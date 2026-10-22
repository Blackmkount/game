class_name RoomView
extends Node3D
## Escena 3D del espacio actual, armada a partir del estado de la partida:
## muebles en sus lugares, impresoras (en muebles o en el suelo), marcas de
## lugares libres, el rincón de despacho junto a la puerta y el personaje.
##
## Lo que cambia con el ciclo de pedidos (la pieza que crece, la pantalla del
## computador, las cajas del rincón) lo muestran las vistas PrinterView,
## DeskView y DispatchView, hijas "View" de cada modelo, con las señales de
## Events.
##
## También sabe qué se puede tocar (interactables), por dónde se puede
## caminar (grid) y dónde está cada cosa en la pantalla. Los gestos del
## jugador los interpreta WorldControls, desde la escena principal.

const BACKDROP_SHADER: Shader = preload("res://game/world/look/backdrop.gdshader")
const BASE_SHADOW_SHADER: Shader = preload("res://game/world/look/base_shadow.gdshader")
const CAMERA_SIZE: float = 6.8
const CAMERA_TARGET: Vector3 = Vector3(-0.15, 1.95, -0.15)
## Proporción de pantalla (alto / ancho) para la que está pensado CAMERA_SIZE.
## En teléfonos más altos se acerca un poco la cámara para llenar el espacio.
const BASE_ASPECT: float = 16.0 / 9.0
const MIN_ZOOM: float = 0.85
## Margen extra alrededor de cada objeto al tocarlo, en metros.
const PICK_MARGIN: float = 0.08
## Las impresoras y los muebles ocupan un poco más en el piso que su dibujo.
const OBSTACLE_MARGIN: float = 0.05
## Alto de la zona que se toca en un lugar libre (la marca es casi plana).
const SLOT_TOUCH_HEIGHT: float = 0.2
## Altura del punto del personaje que sigue la cámara.
const CHARACTER_FOCUS_HEIGHT: float = 0.7
## Hora de la luz cuando no hay partida (la mañana del inicio).
const NO_GAME_HOUR: float = 8.0
## Radio de la mancha de sombra suave bajo el personaje (biblia de arte §3.5).
const CHARACTER_SHADOW_RADIUS: float = 0.36
## Las marcas de lugares libres (biblia §8.7) laten suave entre estos dos
## alfas, en este periodo (segundos), y se encienden (LIT) cuando el
## personaje está a MARKER_NEAR metros o menos, o con la tienda abierta.
const MARKER_ALPHA: float = 0.35
const MARKER_ALPHA_LOW: float = 0.22
const MARKER_LIT_ALPHA: float = 0.85
const MARKER_LIT_ALPHA_LOW: float = 0.55
const MARKER_PULSE_PERIOD: float = 2.4
const MARKER_NEAR: float = 1.2
## Marca de destino: un aro que crece y se desvanece. Alfa al aparecer, lo
## que tarda en irse (segundos) y sus radios (m).
const DESTINATION_ALPHA: float = 0.6
const DESTINATION_FADE_TIME: float = 0.45
const DESTINATION_RADIUS: float = 0.18
const DESTINATION_LINE: float = 0.035
const DESTINATION_HEIGHT: float = 0.01
## Sombra del sol (biblia §2.6).
const SUN_SHADOW_BIAS: float = 0.04
const SUN_SHADOW_NORMAL_BIAS: float = 1.2
const SUN_SHADOW_OPACITY: float = 0.9
## Sombra suave bajo la base del diorama: tamaño respecto del cuarto y cuánto
## más abajo que la base.
const BASE_SHADOW_SCALE: float = 1.9
const BASE_SHADOW_GAP: float = 0.06
## Luz LED de la impresora del piso (si su modelo no tiene el marcador
## "BedLight": cuánto más arriba de la cama) y brillo del monitor (cuánto
## delante de la pantalla).
const PRINTER_LED_ABOVE_BED: float = 0.18
const MONITOR_GLOW_AHEAD: float = 0.12

var camera: CameraRig
var character: CharacterController
## La luz según la hora (sol, ambiente, ventana, luces del sombreador, fondo).
var day_cycle: DayCycle
## Tiempo de animación del mundo (pantallas, latidos): avanza con step() y
## llega a los sombreadores como cc_anim_time.
var anim_time: float = 0.0
var grid: WalkGrid
var interactables: Array[WorldInteractable] = []
## El rincón de despacho (para abrir su panel desde cualquier parte).
var dispatch_item: WorldInteractable
## Mapa de oclusión del piso que leen los sombreadores (FloorAO): manchas
## bajo los obstáculos de `grid`.
var floor_ao: ImageTexture
## Con la tienda abierta todas las marcas de lugares libres se encienden (lo
## avisa WorldControls).
var markers_emphasis: bool = false
## La caja que tapa el parche de sol de la ventana (cc_occ_a): el tablero del
## escritorio, que está bajo la ventana. Vacía si no hay mueble.
var window_occluder: AABB = AABB()
## Lo que adorna el cuarto y no se toca (biblia §5.4): por ahora, la
## baldosa y el cable de la impresora del piso.
var decor: Node3D

var _character_item: WorldInteractable
var _highlight: HighlightFrame
var _destination: MeshInstance3D
var _destination_material: ShaderMaterial
var _destination_tween: Tween
## Las marcas de lugares libres, el rectángulo del piso de cada una y sus dos
## materiales (late suave, encendida).
var _markers: Array[MeshInstance3D] = []
var _marker_areas: Array[Rect2] = []
var _marker_material: ShaderMaterial
var _marker_lit_material: ShaderMaterial


func _ready() -> void:
	ColorProbe.run(self, WorldViewport.MSAA_HIGH)
	_build_environment()
	_build_camera()
	RoomShell.build(self)
	_build_base_shadow()
	grid = WalkGrid.new(Rect2(-RoomShell.SIZE / 2.0, -RoomShell.SIZE / 2.0, RoomShell.SIZE, RoomShell.SIZE))
	decor = PropBuilder.group(self, "Decor")
	_highlight = HighlightFrame.build(self, "Highlight")
	_build_destination()
	_publish_window_occluders(null)
	if Game.state != null:
		_build_contents()
		# La cámara empieza ya encuadrando al personaje.
		camera.follow_point = character_focus_point()
	# Manchas de oclusión bajo los muebles, las impresoras y el rincón (sin
	# partida, un piso limpio).
	floor_ao = FloorAO.publish(grid.bounds, grid.obstacles())
	day_cycle.apply_hour(Game.state.game_minutes / 60.0 if Game.state != null else NO_GAME_HOUR)
	camera.snap_to_goal()
	_publish_character()
	_update_markers()


## Avanza un cuadro: mueve al personaje y después la cámara, y avisa a los
## sombreadores dónde está el personaje y el tiempo de animación. Lo llama
## WorldControls, que decide el orden de todo lo que pasa en cada cuadro.
func step(delta: float) -> void:
	if character != null:
		character.step(delta)
		camera.follow_velocity = character.velocity
	camera.step(delta)
	anim_time += delta
	RenderingServer.global_shader_parameter_set(&"cc_anim_time", anim_time)
	_publish_character()
	_update_markers()


## Objeto del mundo de ese tipo con ese `ref` (uid de la impresora o del
## mueble, índice del lugar libre), o null si no está.
func item_for(kind: WorldInteractable.Kind, ref: int) -> WorldInteractable:
	for item: WorldInteractable in interactables:
		if item.kind == kind and item.ref == ref:
			return item
	return null


## Objeto que está bajo un punto de la pantalla (píxeles del dibujo), o null.
## Primero busca lo que el rayo toca más cerca. Si no toca nada, acepta
## objetos que se ven pequeños si el dedo cae cerca: se los agranda hasta
## `min_hit_px` de lado.
func pick(view_position: Vector2, min_hit_px: float) -> WorldInteractable:
	if _character_item != null:
		# El personaje se mueve: su caja se calcula de nuevo en cada toque.
		_character_item.place(PropBounds.local_aabb(character.model), character.model.global_transform)
	var origin: Vector3 = camera.project_ray_origin(view_position)
	var direction: Vector3 = camera.project_ray_normal(view_position)
	# Primero lo que está justo bajo el dedo. Solo si no hay nada se acepta un
	# toque un poco al lado de un objeto: así el margen de uno no le gana a lo
	# que se ve detrás.
	var best: WorldInteractable = _ray_pick(origin, direction, 0.0)
	if best == null:
		best = _ray_pick(origin, direction, PICK_MARGIN)
	if best != null:
		return best
	var best_center: float = INF
	for item: WorldInteractable in interactables:
		# Las marcas del piso son planas y grandes: su rectángulo en la pantalla
		# cubre mucho piso vacío. Solo se tocan con el rayo.
		if item.kind == WorldInteractable.Kind.SLOT:
			continue
		var rect: Rect2 = screen_rect(item)
		if rect.size.x >= min_hit_px and rect.size.y >= min_hit_px:
			continue
		var grow: Vector2 = (Vector2(min_hit_px, min_hit_px) - rect.size).max(Vector2.ZERO) / 2.0
		rect = rect.grow_individual(grow.x, grow.y, grow.x, grow.y)
		if not rect.has_point(view_position):
			continue
		var center_distance: float = rect.get_center().distance_to(view_position)
		if best == null or item.priority() > best.priority() \
				or (item.priority() == best.priority() and center_distance < best_center):
			best = item
			best_center = center_distance
	return best


## Punto del piso bajo un punto de la pantalla, o null si cae fuera del piso.
func floor_point(view_position: Vector2) -> Variant:
	var origin: Vector3 = camera.project_ray_origin(view_position)
	var direction: Vector3 = camera.project_ray_normal(view_position)
	if absf(direction.y) < 0.0001:
		return null
	var point: Vector3 = origin + direction * (-origin.y / direction.y)
	var on_floor: Vector2 = Vector2(point.x, point.z)
	return on_floor if grid.bounds.has_point(on_floor) else null


## Rectángulo que ocupa un objeto en la pantalla (píxeles del dibujo).
func screen_rect(item: WorldInteractable) -> Rect2:
	var rect: Rect2 = Rect2(camera.unproject_position(item.bounds.get_endpoint(0)), Vector2.ZERO)
	for i: int in range(1, 8):
		rect = rect.expand(camera.unproject_position(item.bounds.get_endpoint(i)))
	return rect


## Resalta un objeto con un marco cian en el piso (null para quitarlo).
func set_highlight(item: WorldInteractable) -> void:
	if item == null:
		_highlight.hide_frame()
	else:
		_highlight.show_around(item.footprint())


## Marca por un momento el punto del piso adonde va a caminar el personaje.
func show_destination(point: Vector2) -> void:
	_destination.position = Vector3(point.x, DESTINATION_HEIGHT, point.y)
	_destination.visible = true
	_destination.scale = Vector3.ONE * 0.6
	_destination_material.set_shader_parameter("alpha", DESTINATION_ALPHA)
	if _destination_tween != null:
		_destination_tween.kill()
	_destination_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	_destination_tween.tween_property(_destination, "scale", Vector3.ONE, DESTINATION_FADE_TIME)
	_destination_tween.tween_property(_destination_material, "shader_parameter/alpha", 0.0, DESTINATION_FADE_TIME)
	_destination_tween.chain().tween_callback(func() -> void: _destination.visible = false)


func character_focus_point() -> Vector3:
	return character.model.position + Vector3(0.0, CHARACTER_FOCUS_HEIGHT, 0.0)


## Entorno de la biblia de arte §2.5: el ambiente, los reflejos y los
## efectos del motor apagados (los calcula el sombreador del mundo, ver
## game/world/look/) y tonemap lineal, para que la cuenta de color sea una
## suma simple. Un solo sol con sombra; DayCycle lo orienta según la hora.
func _build_environment() -> void:
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(WorldPalette.BACKGROUND)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	world_environment.environment = environment
	add_child(world_environment)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	# Una sola sombra ortogonal para todo el cuarto: con la cámara en movimiento,
	# las divisiones del modo por defecto se recalculan y los bordes tiemblan.
	# Con cámara ortográfica, la sombra cubre de near a far de la cámara.
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.shadow_bias = SUN_SHADOW_BIAS
	sun.shadow_normal_bias = SUN_SHADOW_NORMAL_BIAS
	sun.shadow_opacity = SUN_SHADOW_OPACITY
	add_child(sun)

	day_cycle = DayCycle.new()
	day_cycle.name = "DayCycle"
	day_cycle.sun = sun
	add_child(day_cycle)
	var half: float = RoomShell.SIZE / 2.0
	RenderingServer.global_shader_parameter_set(&"cc_room", Vector4(-half, -half, RoomShell.SIZE, RoomShell.WALL_HEIGHT))
	WindowSpec.publish()


func _build_camera() -> void:
	camera = CameraRig.new()
	camera.name = "Camera"
	add_child(camera)
	var half: float = RoomShell.SIZE / 2.0 + RoomShell.WALL_THICKNESS
	var room_bounds: AABB = AABB(Vector3(-half, 0.0, -half), Vector3(half + RoomShell.SIZE / 2.0, RoomShell.WALL_HEIGHT, half + RoomShell.SIZE / 2.0))
	camera.configure(room_bounds, CAMERA_TARGET, _fitted_camera_size())
	camera.current = true
	_build_backdrop()
	get_viewport().size_changed.connect(func() -> void: camera.set_base_size(_fitted_camera_size()))


## Fondo degradado del diorama (biblia §8.10): un cuadro pegado a la cámara,
## al fondo de lo que ve. Sus colores los pone DayCycle.
func _build_backdrop() -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE * CameraRig.FAR * 4.0
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = BACKDROP_SHADER
	var backdrop: MeshInstance3D = MeshInstance3D.new()
	backdrop.name = "Backdrop"
	backdrop.mesh = quad
	backdrop.material_override = material
	backdrop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	backdrop.position = Vector3(0.0, 0.0, -(CameraRig.FAR - 0.5))
	camera.add_child(backdrop)
	day_cycle.backdrop = material


## Sombra suave bajo la base del diorama: lo apoya en el fondo.
func _build_base_shadow() -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE * RoomShell.SIZE * BASE_SHADOW_SCALE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = BASE_SHADOW_SHADER
	var shadow: MeshInstance3D = MeshInstance3D.new()
	shadow.name = "BaseShadow"
	shadow.mesh = quad
	shadow.material_override = material
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.position = Vector3(0.0, RoomShell.BASE_BOTTOM - BASE_SHADOW_GAP, 0.0)
	shadow.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	add_child(shadow)


func _fitted_camera_size() -> float:
	var size: Vector2 = get_viewport().get_visible_rect().size
	if size.x <= 0.0:
		return CAMERA_SIZE
	var aspect: float = size.y / size.x
	return CAMERA_SIZE * clampf(sqrt(BASE_ASPECT / aspect), MIN_ZOOM, 1.0)


func _build_contents() -> void:
	var state: GameState = Game.state
	var layout: RoomLayout = RoomLayout.for_space(state.space_id)
	var furniture_nodes: Dictionary[int, Node3D] = {}
	var used_slots: Array[int] = []
	for item: OwnedFurniture in state.furniture:
		var node: Node3D = FurnitureModel.build(self, "Furniture%d" % item.uid, item.furniture_id)
		node.transform = layout.slots[item.slot]
		furniture_nodes[item.uid] = node
		used_slots.append(item.slot)
		_register(WorldInteractable.Kind.FURNITURE, item.uid, node, true)
		if item.slot == 0:
			_publish_window_occluders(node, item.furniture_id)
		if item.furniture_id == DeskSheet.FURNITURE_ID:
			_add_view(node, DeskView.new())
			var screen: Node3D = node.get_node("Monitor/Screen")
			day_cycle.place_light("monitor", screen.global_transform * Vector3(0.0, 0.0, MONITOR_GLOW_AHEAD))

	var spool_color: String = _first_spool_color(state)
	var floor_index: int = 0
	var spot_index: Dictionary[int, int] = {}
	for printer: OwnedPrinter in state.printers:
		var node: Node3D = PrinterModel.build(self, "Printer%d" % printer.uid, printer.printer_id, spool_color)
		if printer.is_on_floor():
			node.transform = layout.floor_printer_spots[mini(floor_index, layout.floor_printer_spots.size() - 1)]
			if floor_index == 0:
				PaverModel.build(decor, node.transform)
				_place_printer_led(node)
			floor_index += 1
		else:
			var furniture: Node3D = furniture_nodes[printer.furniture_uid]
			var index: int = spot_index.get(printer.furniture_uid, 0)
			spot_index[printer.furniture_uid] = index + 1
			var spot: Node3D = furniture.get_node("PrinterSpot%d" % index)
			node.transform = furniture.transform * spot.transform
		_register(WorldInteractable.Kind.PRINTER, printer.uid, node, true)
		_add_view(node, PrinterView.new(printer.uid, PrinterModel.frame_scale(printer.printer_id)))

	# Las marcas de lugares libres laten suavemente para invitar a llenarlos.
	_marker_material = WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, MARKER_ALPHA, MARKER_ALPHA_LOW, MARKER_PULSE_PERIOD)
	_marker_lit_material = WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, MARKER_LIT_ALPHA, MARKER_LIT_ALPHA_LOW, MARKER_PULSE_PERIOD)
	for slot: int in layout.slots.size():
		if slot not in used_slots:
			var marker: Node3D = SlotMarker.build(self, "FreeSlot%d" % slot, _marker_material)
			marker.transform = layout.slots[slot]
			# Se toca la marca que se ve, con un poco de alto para el rayo.
			var touch_area: AABB = PropBounds.local_aabb(marker)
			touch_area.size.y = SLOT_TOUCH_HEIGHT
			var item: WorldInteractable = WorldInteractable.new(WorldInteractable.Kind.SLOT, slot, touch_area, marker.global_transform)
			interactables.append(item)
			_markers.append(marker.get_node("Mark"))
			_marker_areas.append(item.footprint())

	var door: Node3D = get_node("RoomShell/Door")
	_register(WorldInteractable.Kind.DOOR, 0, door, false)

	var corner: Node3D = DispatchCornerModel.build(self, "DispatchCorner")
	corner.transform = layout.dispatch_spot
	# La vista arma las cajas y los paquetes (escondidos) antes de registrar el
	# rincón: así la zona que se toca incluye los paquetes apilados.
	_add_view(corner, DispatchView.new())
	dispatch_item = _register(WorldInteractable.Kind.DISPATCH, 0, corner, true)

	grid.build()
	var model: Node3D = CharacterModel.build(self, "Character")
	character = CharacterController.new()
	character.name = "CharacterController"
	add_child(character)
	character.setup(model, grid, layout.character_spot)
	_character_item = WorldInteractable.new(WorldInteractable.Kind.CHARACTER, 0, PropBounds.local_aabb(model), model.global_transform)
	interactables.append(_character_item)


## Agrega un objeto que se puede tocar y, si ocupa lugar, lo marca como
## obstáculo para caminar.
func _register(kind: WorldInteractable.Kind, ref: int, node: Node3D, blocks: bool) -> WorldInteractable:
	var item: WorldInteractable = WorldInteractable.new(kind, ref, PropBounds.local_aabb(node), node.global_transform)
	interactables.append(item)
	if blocks:
		grid.add_obstacle(item.footprint().grow(OBSTACLE_MARGIN))
	return item


## Cuelga la vista de un modelo como su hijo "View".
func _add_view(model: Node3D, view: Node) -> void:
	view.name = "View"
	model.add_child(view)


## El objeto más cercano que toca el rayo. Si dos están casi a la misma
## distancia, gana el de más prioridad.
func _ray_pick(origin: Vector3, direction: Vector3, margin: float) -> WorldInteractable:
	var best: WorldInteractable = null
	var best_distance: float = INF
	for item: WorldInteractable in interactables:
		var distance: float = item.ray_distance(origin, direction, margin)
		if distance == INF:
			continue
		if best == null or distance < best_distance - 0.05 \
				or (distance <= best_distance + 0.05 and item.priority() > best.priority()):
			best = item
			best_distance = minf(distance, best_distance)
	return best


## Aro plano que marca adónde va a caminar el personaje.
func _build_destination() -> void:
	_destination_material = WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, DESTINATION_ALPHA).duplicate() as ShaderMaterial
	var ring: ArrayMesh = KitMesh.cached("destination_ring", func() -> ArrayMesh:
		var kit: KitMesh = KitMesh.new()
		kit.ao_enabled = false
		kit.lathe(PackedVector2Array([Vector2(DESTINATION_RADIUS, 0.0), Vector2(DESTINATION_RADIUS - DESTINATION_LINE, 0.0)]), Vector3.ZERO, Vector3.ZERO, 32)
		return kit.commit())
	_destination = PropBuilder.kit(self, "Destination", ring, _destination_material)
	_destination.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_destination.visible = false


## La luz LED que alumbra la cama de la impresora del piso (cc_pl3): en su
## marcador "BedLight" o, en los modelos que no lo tienen, sobre la cama.
func _place_printer_led(printer: Node3D) -> void:
	var led: Node3D = printer.get_node_or_null("BedLight")
	if led != null:
		day_cycle.place_light("printer_led", led.global_position)
	elif printer.has_node("Bed"):
		var bed: Node3D = printer.get_node("Bed")
		day_cycle.place_light("printer_led", bed.global_position + Vector3.UP * PRINTER_LED_ABOVE_BED)


func _first_spool_color(state: GameState) -> String:
	if state.spools.is_empty():
		return WorldPalette.PLASTIC_BEIGE
	var color: Dictionary = DataLookup.config_entry(Game.catalog, "filament_colors", state.spools[0].color_id)
	return color.get("hex", WorldPalette.PLASTIC_BEIGE)



## Las marcas de lugares libres se encienden con el personaje cerca o con la
## tienda abierta. Solo cambia el material cuando hace falta.
func _update_markers() -> void:
	var feet: Vector2 = character.floor_position if character != null else Vector2.INF
	for i: int in _markers.size():
		var lit: bool = markers_emphasis or WalkGrid.distance_to_rect(feet, _marker_areas[i]) <= MARKER_NEAR
		var material: ShaderMaterial = _marker_lit_material if lit else _marker_material
		if _markers[i].material_override != material:
			_markers[i].material_override = material


## Cajas que tapan el parche de sol de la ventana (biblia §6.3, cc_occ_a y
## cc_occ_b): el mueble del lugar 0, que está bajo la ventana (del escritorio,
## su tablero), y la cama (llega con la decoración; por ahora no hay). Sin
## mueble, ninguna caja.
func _publish_window_occluders(under_window: Node3D, furniture_id: String = "") -> void:
	window_occluder = AABB()
	if under_window != null:
		var local: AABB = ComputerDeskModel.table_box() if furniture_id == DeskSheet.FURNITURE_ID else PropBounds.local_aabb(under_window)
		window_occluder = under_window.transform * local
	var center: Vector3 = window_occluder.get_center()
	var half: Vector3 = window_occluder.size / 2.0
	RenderingServer.global_shader_parameter_set(&"cc_occ_a_c", Vector4(center.x, center.y, center.z, 0.0))
	RenderingServer.global_shader_parameter_set(&"cc_occ_a_h", Vector4(half.x, half.y, half.z, 0.0))
	RenderingServer.global_shader_parameter_set(&"cc_occ_b_c", Vector4.ZERO)
	RenderingServer.global_shader_parameter_set(&"cc_occ_b_h", Vector4.ZERO)


## Dónde está el personaje para los sombreadores: su mancha en el piso y la
## cápsula que tapa el parche de la ventana (cc_char_pos).
func _publish_character() -> void:
	if character == null:
		return
	var feet: Vector3 = character.model.position
	RenderingServer.global_shader_parameter_set(&"cc_char_pos", Vector4(feet.x, feet.y, feet.z, CHARACTER_SHADOW_RADIUS))

class_name RoomView
extends Node3D
## Escena 3D del espacio actual, armada a partir del estado de la partida:
## muebles en sus lugares, impresoras (en muebles o en el suelo), marcas de
## lugares libres y el personaje.
##
## También sabe qué se puede tocar (interactables), por dónde se puede
## caminar (grid) y dónde está cada cosa en la pantalla. Los gestos del
## jugador los interpreta WorldControls, desde la escena principal.

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

var camera: CameraRig
var character: CharacterController
var grid: WalkGrid
var interactables: Array[WorldInteractable] = []

var _character_item: WorldInteractable
var _marker_material: StandardMaterial3D
var _highlight: HighlightFrame
var _destination: MeshInstance3D
var _destination_material: StandardMaterial3D
var _destination_tween: Tween


func _ready() -> void:
	_build_environment()
	_build_camera()
	RoomShell.build(self)
	grid = WalkGrid.new(Rect2(-RoomShell.SIZE / 2.0, -RoomShell.SIZE / 2.0, RoomShell.SIZE, RoomShell.SIZE))
	_highlight = HighlightFrame.build(self, "Highlight")
	_build_destination()
	if Game.state != null:
		_build_contents()
		# La cámara empieza ya encuadrando al personaje.
		camera.follow_point = character_focus_point()
	camera.snap_to_goal()


## Avanza un cuadro: mueve al personaje, mueve la cámara y después ajusta al
## personaje a la cuadrícula de píxeles de la cámara. Lo llama WorldControls, que decide el
## orden de todo lo que pasa en cada cuadro.
func step(delta: float) -> void:
	if character != null:
		character.step(delta)
		camera.follow_velocity = character.velocity
	camera.step(delta)
	# Después de la cámara, que es la que actualiza el zoom de este cuadro.
	if character != null:
		_snap_to_pixels(character.model)


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
	_destination.position = Vector3(point.x, 0.01, point.y)
	_destination.visible = true
	_destination.scale = Vector3.ONE * 0.6
	_destination_material.albedo_color.a = 0.8
	if _destination_tween != null:
		_destination_tween.kill()
	_destination_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	_destination_tween.tween_property(_destination, "scale", Vector3.ONE, 0.45)
	_destination_tween.tween_property(_destination_material, "albedo_color:a", 0.0, 0.45)
	_destination_tween.chain().tween_callback(func() -> void: _destination.visible = false)


func character_focus_point() -> Vector3:
	return character.model.position + Vector3(0.0, CHARACTER_FOCUS_HEIGHT, 0.0)


## Mueve un objeto que está en el piso al píxel más cercano del dibujo, igual
## que la cámara. Así su distancia a la cámara es un número entero de píxeles
## y no "tiembla" contra la habitación. Lo corre a lo largo de la mirada de la
## cámara para que siga apoyado en el piso (en la pantalla no se nota).
func _snap_to_pixels(node: Node3D) -> void:
	var texel: float = camera.size / maxf(get_viewport().get_visible_rect().size.x, 1.0)
	var right: Vector3 = camera.basis.x
	var up: Vector3 = camera.basis.y
	var forward: Vector3 = -camera.basis.z
	var point: Vector3 = node.position
	var snapped: Vector3 = right * (roundf(point.dot(right) / texel) * texel) \
		+ up * (roundf(point.dot(up) / texel) * texel) + forward * point.dot(forward)
	node.position = snapped - forward * (snapped.y / forward.y)


func _build_environment() -> void:
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(WorldPalette.BACKGROUND)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("ffe6c7")
	environment.ambient_light_energy = 0.5
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	world_environment.environment = environment
	add_child(world_environment)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-55.0, -60.0, 0.0)
	sun.light_color = Color("fff1dc")
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	# Una sola sombra ortogonal para todo el cuarto: con la cámara en movimiento,
	# las divisiones del modo por defecto se recalculan y los bordes tiemblan.
	# Con cámara ortográfica, la sombra cubre de near a far de la cámara.
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(sun)


func _build_camera() -> void:
	camera = CameraRig.new()
	camera.name = "Camera"
	add_child(camera)
	var half: float = RoomShell.SIZE / 2.0 + RoomShell.WALL_THICKNESS
	var room_bounds: AABB = AABB(Vector3(-half, 0.0, -half), Vector3(half + RoomShell.SIZE / 2.0, RoomShell.WALL_HEIGHT, half + RoomShell.SIZE / 2.0))
	camera.configure(room_bounds, CAMERA_TARGET, _fitted_camera_size())
	camera.current = true
	get_viewport().size_changed.connect(func() -> void: camera.set_base_size(_fitted_camera_size()))


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

	var spool_color: String = _first_spool_color(state)
	var floor_index: int = 0
	var spot_index: Dictionary[int, int] = {}
	for printer: OwnedPrinter in state.printers:
		var node: Node3D = PrinterModel.build(self, "Printer%d" % printer.uid, printer.printer_id, spool_color)
		if printer.is_on_floor():
			node.transform = layout.floor_printer_spots[mini(floor_index, layout.floor_printer_spots.size() - 1)]
			floor_index += 1
		else:
			var furniture: Node3D = furniture_nodes[printer.furniture_uid]
			var index: int = spot_index.get(printer.furniture_uid, 0)
			spot_index[printer.furniture_uid] = index + 1
			var spot: Node3D = furniture.get_node("PrinterSpot%d" % index)
			node.transform = furniture.transform * spot.transform
		_register(WorldInteractable.Kind.PRINTER, printer.uid, node, true)

	_marker_material = WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, 0.6)
	for slot: int in layout.slots.size():
		if slot not in used_slots:
			var marker: Node3D = SlotMarker.build(self, "FreeSlot%d" % slot, _marker_material)
			marker.transform = layout.slots[slot]
			# Se toca la marca que se ve, con un poco de alto para el rayo.
			var touch_area: AABB = PropBounds.local_aabb(marker)
			touch_area.size.y = SLOT_TOUCH_HEIGHT
			interactables.append(WorldInteractable.new(WorldInteractable.Kind.SLOT, slot, touch_area, marker.global_transform))
	_pulse_markers()

	var door: Node3D = get_node("RoomShell/Door")
	_register(WorldInteractable.Kind.DOOR, 0, door, false)

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
func _register(kind: WorldInteractable.Kind, ref: int, node: Node3D, blocks: bool) -> void:
	var item: WorldInteractable = WorldInteractable.new(kind, ref, PropBounds.local_aabb(node), node.global_transform)
	interactables.append(item)
	if blocks:
		grid.add_obstacle(item.footprint().grow(OBSTACLE_MARGIN))


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


func _build_destination() -> void:
	_destination_material = WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, 0.8).duplicate() as StandardMaterial3D
	_destination = PropBuilder.cylinder(self, "Destination", 0.18, 0.01, Vector3.ZERO, _destination_material)
	_destination.visible = false


func _first_spool_color(state: GameState) -> String:
	if state.spools.is_empty():
		return WorldPalette.PLASTIC_BEIGE
	var color: Dictionary = DataLookup.config_entry(Game.catalog, "filament_colors", state.spools[0].color_id)
	return color.get("hex", WorldPalette.PLASTIC_BEIGE)


## Las marcas de lugares libres laten suavemente para invitar a llenarlos.
func _pulse_markers() -> void:
	var tween: Tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tween.tween_property(_marker_material, "albedo_color:a", 0.2, 1.2)
	tween.tween_property(_marker_material, "albedo_color:a", 0.6, 1.2)

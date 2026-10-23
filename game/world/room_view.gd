class_name RoomView
extends Node3D
## Escena 3D del espacio actual, armada a partir del estado de la partida:
## muebles en sus lugares, impresoras (en muebles o en el suelo), marcas de
## lugares libres, el rincón de despacho junto a la puerta, el personaje y la
## decoración del dormitorio (RoomDecor, que crece con el nivel).
##
## Lo que cambia con el ciclo de pedidos (la pieza que crece, la pantalla del
## computador, las cajas del rincón) lo muestran las vistas PrinterView,
## DeskView y DispatchView, hijas "View" de cada modelo, con las señales de
## Events.
##
## También sabe qué se puede tocar (interactables), por dónde se puede
## caminar (grid) y dónde está cada cosa en la pantalla. Los gestos del
## jugador los interpreta WorldControls, desde la escena principal.
##
## El personaje reacciona a lo que pasa (biblia de arte §7.8): RoomView
## escucha las señales de Events y se lo cuenta a su CharacterAnimator (qué
## impresora falló o terminó, si está cerca, si se modela, la hora).
##
## Lo que hay en el cuarto sigue al estado (sync_models, biblia §12.2): al
## cargar otra partida (Events.game_loaded) se arma lo que falta y se quita
## lo que sobra; lo que se compre (Fase 1, tarea 5) aparecerá imprimiéndose
## en su lugar (PrintIn).
##
## Rendimiento (biblia §2.2 y §13): aplica el nivel de calidad gráfica
## (GraphicsQuality: la sombra del sol, el polvo, la fuerza de la oclusión
## del piso y ColorProbe) y, con el zoom lejos, pone las impresoras en su
## versión lejana (PrinterView.set_far: menos detalle y sin lo que se mueve;
## sus pantallitas, todas en un MultiMesh: DisplayField).

## Cambió lo que hay en el cuarto (sync_models): muebles, impresoras o
## lugares libres. Lo escuchan WorldControls y las burbujas de estado, que
## guardan objetos que se tocan.
signal models_changed

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
## Lo que no deja pasar al personaje (y oscurece el piso, FloorAO).
const BLOCKING: Array[WorldInteractable.Kind] = [WorldInteractable.Kind.FURNITURE, WorldInteractable.Kind.PRINTER, WorldInteractable.Kind.DISPATCH]
## El lugar de muebles que queda bajo la ventana (su mueble tapa el parche de
## sol).
const WINDOW_SLOT: int = 0
## Altura del punto del personaje que sigue la cámara.
const CHARACTER_FOCUS_HEIGHT: float = 0.7
## Hora de la luz cuando no hay partida (la mañana del inicio).
const NO_GAME_HOUR: float = 8.0
## Con el zoom por debajo de FAR_ZOOM_ENTER las impresoras pasan a su
## versión lejana, y vuelven por encima de FAR_ZOOM_LEAVE (el escalón lejos
## es 0,68 y el normal 1: entre los dos, sin ir y venir con el pellizco). Al
## alejar, el cambio llega cuando la cámara casi terminó de moverse.
const FAR_ZOOM_ENTER: float = 0.7
const FAR_ZOOM_LEAVE: float = 0.86
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
## Las cajas que tapan el parche de sol de la ventana: el tablero del
## escritorio, que está bajo la ventana (cc_occ_a; vacía si no hay mueble), y
## la cama (cc_occ_b).
var window_occluder: AABB = AABB()
var bed_occluder: AABB = AABB()
## Lo que adorna el cuarto y no se toca (biblia §5.4 y §8.8): la decoración
## del dormitorio, que crece con el nivel, y la baldosa y el cable de la
## impresora del piso.
var decor: RoomDecor
## Los halos de noche de las impresoras, del color de su estado (biblia
## §9.2): un MultiMesh para todos, que DayCycle muestra solo de noche.
var halos: HaloField
## Si las impresoras están en su versión lejana (zoom lejos).
var far_printers: bool = false
## Las pantallitas de las impresoras en su versión lejana: un MultiMesh para
## todas, que se ve solo con el zoom lejos.
var far_displays: DisplayField
## Cuánto tardó el último armado de este cuarto (ms: al crearlo o al
## volver a armar lo que cambió, sync_models) y el primero desde que se abrió
## el juego, con las cachés de mallas y materiales vacías (panel de
## depuración: si en el teléfono pasa de 1 s, decisión D4 de la biblia).
var build_msec: float = 0.0
static var first_build_msec: float = -1.0

var _character_item: WorldInteractable
var _door_item: WorldInteractable
## El nivel de calidad gráfica que se aplica (GraphicsQuality.current) y
## con qué fuerza se pintó el mapa de oclusión del piso.
var _quality: GraphicsQuality
var _floor_ao_strength: float = -1.0
## Los muebles y las impresoras del cuarto (por uid) y las marcas de los
## lugares libres (por lugar), con lo que se toca de cada uno.
var _furniture: Dictionary[int, Placed] = {}
var _printers: Dictionary[int, Placed] = {}
var _slots: Dictionary[int, Placed] = {}
## La impresora del piso (la primera, sobre su baldosa) y la baldosa.
var _floor_printer: Node3D
var _paver: MeshInstance3D
## La mesa del computador (sus luces y sus halos de noche), si hay.
var _desk: Node3D
## Lo que no se mueve nunca del piso (la decoración): la grilla de caminar
## empieza con esto cada vez que se vuelve a armar.
var _fixed_obstacles: Array[Rect2] = []
## Lo que se está imprimiendo en el cuarto (las compras que llegan).
var _print_ins: Array[PrintIn] = []
## Lo que el animador del personaje necesita del cuarto: el escritorio (para
## la cara concentrada), los cabezales de las impresoras (para mirarlos; ver
## _watched_part) y qué impresoras tenían una pieza lista (para el pulgar
## arriba al terminar).
var _desk_area: Rect2 = Rect2()
var _print_heads: Array[Node3D] = []
var _printers_done: Dictionary[int, bool] = {}
## El esqueleto del personaje (copia la pose de sus pivotes) y el punto
## sobre su cabeza donde va el globo de diálogo.
var _rig: CharacterRig
var _speech_anchor: Node3D
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


## Un mueble, una impresora o una marca de lugar libre del cuarto: su nodo,
## con qué se armó (si eso cambia en el estado, se arma de nuevo) y lo que se
## toca de él.
class Placed:
	var node: Node3D
	var key: String
	var item: WorldInteractable

	func _init(p_node: Node3D, p_key: String, p_item: WorldInteractable) -> void:
		node = p_node
		key = p_key
		item = p_item


func _ready() -> void:
	var started: int = Time.get_ticks_usec()
	_quality = GraphicsQuality.current
	_build_environment()
	_build_camera()
	RoomShell.build(self)
	_build_base_shadow()
	grid = WalkGrid.new(Rect2(-RoomShell.SIZE / 2.0, -RoomShell.SIZE / 2.0, RoomShell.SIZE, RoomShell.SIZE))
	halos = HaloField.new()
	add_child(halos)
	day_cycle.halos = halos
	far_displays = DisplayField.new()
	add_child(far_displays)
	# La decoración registra sus obstáculos antes de que se arme la grilla.
	decor = RoomDecor.build(self, grid, _level())
	_fixed_obstacles = grid.obstacles()
	day_cycle.dust = decor.dust
	day_cycle.led_strip_on = decor.has_led_strip()
	day_cycle.place_light("bed_lamp", DecorItems.BED_LAMP_BULB)
	_highlight = HighlightFrame.build(self, "Highlight")
	_build_destination()
	_publish_window_occluders(null)
	if Game.state != null:
		_build_contents()
		# La cámara empieza ya encuadrando al personaje.
		camera.follow_point = character_focus_point()
	else:
		# Sin partida: los halos de la decoración y un piso limpio.
		decor.add_night_lights(halos)
		_paint_floor_ao()
	day_cycle.set_hour(Game.state.game_minutes / GameClock.MINUTES_PER_HOUR if Game.state != null else NO_GAME_HOUR)
	_quality.changed.connect(_apply_quality)
	_apply_quality()
	camera.snap_to_goal()
	_publish_character()
	_update_markers()
	build_msec = (Time.get_ticks_usec() - started) / 1000.0
	if first_build_msec < 0.0:
		first_build_msec = build_msec


## Avanza un cuadro: mueve al personaje y después la cámara, lleva la luz
## hacia la hora del reloj y avisa a los sombreadores dónde está el
## personaje y el tiempo de animación. Lo llama WorldControls, que decide el
## orden de todo lo que pasa en cada cuadro.
func step(delta: float) -> void:
	if character != null:
		character.step(delta)
		_rig.follow()
		camera.follow_velocity = character.velocity
	camera.step(delta)
	_update_far()
	day_cycle.step(delta)
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


## Donde se ancla el globo de diálogo: sobre la cabeza del personaje (sigue
## sus saltos y gestos).
func speech_point() -> Vector3:
	return _speech_anchor.global_position


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
	material.set_shader_parameter("color", Color(LookPalette.BASE_SHADOW, LookPalette.BASE_SHADOW_ALPHA))
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


## Arma lo que sale del estado (muebles, impresoras, lugares libres), lo
## que está siempre (la puerta y el rincón de despacho) y al personaje, en el
## orden en que van los nodos, lo que se toca y los obstáculos.
func _build_contents() -> void:
	var state: GameState = Game.state
	var layout: RoomLayout = RoomLayout.for_space(state.space_id)
	# Las marcas de lugares libres laten suavemente para invitar a llenarlos.
	_marker_material = WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, MARKER_ALPHA, MARKER_ALPHA_LOW, MARKER_PULSE_PERIOD)
	_marker_lit_material = WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, MARKER_LIT_ALPHA, MARKER_LIT_ALPHA_LOW, MARKER_PULSE_PERIOD)
	var new_furniture: Dictionary[int, Node3D] = {}
	var new_printers: Dictionary[Node3D, float] = {}
	_sync_furniture(state, layout, new_furniture)
	_sync_printers(state, layout, new_furniture, new_printers)
	_sync_slots(state, layout)

	var door: Node3D = get_node("RoomShell/Door")
	_door_item = _make_item(WorldInteractable.Kind.DOOR, 0, door)
	var corner: Node3D = DispatchCornerModel.build(self, "DispatchCorner")
	corner.transform = layout.dispatch_spot
	# La vista arma las cajas y los paquetes (escondidos) antes de registrar el
	# rincón: así la zona que se toca incluye los paquetes apilados.
	_add_view(corner, DispatchView.new())
	dispatch_item = _make_item(WorldInteractable.Kind.DISPATCH, 0, corner)
	_rebuild_room(state)

	var model: Node3D = CharacterModel.build(self, "Character")
	character = CharacterController.new()
	character.name = "CharacterController"
	add_child(character)
	character.setup(model, grid, layout.character_spot)
	character.camera_yaw = deg_to_rad(CameraRig.YAW)
	_setup_animator()
	_rig = model.get_node("Rig")
	_rig.follow()
	_speech_anchor = model.get_node("Body/Head/SpeechAnchor")
	_character_item = WorldInteractable.new(WorldInteractable.Kind.CHARACTER, 0, PropBounds.local_aabb(model), model.global_transform)
	interactables.append(_character_item)


## Deja el cuarto igual al estado de la partida (biblia de arte §12.2): arma
## los muebles y las impresoras que faltan, quita los que ya no están y vuelve
## a armar los que cambiaron (de tipo, de lugar o de carrete), con las marcas
## de los lugares que quedan libres. Después rehace lo que depende de dónde
## está cada cosa: lo que se toca, la grilla de caminar, el mapa de oclusión
## del piso, los halos de noche y las luces del escritorio y de la impresora
## del piso. Si nada cambió, no hace nada.
##
## Con `animate`, lo nuevo aparece imprimiéndose en su lugar (PrintIn; las
## impresoras de un mueble nuevo, cuando el mueble ya terminó): así lo
## mostrará el comando de compra (Fase 1, tarea 5). Al cargar una partida
## (Events.game_loaded) el cuarto queda igual al estado de una vez.
func sync_models(animate: bool = true) -> void:
	var state: GameState = Game.state
	if state == null:
		return
	var started: int = Time.get_ticks_usec()
	var layout: RoomLayout = RoomLayout.for_space(state.space_id)
	var new_furniture: Dictionary[int, Node3D] = {}
	var new_printers: Dictionary[Node3D, float] = {}
	var changed: bool = _sync_furniture(state, layout, new_furniture)
	changed = _sync_printers(state, layout, new_furniture, new_printers) or changed
	changed = _sync_slots(state, layout) or changed
	if not changed:
		return
	_rebuild_room(state)
	day_cycle.refresh()
	if character != null:
		# Lo nuevo puede quedar donde estaba el personaje o en su camino.
		character.stop_path()
		character.floor_position = grid.resolve(character.floor_position)
		character.animator.desk_area = _desk_area
		character.animator.watch_points = _print_heads
	if animate:
		_print_in(new_furniture, new_printers)
	build_msec = (Time.get_ticks_usec() - started) / 1000.0
	models_changed.emit()


## Termina ya lo que se está imprimiendo en el cuarto (un toque en el mundo:
## WorldControls).
func finish_print_ins() -> void:
	if _print_ins.is_empty():
		return
	for effect: PrintIn in _print_ins:
		effect.finish()
	_print_ins.clear()


## Lo que muestra cómo se imprime `node` ahora, o null si no se está
## imprimiendo (pruebas y capturas).
func print_in_of(node: Node3D) -> PrintIn:
	for effect: PrintIn in _print_ins:
		if effect.is_running() and effect.node == node:
			return effect
	return null


## Los muebles del estado: arma los que faltan y los que cambiaron de tipo o
## de lugar (en `appeared`, por uid) y quita los que ya no están. Devuelve si
## cambió algo.
func _sync_furniture(state: GameState, layout: RoomLayout, appeared: Dictionary[int, Node3D]) -> bool:
	var keys: Dictionary[int, String] = {}
	for item: OwnedFurniture in state.furniture:
		keys[item.uid] = "%s@%d" % [item.furniture_id, item.slot]
	var changed: bool = false
	for uid: int in _furniture.keys():
		if keys.get(uid, "") != _furniture[uid].key:
			_drop(_furniture[uid].node)
			_furniture.erase(uid)
			changed = true
	for item: OwnedFurniture in state.furniture:
		if _furniture.has(item.uid):
			continue
		var node: Node3D = FurnitureModel.build(self, "Furniture%d" % item.uid, item.furniture_id, layout.wall_gaps[item.slot])
		node.transform = layout.slots[item.slot]
		if item.furniture_id == DeskSheet.FURNITURE_ID:
			_add_view(node, DeskView.new())
		var touched: WorldInteractable = _make_item(WorldInteractable.Kind.FURNITURE, item.uid, node)
		touched.touch_parts = FurnitureModel.touch_parts(node, item.furniture_id)
		_furniture[item.uid] = Placed.new(node, keys[item.uid], touched)
		appeared[item.uid] = node
		changed = true
	return changed


## Las impresoras del estado, cada una en su lugar: en el piso (la primera,
## sobre su baldosa) o en el lugar que le toca de su mueble. Arma las que
## faltan y las que cambiaron de modelo, de lugar o de carrete (en
## `appeared`, con lo que esperan para imprimirse: las de un mueble nuevo,
## lo que tarda el mueble) y quita las que ya no están. Devuelve si cambió
## algo.
func _sync_printers(state: GameState, layout: RoomLayout, new_furniture: Dictionary[int, Node3D], appeared: Dictionary[Node3D, float]) -> bool:
	var spool_color: String = _first_spool_color(state)
	var keys: Dictionary[int, String] = {}
	var places: Dictionary[int, Transform3D] = {}
	var floor_index: int = 0
	var spot_index: Dictionary[int, int] = {}
	for printer: OwnedPrinter in state.printers:
		var place: String = "floor%d" % floor_index
		var at: Transform3D
		if printer.is_on_floor():
			at = layout.floor_printer_spots[mini(floor_index, layout.floor_printer_spots.size() - 1)]
			floor_index += 1
		else:
			var index: int = spot_index.get(printer.furniture_uid, 0)
			spot_index[printer.furniture_uid] = index + 1
			var furniture: Placed = _furniture.get(printer.furniture_uid)
			var spot: Node3D = furniture.node.get_node_or_null("PrinterSpot%d" % index) if furniture != null else null
			if spot == null:
				# Su mueble no está o no tiene ese lugar: no se ve.
				continue
			at = furniture.node.transform * spot.transform
			place = "%d:%s/%d" % [printer.furniture_uid, furniture.key, index]
		keys[printer.uid] = "%s|%s|%s" % [printer.printer_id, place, spool_color]
		places[printer.uid] = at
	var changed: bool = false
	for uid: int in _printers.keys():
		if keys.get(uid, "") != _printers[uid].key:
			_drop(_printers[uid].node)
			_printers.erase(uid)
			changed = true
	_floor_printer = null
	for printer: OwnedPrinter in state.printers:
		if not keys.has(printer.uid):
			continue
		if not _printers.has(printer.uid):
			# La del piso, con todo su detalle; las de los muebles, con menos (y
			# solo su cuerpo da sombra).
			var detail: float = PrinterParts.FLOOR_DETAIL if printer.is_on_floor() else PrinterParts.FURNITURE_DETAIL
			var node: Node3D = PrinterModel.build(self, "Printer%d" % printer.uid, printer.printer_id, spool_color, detail)
			node.transform = places[printer.uid]
			var view: PrinterView = PrinterView.new(printer.uid, printer.printer_id, spool_color, detail)
			_add_view(node, view)
			_printers[printer.uid] = Placed.new(node, keys[printer.uid], _make_item(WorldInteractable.Kind.PRINTER, printer.uid, node))
			# Después de medir lo que se toca: la zona es la de la versión de
			# siempre, con cualquier zoom.
			view.set_far(far_printers)
			appeared[node] = PrintIn.FURNITURE_SECONDS if new_furniture.has(printer.furniture_uid) else 0.0
			changed = true
		if _floor_printer == null and printer.is_on_floor():
			_floor_printer = _printers[printer.uid].node
	# La baldosa (con su cable) va con la impresora del piso.
	if _floor_printer == null and _paver != null:
		_drop(_paver)
		_paver = null
	elif _floor_printer != null and _paver == null:
		_paver = PaverModel.build(decor, _floor_printer.transform)
	return changed


## Una marca en cada lugar sin mueble (FreeSlot<lugar>). Devuelve si cambió
## algo.
func _sync_slots(state: GameState, layout: RoomLayout) -> bool:
	var used: Array[int] = []
	for item: OwnedFurniture in state.furniture:
		used.append(item.slot)
	var changed: bool = false
	for slot: int in layout.slots.size():
		var free: bool = slot not in used
		if free == _slots.has(slot):
			continue
		changed = true
		if not free:
			_drop(_slots[slot].node)
			_slots.erase(slot)
			continue
		var marker: Node3D = SlotMarker.build(self, "FreeSlot%d" % slot, _marker_material)
		marker.transform = layout.slots[slot]
		# Se toca la marca que se ve, con un poco de alto para el rayo.
		var touch_area: AABB = PropBounds.local_aabb(marker)
		touch_area.size.y = SLOT_TOUCH_HEIGHT
		_slots[slot] = Placed.new(marker, "", WorldInteractable.new(WorldInteractable.Kind.SLOT, slot, touch_area, marker.global_transform))
	return changed


## Lo que depende de dónde está cada cosa, después de armar o quitar
## muebles, impresoras o marcas.
func _rebuild_room(state: GameState) -> void:
	_collect_interactables(state)
	grid.clear_obstacles()
	for rect: Rect2 in _fixed_obstacles:
		grid.add_obstacle(rect)
	for item: WorldInteractable in interactables:
		if item.kind in BLOCKING:
			grid.add_obstacle(item.footprint().grow(OBSTACLE_MARGIN))
	grid.build()
	_paint_floor_ao()
	_place_lights(state)
	# Los halos de noche en orden: impresoras, escritorio y decoración. Y las
	# pantallitas de la versión lejana.
	halos.clear()
	far_displays.clear()
	for printer: OwnedPrinter in state.printers:
		if _printers.has(printer.uid):
			var view: PrinterView = _printers[printer.uid].node.get_node("View")
			view.attach_halo(halos)
			view.attach_display(far_displays)
	if _desk != null:
		_add_desk_halos(_desk)
	decor.add_night_lights(halos)


## Lo que se toca, en orden: los muebles, las impresoras, los lugares libres,
## la puerta, el rincón de despacho y el personaje. Los objetos que ya
## estaban son los mismos (WorldControls y las burbujas los guardan).
func _collect_interactables(state: GameState) -> void:
	interactables.clear()
	for item: OwnedFurniture in state.furniture:
		if _furniture.has(item.uid):
			interactables.append(_furniture[item.uid].item)
	for printer: OwnedPrinter in state.printers:
		if _printers.has(printer.uid):
			interactables.append(_printers[printer.uid].item)
	_markers.clear()
	_marker_areas.clear()
	var slots: Array[int] = _slots.keys()
	slots.sort()
	for slot: int in slots:
		var placed: Placed = _slots[slot]
		interactables.append(placed.item)
		_markers.append(placed.node.get_node("Mark"))
		_marker_areas.append(placed.item.footprint())
	for item: WorldInteractable in [_door_item, dispatch_item, _character_item]:
		if item != null:
			interactables.append(item)


## Las luces que salen de los muebles y de la impresora del piso, y lo que
## sabe de ellos el personaje: el escritorio (su lámpara, su monitor, su
## lugar), el mueble bajo la ventana (tapa el parche de sol), la luz de la
## cama de la impresora del piso y los cabezales que se miran.
func _place_lights(state: GameState) -> void:
	_desk = null
	_desk_area = Rect2()
	var under_window: Node3D = null
	var under_window_id: String = ""
	for item: OwnedFurniture in state.furniture:
		if not _furniture.has(item.uid):
			continue
		var placed: Placed = _furniture[item.uid]
		if item.slot == WINDOW_SLOT:
			under_window = placed.node
			under_window_id = item.furniture_id
		if item.furniture_id == DeskSheet.FURNITURE_ID and _desk == null:
			_desk = placed.node
			_desk_area = placed.item.footprint()
	_publish_window_occluders(under_window, under_window_id)
	if _desk != null:
		_place_desk_lights(_desk)
	else:
		day_cycle.clear_light("desk_lamp")
		day_cycle.clear_light("monitor")
	if _floor_printer != null:
		_place_printer_led(_floor_printer)
	else:
		day_cycle.clear_light("printer_led")
	_print_heads.clear()
	for printer: OwnedPrinter in state.printers:
		if _printers.has(printer.uid):
			_print_heads.append(_watched_part(_printers[printer.uid].node))


## Pone a imprimirse lo que acaba de aparecer: los muebles y después las
## impresoras (las de un mueble nuevo esperan a que termine).
func _print_in(new_furniture: Dictionary[int, Node3D], new_printers: Dictionary[Node3D, float]) -> void:
	var running: Array[PrintIn] = []
	for effect: PrintIn in _print_ins:
		if effect.is_running():
			running.append(effect)
	_print_ins = running
	for node: Node3D in new_furniture.values():
		_print_ins.append(PrintIn.play(node, PrintIn.FURNITURE_SECONDS))
	for node: Node3D in new_printers:
		_print_ins.append(PrintIn.play(node, PrintIn.PRINTER_SECONDS, new_printers[node]))


## Quita del cuarto un modelo que ya no está, de una vez (su nombre queda
## libre para el que lo reemplaza). Si se estaba imprimiendo, termina.
func _drop(node: Node3D) -> void:
	for effect: PrintIn in _print_ins:
		if effect.is_running() and effect.node == node:
			effect.finish()
	node.free()


## El nivel de calidad gráfica (biblia §2.2): la sombra del sol y el modelo
## de color que va con ella (cc_sun_shadowed), las motas de polvo y la
## fuerza del mapa de oclusión del piso. ColorProbe vuelve a medir si el
## nivel cambió el suavizado o la sombra.
func _apply_quality() -> void:
	var shadow: bool = _quality.sun_shadow()
	day_cycle.sun.shadow_enabled = shadow
	RenderingServer.global_shader_parameter_set(&"cc_sun_shadowed", 1.0 if shadow else 0.0)
	decor.dust.enabled = _quality.dust()
	day_cycle.refresh()
	# Al armar el cuarto ya se pintó con la fuerza de ahora.
	if _quality.floor_ao() != _floor_ao_strength:
		_paint_floor_ao()
	ColorProbe.run(self, _quality.msaa(), shadow)


## Manchas de oclusión bajo los muebles, las impresoras, el rincón y la
## decoración (los obstáculos de la grilla), con la fuerza del nivel de
## calidad.
func _paint_floor_ao() -> void:
	_floor_ao_strength = _quality.floor_ao()
	floor_ao = FloorAO.publish(grid.bounds, grid.obstacles(), _floor_ao_strength)


## Con el zoom lejos, las impresoras en su versión lejana (y de vuelta), con
## sus pantallitas en DisplayField. Solo hace algo al cruzar el umbral. Si
## algo se está imprimiendo (una compra, biblia §12.2), espera a que termine:
## las partes que cambian no deben hacerlo a mitad del efecto, ni cortarlo.
func _update_far() -> void:
	var far: bool = camera.zoom < (FAR_ZOOM_LEAVE if far_printers else FAR_ZOOM_ENTER)
	if far == far_printers or _printing_in():
		return
	far_printers = far
	for uid: int in _printers:
		(_printers[uid].node.get_node(^"View") as PrinterView).set_far(far)
	far_displays.set_shown(far)


## Si algo del cuarto se está imprimiendo ahora (PrintIn).
func _printing_in() -> bool:
	for effect: PrintIn in _print_ins:
		if effect.is_running():
			return true
	return false


## Si el personaje está a CharacterAnimator.NEAR metros o menos de ese
## objeto (para las reacciones de cerca).
func character_near(item: WorldInteractable) -> bool:
	return character != null and item != null \
		and WalkGrid.distance_to_rect(character.floor_position, item.footprint()) <= CharacterAnimator.NEAR


## Le cuenta al animador del personaje lo que tiene alrededor y lo conecta a
## lo que pasa en la partida. Su azar cambia en cada partida (las capturas
## le ponen una semilla fija).
func _setup_animator() -> void:
	var animator: CharacterAnimator = character.animator
	animator.reseed(randi())
	animator.desk_area = _desk_area
	animator.watch_points = _print_heads
	Events.order_delivered.connect(_on_order_delivered)
	Events.print_failed.connect(_on_print_failed)
	Events.level_up.connect(_on_level_up)
	Events.offer_arrived.connect(_on_offer_arrived.unbind(1))
	Events.printer_changed.connect(_on_printer_changed)
	Events.computer_changed.connect(_on_computer_changed)
	Events.time_changed.connect(_on_time_changed)
	Events.game_loaded.connect(_on_game_loaded)
	_on_game_loaded()


func _on_order_delivered(_order_uid: int, _order_id: String, _cents: int, _xp: int, late: bool) -> void:
	character.animator.react(CharacterAnimator.Reaction.DELIVERED_LATE if late else CharacterAnimator.Reaction.DELIVERED)


## Se agarra la cabeza de cara al jugador (se gira hacia la cámara, como al
## saludar: si estaba mirando la impresora, la cara preocupada quedaba de
## espaldas) y mira de reojo la impresora que falló. Con un panel abierto
## sigue de frente al objeto del panel.
func _on_print_failed(printer_uid: int, _failure_type: String) -> void:
	character.animator.react(CharacterAnimator.Reaction.PRINT_FAILED, _print_head_of(printer_uid))
	if character.animator.current_gesture() == CharacterGestures.Gesture.HANDS_ON_HEAD and not character.animator.panel_open:
		character.face_camera()


## Sube de nivel: el personaje salta y la decoración crece (la grilla de
## caminar no cambia).
func _on_level_up(level: int) -> void:
	character.animator.react(CharacterAnimator.Reaction.LEVEL_UP)
	_show_decor_level(level)


## La decoración del nivel `level`. La tira LED del taller enciende o apaga
## su luz del sombreador.
func _show_decor_level(level: int) -> void:
	decor.set_level(level)
	if day_cycle.led_strip_on != decor.has_led_strip():
		day_cycle.led_strip_on = decor.has_led_strip()
		day_cycle.refresh()


## Nivel del juego (sin partida, el primero).
func _level() -> int:
	return OrderQueries.level(Game.state, Game.rules) if Game.state != null else RoomDecor.TIER_LEVELS[0]


func _on_offer_arrived() -> void:
	character.animator.react(CharacterAnimator.Reaction.OFFER)


## Una impresora que termina su pieza con el personaje cerca: pulgar arriba
## para el jugador (se gira hacia la cámara, como al saludar, y la mira de
## reojo). Con un panel abierto sigue de frente al objeto del panel.
func _on_printer_changed(printer_uid: int) -> void:
	var printer: OwnedPrinter = Game.state.find_printer(printer_uid)
	if printer == null:
		return
	var done: bool = OrderQueries.printer_status(Game.state, Game.rules, printer) == OrderQueries.PrinterStatus.DONE
	var was_done: bool = _printers_done.get(printer_uid, false)
	_printers_done[printer_uid] = done
	if done and not was_done and character_near(item_for(WorldInteractable.Kind.PRINTER, printer_uid)):
		character.animator.react(CharacterAnimator.Reaction.PRINTER_READY, _print_head_of(printer_uid))
		if character.animator.current_gesture() == CharacterGestures.Gesture.THUMBS_UP and not character.animator.panel_open:
			character.face_camera()


func _on_computer_changed() -> void:
	character.animator.modeling = Game.state.designing_uid >= 0


## Avanzó el reloj (un minuto de juego): la luz va hacia la hora nueva
## mezclándose y el personaje sabe qué hora es (bosteza de noche).
func _on_time_changed(game_minutes: float) -> void:
	day_cycle.go_to_hour(game_minutes / GameClock.MINUTES_PER_HOUR)
	character.animator.game_minutes = game_minutes


## Partida nueva o cargada: el cuarto igual a su estado (sin efecto de
## impresión), la luz de su hora de una vez (sin mezcla), el animador sin
## reacciones pendientes y al día, y la decoración de su nivel.
func _on_game_loaded() -> void:
	sync_models(false)
	day_cycle.set_hour(Game.state.game_minutes / GameClock.MINUTES_PER_HOUR)
	_show_decor_level(_level())
	character.animator.reset()
	_on_computer_changed()
	character.animator.game_minutes = Game.state.game_minutes
	_printers_done.clear()
	for printer: OwnedPrinter in Game.state.printers:
		_printers_done[printer.uid] = OrderQueries.printer_status(Game.state, Game.rules, printer) == OrderQueries.PrinterStatus.DONE


## Lo que el personaje mira de una impresora: su cabezal o, en la de resina
## (que no tiene), la placa.
func _watched_part(printer: Node3D) -> Node3D:
	for part: String in ["PrintHead", "PlateTop"]:
		var node: Node3D = printer.get_node_or_null(part)
		if node != null:
			return node
	return printer


## Dónde está lo que se mira de una impresora (o el personaje, si ya no está).
func _print_head_of(printer_uid: int) -> Vector3:
	var printer: Node3D = get_node_or_null("Printer%d" % printer_uid)
	return _watched_part(printer).global_position if printer != null else character.model.position


## Lo que se toca de un modelo: la caja de sus mallas (no depende de su
## material ni de lo que se ve: es la misma mientras se imprime) y dónde
## está. Si ocupa lugar en el piso (BLOCKING), _rebuild_room lo vuelve
## obstáculo para caminar.
func _make_item(kind: WorldInteractable.Kind, ref: int, node: Node3D) -> WorldInteractable:
	return WorldInteractable.new(kind, ref, PropBounds.local_aabb(node), node.global_transform)


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


## Las luces del escritorio (biblia §6.2): la lámpara (cc_pl0) en su
## ampolleta y el monitor (cc_pl1) delante de la pantalla, en los marcadores
## "LampBulb" y "ScreenGlow" del modelo.
func _place_desk_lights(desk: Node3D) -> void:
	day_cycle.place_light("desk_lamp", (desk.get_node("LampBulb") as Node3D).global_position)
	day_cycle.place_light("monitor", (desk.get_node("ScreenGlow") as Node3D).global_position)


## Los halos de noche del escritorio (ComputerDeskModel.night_lights): la
## mancha de la lámpara sobre la mesa y el resplandor del monitor.
func _add_desk_halos(desk: Node3D) -> void:
	for light: Dictionary in ComputerDeskModel.night_lights():
		halos.add_glow(desk.transform * (light["at"] as Transform3D), light["size"], light["color"])


## La luz LED que alumbra la cama de la impresora del piso (cc_pl3), en su
## marcador "BedLight".
func _place_printer_led(printer: Node3D) -> void:
	day_cycle.place_light("printer_led", (printer.get_node("BedLight") as Node3D).global_position)


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
## su tablero; sin mueble, ninguna caja), y la cama de la decoración.
func _publish_window_occluders(under_window: Node3D, furniture_id: String = "") -> void:
	window_occluder = AABB()
	if under_window != null:
		var local: AABB = ComputerDeskModel.table_box() if furniture_id == DeskSheet.FURNITURE_ID else PropBounds.local_aabb(under_window)
		window_occluder = under_window.transform * local
	bed_occluder = RoomDecor.BED_BOX
	_publish_box(&"cc_occ_a_c", &"cc_occ_a_h", window_occluder)
	_publish_box(&"cc_occ_b_c", &"cc_occ_b_h", bed_occluder)


static func _publish_box(center_name: StringName, half_name: StringName, box: AABB) -> void:
	var center: Vector3 = box.get_center()
	var half: Vector3 = box.size / 2.0
	RenderingServer.global_shader_parameter_set(center_name, Vector4(center.x, center.y, center.z, 0.0))
	RenderingServer.global_shader_parameter_set(half_name, Vector4(half.x, half.y, half.z, 0.0))


## Dónde está el personaje para los sombreadores: su mancha en el piso y la
## cápsula que tapa el parche de la ventana (cc_char_pos).
func _publish_character() -> void:
	if character == null:
		return
	var feet: Vector3 = character.model.position
	RenderingServer.global_shader_parameter_set(&"cc_char_pos", Vector4(feet.x, feet.y, feet.z, CHARACTER_SHADOW_RADIUS))

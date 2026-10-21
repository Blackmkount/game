class_name RoomView
extends Node3D
## Escena 3D del espacio actual, armada a partir del estado de la partida:
## muebles en sus lugares, impresoras (en muebles o en el suelo), marcas de
## lugares libres y el personaje.

const CAMERA_SIZE: float = 6.8
const CAMERA_TARGET: Vector3 = Vector3(-0.15, 1.95, -0.15)
const CAMERA_DISTANCE: float = 20.0
const CAMERA_YAW: float = 45.0
## Inclinación clásica del pixel art isométrico (proporción 2:1).
const CAMERA_PITCH: float = -30.0
## Proporción de pantalla (alto / ancho) para la que está pensado CAMERA_SIZE.
## En teléfonos más altos se acerca un poco la cámara para llenar el espacio.
const BASE_ASPECT: float = 16.0 / 9.0
const MIN_ZOOM: float = 0.85

var _camera: Camera3D
var _marker_material: StandardMaterial3D


func _ready() -> void:
	_build_environment()
	_build_camera()
	RoomShell.build(self)
	if Game.state != null:
		_build_contents()


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
	sun.directional_shadow_max_distance = 30.0
	add_child(sun)


func _build_camera() -> void:
	var camera: Camera3D = Camera3D.new()
	_camera = camera
	camera.name = "Camera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = CAMERA_SIZE
	camera.near = 0.1
	camera.far = 60.0
	camera.rotation_degrees = Vector3(CAMERA_PITCH, CAMERA_YAW, 0.0)
	camera.position = CAMERA_TARGET - camera.basis * Vector3.FORWARD * CAMERA_DISTANCE
	camera.current = true
	add_child(camera)
	get_viewport().size_changed.connect(_fit_camera)
	_fit_camera()


func _fit_camera() -> void:
	var size: Vector2 = get_viewport().get_visible_rect().size
	if size.x <= 0.0:
		return
	var aspect: float = size.y / size.x
	_camera.size = CAMERA_SIZE * clampf(sqrt(BASE_ASPECT / aspect), MIN_ZOOM, 1.0)


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

	_marker_material = WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, 0.6)
	for slot: int in layout.slots.size():
		if slot not in used_slots:
			var marker: Node3D = SlotMarker.build(self, "FreeSlot%d" % slot, _marker_material)
			marker.transform = layout.slots[slot]
	_pulse_markers()

	var character: Node3D = CharacterModel.build(self, "Character")
	character.transform = layout.character_spot
	_animate_idle(character)


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


## Respiración del personaje y una mirada de vez en cuando a la impresora.
func _animate_idle(character: Node3D) -> void:
	var body: Node3D = character.get_node("Body")
	var head: Node3D = body.get_node("Head")
	var breathing: Tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	breathing.tween_property(body, "position:y", body.position.y + 0.015, 1.1)
	breathing.tween_property(body, "position:y", body.position.y, 1.1)
	var looking: Tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	looking.tween_interval(2.5)
	looking.tween_property(head, "rotation_degrees:y", -25.0, 0.6)
	looking.tween_interval(1.8)
	looking.tween_property(head, "rotation_degrees:y", 0.0, 0.6)
	looking.tween_interval(3.0)

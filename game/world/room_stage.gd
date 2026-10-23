class_name RoomStage
extends RefCounted
## Lo que rodea al cuarto y no sale de la partida (RoomView lo arma una vez):
## el entorno del motor y el único sol con su DayCycle (biblia de arte §2.5),
## la cámara con el fondo degradado del diorama (§8.10) y la sombra suave
## bajo la base.

const BACKDROP_SHADER: Shader = preload("res://game/world/look/backdrop.gdshader")
const BASE_SHADOW_SHADER: Shader = preload("res://game/world/look/base_shadow.gdshader")
const CAMERA_SIZE: float = 6.8
const CAMERA_TARGET: Vector3 = Vector3(-0.15, 1.95, -0.15)
## Proporción de pantalla (alto / ancho) para la que está pensado CAMERA_SIZE.
## En teléfonos más altos se acerca un poco la cámara para llenar el espacio.
const BASE_ASPECT: float = 16.0 / 9.0
const MIN_ZOOM: float = 0.85
## Sombra del sol (biblia §2.6).
const SUN_SHADOW_BIAS: float = 0.04
const SUN_SHADOW_NORMAL_BIAS: float = 1.2
const SUN_SHADOW_OPACITY: float = 0.9
## Sombra suave bajo la base del diorama: tamaño respecto del cuarto y cuánto
## más abajo que la base.
const BASE_SHADOW_SCALE: float = 1.9
const BASE_SHADOW_GAP: float = 0.06


## Entorno de la biblia §2.5 en `room`: el ambiente, los reflejos y los
## efectos del motor apagados (los calcula el sombreador del mundo, ver
## game/world/look/) y tonemap lineal, para que la cuenta de color sea una
## suma simple. Un solo sol con sombra, que orienta el DayCycle que devuelve.
static func build_environment(room: Node3D) -> DayCycle:
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(WorldPalette.BACKGROUND)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	world_environment.environment = environment
	room.add_child(world_environment)

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
	room.add_child(sun)

	var day_cycle: DayCycle = DayCycle.new()
	day_cycle.name = "DayCycle"
	day_cycle.sun = sun
	room.add_child(day_cycle)
	var half: float = RoomShell.SIZE / 2.0
	RenderingServer.global_shader_parameter_set(&"cc_room", Vector4(-half, -half, RoomShell.SIZE, RoomShell.WALL_HEIGHT))
	WindowSpec.publish()
	return day_cycle


## La cámara del cuarto en `room`, con el fondo degradado del diorama (sus
## colores los pone `day_cycle`). Se acerca un poco en pantallas más altas.
static func build_camera(room: Node3D, day_cycle: DayCycle) -> CameraRig:
	var camera: CameraRig = CameraRig.new()
	camera.name = "Camera"
	room.add_child(camera)
	var half: float = RoomShell.SIZE / 2.0 + RoomShell.WALL_THICKNESS
	var room_bounds: AABB = AABB(Vector3(-half, 0.0, -half), Vector3(half + RoomShell.SIZE / 2.0, RoomShell.WALL_HEIGHT, half + RoomShell.SIZE / 2.0))
	camera.configure(room_bounds, CAMERA_TARGET, fitted_camera_size(room.get_viewport()))
	camera.current = true
	_build_backdrop(camera, day_cycle)
	room.get_viewport().size_changed.connect(func() -> void: camera.set_base_size(fitted_camera_size(room.get_viewport())))
	return camera


## Sombra suave bajo la base del diorama: lo apoya en el fondo.
static func build_base_shadow(room: Node3D) -> void:
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
	room.add_child(shadow)


## El tamaño de la cámara para la pantalla de `viewport`.
static func fitted_camera_size(viewport: Viewport) -> float:
	var size: Vector2 = viewport.get_visible_rect().size
	if size.x <= 0.0:
		return CAMERA_SIZE
	var aspect: float = size.y / size.x
	return CAMERA_SIZE * clampf(sqrt(BASE_ASPECT / aspect), MIN_ZOOM, 1.0)


## Fondo degradado del diorama (biblia §8.10): un cuadro pegado a la cámara,
## al fondo de lo que ve. Sus colores los pone DayCycle.
static func _build_backdrop(camera: CameraRig, day_cycle: DayCycle) -> void:
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

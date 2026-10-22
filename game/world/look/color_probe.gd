class_name ColorProbe
extends Node
## Mide una vez, al arrancar, cómo escribe el motor cada pasada de luz, para
## que "lo que dice el hex sea lo que se ve" en cualquier teléfono (biblia de
## arte §2.4).
##
## En Compatibility el sol con sombra se dibuja en otra pasada que se mezcla
## en sRGB, y la pasada base (ambiente, luz propia) en llvmpipe se escribe
## sin convertir. Eso puede cambiar con el teléfono o con una versión de
## Godot, así que no se deja ninguna compensación escrita a mano: se dibujan
## dos cuadritos (uno con 0,25 de pasada base, otro con 0,5 de sol con
## sombra), se lee el píxel y se decide si cada pasada se convierte. El
## resultado va a los globales cc_base_fix y cc_sun_fix, que usan cc_out() y
## cc_sun_out() (look_globals.gdshaderinc).
##
## Si la lectura falla o sale fuera de rango, quedan los valores de
## llvmpipe. Sin pantalla (las pruebas) no se mide nada.

enum Status { PENDING, MEASURED, OUT_OF_RANGE, NO_SCREEN }

## Lo que dibuja cada cuadrito (sin convertir).
const BASE_LEVEL: float = 0.25
const SUN_LEVEL: float = 0.5
## Lo más lejos que puede quedar la lectura de lo esperado.
const TOLERANCE: float = 0.06
## Lo medido en llvmpipe: la pasada base no se convierte; la del sol, sí.
const DEFAULT_BASE_FIX: int = 0
const DEFAULT_SUN_FIX: int = 1
## Lado de cada cuadrito en píxeles, y su centro.
const SQUARE_PX: int = 8
const CENTER_PX: int = 4
const SHADER: Shader = preload("res://game/world/look/color_probe.gdshader")

## Resultado (para el panel de depuración y la captura de calibración).
static var status: Status = Status.PENDING
static var base_fix: int = DEFAULT_BASE_FIX
static var sun_fix: int = DEFAULT_SUN_FIX
## Lo que se leyó en cada cuadrito (0–1); -1 si no se leyó.
static var base_reading: float = -1.0
static var sun_reading: float = -1.0

var _viewport: SubViewport


## Decide, con lo leído en el cuadrito de la pasada base y en el del sol, si
## cada pasada se convierte a sRGB. Pura: no toca nada.
static func decide(base_value: float, sun_value: float) -> Dictionary:
	var base: int = _pass_fix(base_value, BASE_LEVEL)
	var sun: int = _pass_fix(sun_value, SUN_LEVEL)
	var valid: bool = base >= 0 and sun >= 0
	return {
		"valid": valid,
		"base_fix": base if valid else DEFAULT_BASE_FIX,
		"sun_fix": sun if valid else DEFAULT_SUN_FIX,
	}


## Mide una sola vez en todo el juego. `msaa`: el del dibujo del mundo.
static func run(host: Node, msaa: Viewport.MSAA) -> void:
	if status != Status.PENDING:
		return
	if DisplayServer.get_name() == "headless":
		status = Status.NO_SCREEN
		return
	var probe: ColorProbe = ColorProbe.new()
	probe.name = "ColorProbe"
	probe._build(msaa)
	host.get_tree().root.add_child.call_deferred(probe)


## 0 si `value` es el nivel sin convertir, 1 si es el nivel pasado a sRGB,
## -1 si no se parece a ninguno.
static func _pass_fix(value: float, level: float) -> int:
	if absf(value - level) <= TOLERANCE:
		return 0
	if absf(value - Color(level, level, level).linear_to_srgb().r) <= TOLERANCE:
		return 1
	return -1


static func _apply(result: Dictionary) -> void:
	base_fix = result["base_fix"]
	sun_fix = result["sun_fix"]
	RenderingServer.global_shader_parameter_set(&"cc_base_fix", float(base_fix))
	RenderingServer.global_shader_parameter_set(&"cc_sun_fix", float(sun_fix))


func _ready() -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image: Image = _viewport.get_texture().get_image()
	if image != null and image.get_width() >= SQUARE_PX * 2:
		base_reading = image.get_pixel(CENTER_PX, CENTER_PX).r
		sun_reading = image.get_pixel(SQUARE_PX + CENTER_PX, CENTER_PX).r
	var result: Dictionary = decide(base_reading, sun_reading)
	status = Status.MEASURED if result["valid"] else Status.OUT_OF_RANGE
	_apply(result)
	queue_free()


## Un mundo aparte: una cámara, un sol con sombra y dos cuadritos que miran
## a la cámara y al sol (el de la izquierda solo la pasada base, el de la
## derecha solo el sol).
func _build(msaa: Viewport.MSAA) -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(SQUARE_PX * 2, SQUARE_PX)
	_viewport.own_world_3d = true
	_viewport.msaa_3d = msaa
	_viewport.positional_shadow_atlas_size = 0
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_viewport)

	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color.BLACK
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = environment
	_viewport.add_child(world_environment)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_viewport.add_child(sun)

	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = 1.0
	camera.position = Vector3(0.0, 0.0, 2.0)
	_viewport.add_child(camera)

	_square(Vector3(-0.5, 0.0, 0.0), BASE_LEVEL, 0.0)
	_square(Vector3(0.5, 0.0, 0.0), 0.0, SUN_LEVEL)


func _square(position: Vector3, base_level: float, sun_level: float) -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("base_level", base_level)
	material.set_shader_parameter("sun_level", sun_level)
	var square: MeshInstance3D = MeshInstance3D.new()
	square.mesh = quad
	square.material_override = material
	square.position = position
	_viewport.add_child(square)

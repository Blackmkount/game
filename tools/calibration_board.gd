extends CanvasLayer
## Captura 00_calibracion (biblia de arte §2.4): la prueba de que "lo que dice
## el hex es lo que se ve". Lo usa tools/screenshot_runner.gd.
##
## Dibuja tarjetas gris, blanca y de la paleta con los materiales del mundo
## (arriba por uniform, WorldPalette.paint; abajo por vértice, una malla de
## KitMesh con WorldPalette.kit)
## cuatro veces: solo ambiente 0,25, solo sol 0,5 (con sombra), los dos, y los
## dos con el sol sin sombra (como en el nivel de calidad Bajo). Las imágenes
## se muestran una debajo de la otra, con lo que midió ColorProbe al
## arrancar, y se revisan los píxeles: blanco 64, 128, 191 y 191; gris la
## mitad; vértice y uniform iguales.

## Colores de las tarjetas: gris, blanco y muestras de la paleta.
const CARDS: Array[String] = [
	"808080", "ffffff", LookPalette.FLOOR_TILE, LookPalette.WALL_WINDOW, LookPalette.SKIN, LookPalette.HOODIE,
]
## Lo que se espera ver de la tarjeta blanca y la gris en cada condición
## (0–255) y la tolerancia.
const WHITE_EXPECTED: Array[float] = [64.0, 128.0, 191.0, 191.0]
const WHITE_TOLERANCE: Array[float] = [3.0, 3.0, 4.0, 4.0]
const GRAY_EXPECTED: Array[float] = [32.0, 64.0, 96.0, 96.0]
const GRAY_TOLERANCE: float = 3.0
## Vértice contra uniform, en cada canal (0–255).
const VERTEX_TOLERANCE: float = 2.0
const CONDITIONS: Array[String] = [
	"Solo ambiente 0,25", "Solo sol 0,5 (con sombra)", "Ambiente 0,25 + sol 0,5", "Ambiente 0,25 + sol 0,5 sin sombra (Baja)",
]
## Condiciones con ambiente, con sol y con el sol sin sombra.
const WITH_AMBIENT: Array[bool] = [true, false, true, true]
const WITH_SUN: Array[bool] = [false, true, true, true]
const SUN_SHADOWED: Array[bool] = [true, true, true, false]
const AMBIENT: float = 0.25
const SUN: float = 0.5
## Tamaño de cada imagen y de las tarjetas (metros; la cámara ve 7,2 m de
## ancho: 100 píxeles por metro).
const RENDER_SIZE: Vector2i = Vector2i(720, 250)
const VIEW_WIDTH: float = 7.2
const CARD: float = 0.8
const CARD_STEP: float = 1.15
const ROW_Y: float = 0.5
## Las tarjetas van lejos del cuarto, para que no les llegue su oclusión.
const FAR_AWAY: Vector3 = Vector3(100.0, 10.0, 100.0)

var problems: Array[String] = []

var _viewport: SubViewport
var _sun: DirectionalLight3D
var _rows: VBoxContainer


func _ready() -> void:
	layer = 100
	var background: ColorRect = ColorRect.new()
	background.color = Color(LookPalette.BACKGROUND)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	_rows = VBoxContainer.new()
	_rows.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rows.add_theme_constant_override("separation", 6)
	add_child(_rows)
	_title("00 · Calibración del modelo de color")
	_title("ColorProbe: %s · base %.3f → fix %d · sol %.3f → fix %d" % [
		ColorProbe.Status.keys()[ColorProbe.status], ColorProbe.base_reading, ColorProbe.base_fix,
		ColorProbe.sun_reading, ColorProbe.sun_fix])
	_build_world()


## Dibuja las condiciones, las muestra y revisa los píxeles. Después, quien
## la llama vuelve a poner la luz del cuarto (DayCycle).
func render_all() -> void:
	for i: int in CONDITIONS.size():
		var image: Image = await _render(i)
		_title(CONDITIONS[i])
		var shown: TextureRect = TextureRect.new()
		shown.texture = ImageTexture.create_from_image(image)
		shown.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		_rows.add_child(shown)
		_check(i, image)
	RenderingServer.global_shader_parameter_set(&"cc_sun_shadowed", 1.0)


func _build_world() -> void:
	_viewport = SubViewport.new()
	_viewport.size = RENDER_SIZE
	_viewport.own_world_3d = true
	_viewport.msaa_3d = WorldViewport.MSAA_HIGH
	_viewport.positional_shadow_atlas_size = 0
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_viewport)
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(LookPalette.BACKGROUND)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = environment
	_viewport.add_child(world_environment)
	# El sol llega de frente a las tarjetas (desde la cámara): sin borde de
	# luz ni brillo, suma exactamente color × energía.
	_sun = DirectionalLight3D.new()
	_sun.shadow_enabled = true
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_sun.light_color = Color.WHITE
	_sun.position = FAR_AWAY
	_viewport.add_child(_sun)
	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = VIEW_WIDTH
	camera.position = FAR_AWAY + Vector3(0.0, 0.0, 5.0)
	_viewport.add_child(camera)
	for i: int in CARDS.size():
		var x: float = (i - (CARDS.size() - 1) / 2.0) * CARD_STEP
		_card(WorldPalette.paint(CARDS[i]), _quad_mesh(), Vector3(x, ROW_Y, 0.0))
		_card(WorldPalette.kit(), _vertex_quad(CARDS[i]), Vector3(x, -ROW_Y, 0.0))


func _card(material: Material, mesh: Mesh, offset: Vector3) -> void:
	var card: MeshInstance3D = MeshInstance3D.new()
	card.mesh = mesh
	card.material_override = material
	card.position = FAR_AWAY + offset
	_viewport.add_child(card)


func _quad_mesh() -> QuadMesh:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE * CARD
	return quad


## Un cuadrado armado con el kit de formas (KitMesh): color en el vértice,
## sin oclusión de contacto, superficie lisa, no impreso y sin luz propia.
func _vertex_quad(hex: String) -> ArrayMesh:
	var kit: KitMesh = KitMesh.new()
	kit.ao_enabled = false
	kit.paint(hex).quad(Vector2.ONE * CARD, Vector3.ZERO)
	return kit.commit()


## Pone la luz de la condición `index` y dibuja una vez.
func _render(index: int) -> Image:
	var ambient: float = AMBIENT if WITH_AMBIENT[index] else 0.0
	_sun.visible = WITH_SUN[index]
	_sun.light_energy = SUN
	_sun.shadow_enabled = SUN_SHADOWED[index]
	RenderingServer.global_shader_parameter_set(&"cc_sun_shadowed", 1.0 if SUN_SHADOWED[index] else 0.0)
	var ambient_color: Vector3 = Vector3.ONE * ambient
	RenderingServer.global_shader_parameter_set(&"cc_amb_sky", ambient_color)
	RenderingServer.global_shader_parameter_set(&"cc_amb_ground", ambient_color)
	RenderingServer.global_shader_parameter_set(&"cc_fill", Vector4.ZERO)
	RenderingServer.global_shader_parameter_set(&"cc_window_color", Vector3.ZERO)
	for slot: StringName in DayCycle.LIGHT_COLOR_GLOBALS:
		RenderingServer.global_shader_parameter_set(slot, Vector4.ZERO)
	RenderingServer.global_shader_parameter_set(&"cc_strip_col", Vector4.ZERO)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	return _viewport.get_texture().get_image()


func _check(index: int, image: Image) -> void:
	for i: int in CARDS.size():
		var uniform_color: Color = image.get_pixelv(_card_pixel(i, true))
		var vertex_color: Color = image.get_pixelv(_card_pixel(i, false))
		for channel: int in 3:
			if absf(uniform_color[channel] - vertex_color[channel]) * 255.0 > VERTEX_TOLERANCE:
				problems.append("%s, tarjeta %s: uniform %s y vértice %s no son iguales" % [
					CONDITIONS[index], CARDS[i], uniform_color.to_html(false), vertex_color.to_html(false)])
				break
	_expect(index, "blanca", image.get_pixelv(_card_pixel(CARDS.find("ffffff"), true)).r * 255.0, WHITE_EXPECTED[index], WHITE_TOLERANCE[index])
	_expect(index, "gris", image.get_pixelv(_card_pixel(CARDS.find("808080"), true)).r * 255.0, GRAY_EXPECTED[index], GRAY_TOLERANCE)


func _expect(index: int, card_name: String, value: float, expected: float, tolerance: float) -> void:
	if absf(value - expected) > tolerance:
		problems.append("%s, tarjeta %s: %.0f en vez de %.0f ± %.0f" % [CONDITIONS[index], card_name, value, expected, tolerance])


## Píxel del centro de una tarjeta en la imagen de una condición.
func _card_pixel(index: int, top_row: bool) -> Vector2i:
	var pixels_per_meter: float = RENDER_SIZE.x / VIEW_WIDTH
	var x: float = (index - (CARDS.size() - 1) / 2.0) * CARD_STEP
	var y: float = ROW_Y if top_row else -ROW_Y
	return Vector2i(roundi(RENDER_SIZE.x / 2.0 + x * pixels_per_meter), roundi(RENDER_SIZE.y / 2.0 - y * pixels_per_meter))


func _title(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rows.add_child(label)

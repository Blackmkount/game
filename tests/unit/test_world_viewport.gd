extends GutTest
## Vista del mundo a resolución alta (WorldViewport): el dibujo tiene el ancho
## de la pantalla física hasta el tope del nivel de calidad (Alta 1080 px,
## Baja 720 px: GraphicsQuality), se ve del tamaño de la pantalla y las
## cuentas entre la interfaz y el dibujo van y vuelven.

## Ancho de la interfaz (la pantalla virtual del proyecto).
const UI_WIDTH: float = 720.0
## Ventanas de prueba: ancho y alto físicos, y k esperado (píxeles del dibujo
## por píxel de la interfaz).
const WINDOWS: Array[Array] = [
	[405, 720, 0.5625],
	[720, 1280, 1.0],
	[1080, 2400, 1.5],
	[1440, 3200, 1.5],
]
## k esperado en el nivel Bajo (tope de 720 px), en las mismas ventanas.
const LOW_K: Array[float] = [0.5625, 1.0, 1.0, 1.0]
const SETTINGS_PATH: String = "user://test_world_viewport_settings.cfg"
const HIGH: GraphicsQuality.Level = GraphicsQuality.Level.HIGH
const LOW: GraphicsQuality.Level = GraphicsQuality.Level.LOW

var _previous_window_size: Vector2i
var _previous_quality: GraphicsQuality
var _previous_settings_path: String
var _quality: GraphicsQuality
var _screen: Control
var _view: WorldViewport
var _sub: SubViewport
var _camera: Camera3D


func before_each() -> void:
	_previous_window_size = get_tree().root.size
	# Una calidad propia, en Alta, guardada en un archivo de esta prueba.
	_previous_quality = GraphicsQuality.current
	_previous_settings_path = UserSettings.path
	UserSettings.path = SETTINGS_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	_quality = GraphicsQuality.new(UserSettings.load_settings())
	_quality.set_mode(GraphicsQuality.Mode.HIGH)
	GraphicsQuality.current = _quality
	_screen = Control.new()
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view = WorldViewport.new()
	_view.name = "WorldView"
	_sub = SubViewport.new()
	_sub.name = "SubViewport"
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.keep_aspect = Camera3D.KEEP_WIDTH
	_camera.size = 6.8
	_camera.rotation_degrees = Vector3(CameraRig.PITCH, CameraRig.YAW, 0.0)
	_camera.position = -_camera.basis.z * -20.0
	_sub.add_child(_camera)
	_view.add_child(_sub)
	_screen.add_child(_view)
	add_child_autofree(_screen)
	_camera.current = true


func after_each() -> void:
	get_tree().root.size = _previous_window_size
	GraphicsQuality.current = _previous_quality
	UserSettings.path = _previous_settings_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))


func test_k_is_the_physical_width_up_to_the_cap_over_the_ui_width() -> void:
	for i: int in WINDOWS.size():
		var window: Array = WINDOWS[i]
		var k: float = WorldViewport.scale_for(float(window[0]), UI_WIDTH, GraphicsQuality.MAX_WIDTH[HIGH])
		assert_almost_eq(k, float(window[2]), 0.000001, "Ventana de %d px" % window[0])
		var low: float = WorldViewport.scale_for(float(window[0]), UI_WIDTH, GraphicsQuality.MAX_WIDTH[LOW])
		assert_almost_eq(low, LOW_K[i], 0.000001, "Ventana de %d px en Baja" % window[0])
	assert_eq(WorldViewport.scale_for(0.0, UI_WIDTH, GraphicsQuality.MAX_WIDTH[HIGH]), 1.0, "Sin pantalla, uno a uno")


func test_the_world_is_drawn_at_the_internal_width_and_fills_the_screen() -> void:
	for window: Array in WINDOWS:
		await _set_window(window)
		var k: float = float(window[2])
		var physical: float = float(window[0])
		assert_almost_eq(_view.view_per_ui, k, 0.000001, "k con %d px" % window[0])
		assert_eq(_sub.size.x, int(minf(physical, GraphicsQuality.MAX_WIDTH[HIGH])), "Ancho del dibujo con %d px" % window[0])
		# Se ve del tamaño de la pantalla: lo que sobra al redondear es menos
		# de un píxel del dibujo.
		var shown: Vector2 = Vector2(_sub.size) / k
		assert_almost_eq(shown.x, _screen.size.x, 0.001, "Llena el ancho con %d px" % window[0])
		assert_between(shown.y - _screen.size.y, 0.0, 1.0 / k + 0.001, "Llena el alto con %d px" % window[0])
	assert_eq(_sub.msaa_3d, GraphicsQuality.MSAA[HIGH], "Bordes suavizados")
	assert_eq(_view.stretch_shrink, 1)
	assert_eq(_view.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR, "Se estira sin pixelar")


## Al pasar a Baja (con el juego abierto) el dibujo baja a 720 px como mucho
## y a MSAA 2×, sigue llenando la pantalla, y vuelve al pasar a Alta.
func test_the_low_level_draws_at_most_720_pixels_with_less_msaa() -> void:
	assert_eq(GraphicsQuality.MAX_WIDTH[LOW], 720.0)
	assert_eq(GraphicsQuality.MSAA[LOW], Viewport.MSAA_2X)
	for i: int in WINDOWS.size():
		var window: Array = WINDOWS[i]
		await _set_window(window)
		_quality.set_mode(GraphicsQuality.Mode.LOW)
		await wait_process_frames(2)
		assert_almost_eq(_view.view_per_ui, LOW_K[i], 0.000001, "k en Baja con %d px" % window[0])
		assert_eq(_sub.size.x, int(minf(float(window[0]), GraphicsQuality.MAX_WIDTH[LOW])), "Ancho del dibujo en Baja con %d px" % window[0])
		assert_almost_eq(Vector2(_sub.size).x / LOW_K[i], _screen.size.x, 0.001, "Llena el ancho en Baja con %d px" % window[0])
		assert_eq(_sub.msaa_3d, GraphicsQuality.MSAA[LOW], "Menos suavizado en Baja")
		_quality.set_mode(GraphicsQuality.Mode.HIGH)
		await wait_process_frames(2)
		assert_almost_eq(_view.view_per_ui, float(window[2]), 0.000001, "De vuelta en Alta con %d px" % window[0])
		assert_eq(_sub.msaa_3d, GraphicsQuality.MSAA[HIGH], "De vuelta el suavizado de Alta")


## Con pantalla, mientras el automático mide, cada cuadro de verdad le llega
## (WorldViewport._process): un teléfono lento pasa a Baja, el dibujo se
## ajusta y deja de contar cuadros. Los cuadros los da la prueba.
func test_while_automatic_measures_each_frame_reaches_it() -> void:
	await _set_window(WINDOWS[2])
	_view.has_screen = true
	_quality.set_mode(GraphicsQuality.Mode.AUTO)
	assert_true(_quality.is_measuring())
	assert_true(_view.is_processing(), "Con pantalla y midiendo, cuenta cuadros")
	_view.set_process(false)
	var slow_frame: float = 0.030
	for i: int in ceili((GraphicsQuality.AUTO_WARMUP_SECONDS + GraphicsQuality.AUTO_WINDOW_SECONDS + 0.1) / slow_frame):
		_view._process(slow_frame)
	assert_eq(_quality.level, LOW, "Los cuadros lentos llegaron al automático")
	assert_false(_view.is_processing(), "Terminó de medir: no cuenta más")
	assert_eq(_sub.msaa_3d, GraphicsQuality.MSAA[LOW])
	await wait_process_frames(2)
	assert_eq(_sub.size.x, int(GraphicsQuality.MAX_WIDTH[LOW]), "El dibujo bajó al ancho de Baja")
	_view.has_screen = false
	_quality.set_mode(GraphicsQuality.Mode.AUTO)
	assert_true(_quality.is_measuring())
	assert_false(_view.is_processing(), "Sin pantalla no hay cuadros de verdad que medir")


## Tapado por una sección (biblia §13: no dibujar lo que no se ve): se dibuja
## una vez más y se queda quieto; al volver, cada cuadro. Un cambio de
## calidad mientras tanto se dibuja una vez. Si el automático mide, sigue
## dibujando hasta terminar.
func test_covered_by_a_section_the_world_stops_drawing() -> void:
	assert_eq(_sub.render_target_update_mode, SubViewport.UPDATE_ALWAYS, "Cada cuadro")
	_view.set_covered(true)
	# Después de ese cuadro el motor lo deja en UPDATE_DISABLED (sin pantalla
	# no dibuja, así que aquí no se ve).
	assert_eq(_sub.render_target_update_mode, SubViewport.UPDATE_ONCE, "Tapado: una vez más y quieto")
	_quality.set_mode(GraphicsQuality.Mode.LOW)
	assert_eq(_sub.render_target_update_mode, SubViewport.UPDATE_ONCE, "Otra calidad: se dibuja una vez")
	_view.set_covered(false)
	assert_eq(_sub.render_target_update_mode, SubViewport.UPDATE_ALWAYS, "Destapado: cada cuadro")
	_view.has_screen = true
	_quality.set_mode(GraphicsQuality.Mode.AUTO)
	_view.set_covered(true)
	assert_eq(_sub.render_target_update_mode, SubViewport.UPDATE_ALWAYS, "Midiendo, sigue dibujando")
	_view.set_process(false)
	for i: int in ceili((GraphicsQuality.AUTO_WARMUP_SECONDS + GraphicsQuality.AUTO_WINDOW_SECONDS + 0.1) / 0.01):
		_view._process(0.01)
	assert_false(_quality.is_measuring())
	assert_eq(_sub.render_target_update_mode, SubViewport.UPDATE_ONCE, "Terminó de medir: tapado, se queda quieto")
	_view.has_screen = false


func test_ui_and_view_points_round_trip() -> void:
	for window: Array in WINDOWS:
		await _set_window(window)
		var k: float = float(window[2])
		var ui_point: Vector2 = Vector2(300.0, 700.0)
		var view_point: Vector2 = _view.ui_to_view(ui_point)
		assert_almost_eq(view_point, ui_point * k, Vector2.ONE * 0.001, "Interfaz → dibujo con %d px" % window[0])
		assert_almost_eq(_view.view_to_ui(view_point), ui_point, Vector2.ONE * 0.001, "Y de vuelta")
		# Un punto del mundo llevado a la interfaz y de vuelta al dibujo cae
		# en el mismo píxel, y el rayo de ese píxel pasa por el punto.
		var world_point: Vector3 = Vector3(0.4, 0.3, -0.7)
		var projected: Vector2 = _camera.unproject_position(world_point)
		var back: Vector2 = _view.ui_to_view(_view.view_to_ui(projected))
		assert_almost_eq(back, projected, Vector2.ONE * 0.001, "Mundo → interfaz → dibujo con %d px" % window[0])
		var origin: Vector3 = _camera.project_ray_origin(back)
		var direction: Vector3 = _camera.project_ray_normal(back)
		var miss: float = (world_point - origin).cross(direction).length()
		assert_lt(miss, 0.001, "El rayo pasa por el punto con %d px" % window[0])


func _set_window(window: Array) -> void:
	get_tree().root.size = Vector2i(int(window[0]), int(window[1]))
	await wait_process_frames(2)

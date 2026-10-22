extends GutTest
## Vista del mundo a resolución alta (WorldViewport): el dibujo tiene el ancho
## de la pantalla física hasta el tope del nivel Alto, se ve del tamaño de la
## pantalla y las cuentas entre la interfaz y el dibujo van y vuelven.

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

var _previous_window_size: Vector2i
var _screen: Control
var _view: WorldViewport
var _sub: SubViewport
var _camera: Camera3D


func before_each() -> void:
	_previous_window_size = get_tree().root.size
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


func test_k_is_the_physical_width_up_to_the_cap_over_the_ui_width() -> void:
	for window: Array in WINDOWS:
		var k: float = WorldViewport.scale_for(float(window[0]), UI_WIDTH, WorldViewport.MAX_WIDTH_HIGH)
		assert_almost_eq(k, float(window[2]), 0.000001, "Ventana de %d px" % window[0])
	assert_eq(WorldViewport.scale_for(0.0, UI_WIDTH, WorldViewport.MAX_WIDTH_HIGH), 1.0, "Sin pantalla, uno a uno")


func test_the_world_is_drawn_at_the_internal_width_and_fills_the_screen() -> void:
	for window: Array in WINDOWS:
		await _set_window(window)
		var k: float = float(window[2])
		var physical: float = float(window[0])
		assert_almost_eq(_view.view_per_ui, k, 0.000001, "k con %d px" % window[0])
		assert_eq(_sub.size.x, int(minf(physical, WorldViewport.MAX_WIDTH_HIGH)), "Ancho del dibujo con %d px" % window[0])
		# Se ve del tamaño de la pantalla: lo que sobra al redondear es menos
		# de un píxel del dibujo.
		var shown: Vector2 = Vector2(_sub.size) / k
		assert_almost_eq(shown.x, _screen.size.x, 0.001, "Llena el ancho con %d px" % window[0])
		assert_between(shown.y - _screen.size.y, 0.0, 1.0 / k + 0.001, "Llena el alto con %d px" % window[0])
	assert_eq(_sub.msaa_3d, WorldViewport.MSAA_HIGH, "Bordes suavizados")
	assert_eq(_view.stretch_shrink, 1)
	assert_eq(_view.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR, "Se estira sin pixelar")


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

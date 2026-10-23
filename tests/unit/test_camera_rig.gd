extends GutTest
## Cámara: escalones de zoom, límites del cuarto y que llega justo a su meta.
## La cámara se prueba fuera del árbol: usa una vista de 360×640 píxeles.

const ROOM: AABB = AABB(Vector3(-3.2, 0.0, -3.2), Vector3(6.2, 2.8, 6.2))
const HOME: Vector3 = Vector3(-0.15, 1.95, -0.15)
const VIEW: Vector2 = Vector2(360.0, 640.0)

var _camera: CameraRig


func before_each() -> void:
	_camera = CameraRig.new()
	_camera.configure(ROOM, HOME, 6.8, ControlsTuning.new())


func after_each() -> void:
	_camera.free()


func test_starts_at_normal_zoom() -> void:
	assert_eq(_camera.zoom_index, CameraRig.DEFAULT_ZOOM_INDEX)
	assert_almost_eq(_camera.size, 6.8, 0.0001)


func test_zoom_button_cycles_normal_near_far() -> void:
	_camera.cycle_zoom()
	assert_eq(_camera.zoom_index, 2, "Normal → cerca")
	_camera.cycle_zoom()
	assert_eq(_camera.zoom_index, 0, "Cerca → lejos")
	_camera.cycle_zoom()
	assert_eq(_camera.zoom_index, 1, "Lejos → normal")


func test_zoom_changes_smoothly_and_settles_on_the_step() -> void:
	_camera.set_zoom_index(2)
	_camera.step(0.03)
	assert_between(_camera.zoom, 1.0, 2.0, "A mitad de camino")
	_step(1.0)
	assert_eq(_camera.zoom, 2.0)
	assert_almost_eq(_camera.size, 3.4, 0.0001)


func test_far_view_fits_the_whole_room() -> void:
	_camera.set_zoom_index(0)
	_camera.snap_to_goal()
	var visible_width: float = _camera.size
	var room_width: float = RoomShell.SIZE * sqrt(2.0)
	assert_gt(visible_width, room_width, "Con la vista lejana entra todo el cuarto de lado a lado")


func test_pinch_follows_the_fingers_and_snaps_to_the_nearest_step() -> void:
	_camera.begin_pinch()
	_camera.update_pinch(1.8)
	assert_almost_eq(_camera.zoom, 1.8, 0.0001)
	_camera.update_pinch(10.0)
	assert_almost_eq(_camera.zoom, CameraRig.ZOOM_STEPS[2], 0.0001, "No pasa del último escalón")
	_camera.update_pinch(1.8)
	_camera.end_pinch()
	assert_eq(_camera.zoom_index, 2)


func test_far_view_does_not_follow_the_character() -> void:
	_camera.set_zoom_index(0)
	_camera.follow_point = Vector3(2.8, 0.7, 2.8)
	_step(2.0)
	var home_offset: Vector3 = _camera.position + _forward() * CameraRig.DISTANCE - HOME
	assert_lt(_planar(home_offset).length(), 0.1, "El cuarto entero ya se ve: la cámara se queda quieta")


func test_close_view_follows_but_never_shows_empty_space_past_the_room() -> void:
	_camera.set_zoom_index(2)
	_camera.follow_point = Vector3(3.0, 0.7, 3.0)
	_step(3.0)
	var center: Vector3 = _camera.position + _forward() * CameraRig.DISTANCE
	var half_height: float = _camera.size / 2.0 * VIEW.y / VIEW.x
	assert_gt((center - HOME).length(), 0.3, "La cámara se movió hacia el personaje")
	assert_gte(center.dot(_camera.basis.y) - half_height, _room_extent(_camera.basis.y, false) - 0.01, "No se ve vacío debajo del cuarto")
	_camera.follow_point = Vector3(3.0, 0.7, -3.2)
	_step(3.0)
	center = _camera.position + _forward() * CameraRig.DISTANCE
	assert_lte(center.dot(_camera.basis.x) + _camera.size / 2.0, _room_extent(_camera.basis.x, true) + 0.01, "Ni a la derecha")


func test_camera_reaches_its_goal_exactly() -> void:
	_camera.set_zoom_index(2)
	# Un punto que con el zoom cerca se puede encuadrar sin chocar con los
	# bordes del cuarto.
	_camera.follow_point = Vector3(0.2, 1.5, -0.3)
	_step(0.5)
	# Sin ajuste a píxeles: el centro de la vista es justo el punto que la
	# cámara persigue en cada cuadro, sin resto.
	var center: Vector3 = _camera.position + _forward() * CameraRig.DISTANCE
	var target: Vector3 = _camera._target
	for axis: Vector3 in [_camera.basis.x, _camera.basis.y]:
		assert_almost_eq(center.dot(axis), target.dot(axis), 0.00001, "La cámara está justo donde va")
	assert_almost_eq(_camera.meters_per_pixel(), _camera.size / VIEW.x, 0.00001)
	# Y llega a su meta: el punto seguido queda centrado de lado a lado y a la
	# altura de ANCHOR, medida en píxeles de la vista.
	_step(2.0)
	center = _camera.position + _forward() * CameraRig.DISTANCE
	var offset: Vector3 = _camera.follow_point - center
	var below_px: float = (CameraRig.ANCHOR - 0.5) * VIEW.y
	assert_almost_eq(offset.dot(_camera.basis.x), 0.0, 0.00001, "Centrado de lado a lado")
	assert_almost_eq(-offset.dot(_camera.basis.y) / _camera.meters_per_pixel(), below_px, 0.001, "A la altura de ANCHOR")


func test_an_open_panel_lets_the_camera_frame_objects_above_it() -> void:
	var low_object: Vector3 = Vector3(1.0, 0.3, 1.1)
	_camera.follow_point = low_object
	_step(2.0)
	var without_panel: float = (_camera.position + _forward() * CameraRig.DISTANCE).dot(_camera.basis.y)
	_camera.inset_bottom_px = 300.0
	_step(2.0)
	var with_panel: float = (_camera.position + _forward() * CameraRig.DISTANCE).dot(_camera.basis.y)
	assert_lt(with_panel, without_panel, "La cámara baja para que el objeto quede sobre el panel")


## Lo más lejos que llega el cuarto en una dirección de la pantalla.
func _room_extent(axis: Vector3, maximum: bool) -> float:
	var result: float = -INF if maximum else INF
	for i: int in 8:
		var value: float = ROOM.get_endpoint(i).dot(axis)
		result = maxf(result, value) if maximum else minf(result, value)
	return result


func _step(seconds: float) -> void:
	var steps: int = ceili(seconds / 0.05)
	for i: int in steps:
		_camera.step(0.05)


func _forward() -> Vector3:
	return -_camera.basis.z


## Parte de un desplazamiento que se ve en la pantalla (sin la profundidad).
func _planar(offset: Vector3) -> Vector2:
	return Vector2(offset.dot(_camera.basis.x), offset.dot(_camera.basis.y))

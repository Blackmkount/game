extends GutTest
## Toques, joystick flotante y pellizco.

var _tuning: ControlsTuning
var _tracker: TouchTracker


func before_each() -> void:
	_tuning = ControlsTuning.new()
	_tracker = TouchTracker.new(_tuning)
	_tracker.area = Rect2(20.0, 0.0, 680.0, 1280.0)


func test_press_and_release_without_moving_is_a_tap() -> void:
	assert_true(_tracker.press(0, Vector2(300, 600)))
	_tracker.drag(0, Vector2(305, 604))
	assert_eq(_tracker.release(0, Vector2(305, 604)), Vector2(300, 600))
	assert_eq(_tracker.state, TouchTracker.State.IDLE)


func test_a_slow_press_still_counts_as_a_tap() -> void:
	_tracker.press(0, Vector2(300, 600))
	assert_eq(_tracker.release(0, Vector2(300, 600)), Vector2(300, 600), "No hay límite de tiempo para un toque")


func test_moving_past_the_slop_starts_the_joystick_at_the_press_point() -> void:
	_tracker.press(0, Vector2(300, 600))
	_tracker.drag(0, Vector2(340, 600))
	assert_true(_tracker.is_joystick())
	assert_eq(_tracker.joystick_base, Vector2(300, 600))
	assert_null(_tracker.release(0, Vector2(340, 600)), "Un arrastre no es un toque")
	assert_eq(_tracker.joystick_vector(), Vector2.ZERO, "Al soltar se detiene")


func test_joystick_vector_points_where_the_finger_goes() -> void:
	_tracker.press(0, Vector2(300, 600))
	_tracker.drag(0, Vector2(300, 600 - _tuning.joystick_full_speed_px))
	var vector: Vector2 = _tracker.joystick_vector()
	assert_almost_eq(vector.x, 0.0, 0.001)
	assert_almost_eq(vector.y, -1.0, 0.001, "Hacia arriba y a velocidad máxima")


func test_first_step_past_the_deadzone_is_not_a_crawl() -> void:
	_tracker.press(0, Vector2(300, 600))
	_tracker.drag(0, Vector2(330, 600))
	_tracker.drag(0, Vector2(300 + _tuning.joystick_deadzone_px + 1.0, 600))
	assert_gte(_tracker.joystick_vector().length(), _tuning.joystick_min_speed)
	_tracker.drag(0, Vector2(302, 600))
	assert_eq(_tracker.joystick_vector(), Vector2.ZERO, "Con el dedo en el centro se queda quieto")


func test_ring_follows_the_finger_beyond_its_radius() -> void:
	_tracker.press(0, Vector2(300, 600))
	_tracker.drag(0, Vector2(300 + _tuning.joystick_ring_px + 50.0, 600))
	assert_almost_eq(_tracker.joystick_base.x, 350.0, 0.001)
	# Basta con pasar el nuevo centro (350) para cambiar de dirección, sin
	# volver hasta donde se apoyó el dedo (300).
	_tracker.drag(0, Vector2(320, 600))
	assert_lt(_tracker.joystick_vector().x, 0.0)


func test_presses_near_the_side_edges_are_ignored() -> void:
	assert_false(_tracker.press(0, Vector2(5, 600)))
	assert_eq(_tracker.state, TouchTracker.State.IDLE)
	assert_null(_tracker.release(0, Vector2(5, 600)))


func test_two_fingers_moving_apart_start_a_pinch_and_stop_the_joystick() -> void:
	_tracker.press(0, Vector2(300, 600))
	_tracker.drag(0, Vector2(340, 600))
	_tracker.press(1, Vector2(400, 600))
	assert_true(_tracker.is_joystick(), "Un segundo dedo quieto no corta el joystick")
	_tracker.drag(1, Vector2(460, 600))
	assert_true(_tracker.is_pinching())
	assert_almost_eq(_tracker.pinch_ratio, 120.0 / 60.0, 0.001)
	assert_eq(_tracker.joystick_vector(), Vector2.ZERO)


func test_after_a_pinch_nothing_starts_until_all_fingers_lift() -> void:
	_tracker.press(0, Vector2(300, 600))
	_tracker.press(1, Vector2(400, 600))
	_tracker.drag(1, Vector2(460, 600))
	assert_null(_tracker.release(1, Vector2(460, 600)))
	assert_eq(_tracker.state, TouchTracker.State.LOCKED)
	_tracker.drag(0, Vector2(380, 600))
	assert_false(_tracker.is_joystick())
	assert_null(_tracker.release(0, Vector2(380, 600)), "No es un toque")
	assert_eq(_tracker.state, TouchTracker.State.IDLE)


func test_a_third_finger_lifting_does_not_end_the_pinch() -> void:
	_tracker.press(0, Vector2(300, 600))
	_tracker.press(1, Vector2(400, 600))
	_tracker.drag(1, Vector2(450, 600))
	_tracker.press(2, Vector2(200, 900))
	_tracker.release(2, Vector2(200, 900))
	assert_true(_tracker.is_pinching())
	_tracker.drag(1, Vector2(500, 600))
	assert_almost_eq(_tracker.pinch_ratio, 2.0, 0.001, "Los dos dedos siguen haciendo zoom")


func test_a_stray_second_finger_that_lifts_leaves_the_joystick_alone() -> void:
	_tracker.press(0, Vector2(300, 600))
	_tracker.drag(0, Vector2(340, 600))
	_tracker.press(1, Vector2(500, 900))
	_tracker.release(1, Vector2(500, 900))
	_tracker.drag(0, Vector2(360, 600))
	assert_true(_tracker.is_joystick())


func test_a_lost_release_is_recovered_on_the_next_press() -> void:
	_tracker.press(0, Vector2(300, 600))
	_tracker.drag(0, Vector2(360, 600))
	# El sistema se tragó la subida del dedo; vuelve a bajar el mismo dedo.
	_tracker.press(0, Vector2(100, 300))
	assert_eq(_tracker.state, TouchTracker.State.PRESSED)
	assert_eq(_tracker.joystick_vector(), Vector2.ZERO)


func test_cancel_forgets_everything() -> void:
	_tracker.press(0, Vector2(300, 600))
	_tracker.drag(0, Vector2(360, 600))
	_tracker.cancel()
	assert_eq(_tracker.state, TouchTracker.State.IDLE)
	assert_eq(_tracker.joystick_vector(), Vector2.ZERO)
	assert_null(_tracker.release(0, Vector2(360, 600)))


func test_speed_fraction_curve() -> void:
	assert_eq(_tuning.speed_fraction(0.0), 0.0)
	assert_almost_eq(_tuning.speed_fraction(_tuning.joystick_deadzone_px), _tuning.joystick_min_speed, 0.001)
	assert_almost_eq(_tuning.speed_fraction(_tuning.joystick_full_speed_px), 1.0, 0.001)
	assert_almost_eq(_tuning.speed_fraction(500.0), 1.0, 0.001)

extends GutTest
## Movimiento y animación del personaje, sin la escena principal.

const ROOM: Rect2 = Rect2(-3.0, -3.0, 6.0, 6.0)

var _root: Node3D
var _grid: WalkGrid
var _tuning: ControlsTuning
var _controller: CharacterController


func before_each() -> void:
	_root = Node3D.new()
	add_child_autofree(_root)
	_grid = WalkGrid.new(ROOM)
	_grid.add_obstacle(Rect2(-0.5, -0.5, 1.0, 1.0))
	_grid.build()
	_tuning = ControlsTuning.new()
	_controller = CharacterController.new()
	add_child_autofree(_controller)
	var model: Node3D = CharacterModel.build(_root, "Character")
	_controller.setup(model, _grid, Transform3D(Basis.IDENTITY, Vector3(-2.0, 0.0, -2.0)), _tuning)


func test_stick_moves_at_walking_speed_in_its_direction() -> void:
	_controller.stick = Vector2(1.0, 0.0)
	_run(0.5)
	var start_x: float = _controller.floor_position.x
	_run(0.5)
	assert_almost_eq(_controller.floor_position.x - start_x, _tuning.walk_speed * 0.5, 0.05)
	assert_almost_eq(_controller.floor_position.y, -2.0, 0.001)
	assert_almost_eq(_controller.yaw, PI / 2.0, 0.01, "Mira hacia donde camina (+X)")


func test_releasing_the_stick_stops_quickly() -> void:
	_controller.stick = Vector2(0.0, 1.0)
	_run(0.4)
	_controller.stick = Vector2.ZERO
	_run(_tuning.deceleration_time + 0.05)
	assert_eq(_controller.velocity, Vector2.ZERO)


func test_walking_into_furniture_stops_at_its_edge() -> void:
	_controller.floor_position = Vector2(-2.0, 0.0)
	_controller.stick = Vector2(1.0, 0.0)
	_run(3.0)
	assert_true(_grid.is_free(_controller.floor_position))
	assert_lt(_controller.floor_position.x, -0.5)


func test_pushing_against_a_wall_turns_to_it_without_walking_in_place() -> void:
	# De espaldas a la pared de atrás (-Z), empujando hacia ella.
	_controller.floor_position = Vector2(0.0, -2.75)
	_controller.stick = Vector2(0.0, -1.0)
	_run(0.5)
	assert_almost_eq(absf(_controller.yaw), PI, 0.05, "Se gira hacia la pared")
	assert_lt(_controller.velocity.length(), 0.5, "No sigue en pose de caminar")
	assert_almost_eq(_controller.model.get_node("Body").rotation.x, 0.0, 0.05, "Sin inclinarse como si caminara")


func test_a_long_frame_does_not_tunnel_through_anything() -> void:
	_controller.floor_position = Vector2(-2.0, 0.0)
	_controller.stick = Vector2(1.0, 0.0)
	_controller.step(0.2)
	_controller.step(2.0)
	assert_lt(_controller.floor_position.x, -0.5)


func test_long_frames_while_walking_still_arrive() -> void:
	# Un navegador trabado entrega cuadros de medio segundo: el camino se
	# sigue igual, en pasos cortos.
	assert_true(_controller.walk_to(Vector2(2.0, 2.0)))
	for i: int in 8:
		_controller.step(0.5)
		assert_true(_grid.is_free(_controller.floor_position))
	assert_false(_controller.is_following_path())
	assert_lt(_controller.floor_position.distance_to(Vector2(2.0, 2.0)), 0.1)


func test_walk_to_goes_around_furniture_and_arrives() -> void:
	assert_true(_controller.walk_to(Vector2(2.0, 2.0)))
	for i: int in 400:
		_controller.step(1.0 / 60.0)
		assert_true(_grid.is_free(_controller.floor_position), "Nunca se mete en un mueble")
		if not _controller.is_following_path():
			break
	assert_false(_controller.is_following_path(), "Llegó y terminó el camino")
	assert_lt(_controller.floor_position.distance_to(Vector2(2.0, 2.0)), 0.1)


func test_joystick_cancels_walking_alone() -> void:
	_controller.walk_to(Vector2(2.0, 2.0))
	_controller.stick = Vector2(-1.0, 0.0)
	_run(0.1)
	assert_false(_controller.is_following_path())


func test_legs_swing_only_while_walking() -> void:
	var hip: Node3D = _controller.model.get_node("HipL")
	_run(0.5)
	assert_almost_eq(hip.rotation.x, 0.0, 0.001, "Quieto, las piernas no se mueven")
	_controller.stick = Vector2(1.0, 0.0)
	var largest: float = 0.0
	for i: int in 30:
		_controller.step(1.0 / 60.0)
		largest = maxf(largest, absf(hip.rotation.x))
	assert_gt(largest, 0.2)


func test_the_head_turns_at_most_20_degrees_and_the_pupils_do_the_rest() -> void:
	# Quieto mirando hacia +Z, con algo a 50° a su izquierda (hacia +X).
	_controller.look_target = Vector3(-2.0 + sin(deg_to_rad(50.0)), 0.5, -2.0 + cos(deg_to_rad(50.0)))
	_run(CharacterAnimator.GLANCE_DELAY + 1.5)
	var head: Node3D = _controller.model.get_node("Body/Head")
	assert_almost_eq(head.rotation.y, CharacterAnimator.MAX_GLANCE, 0.001, "La cabeza gira hasta 20°")
	var gaze: Vector2 = (_controller.model.get_node("Body/Head/Mesh") as GeometryInstance3D).get_instance_shader_parameter(&"gaze")
	assert_gt(gaze.x, CharacterAnimator.MAX_GAZE * 0.7, "Las pupilas siguen hacia el mismo lado")
	assert_lte(gaze.x, CharacterAnimator.MAX_GAZE + 0.0001)
	_controller.look_target = null
	_run(1.5)
	assert_almost_eq(head.rotation.y, 0.0, 0.01, "Sin nada que mirar, vuelve al frente")


func _run(seconds: float) -> void:
	var steps: int = ceili(seconds * 60.0)
	for i: int in steps:
		_controller.step(1.0 / 60.0)

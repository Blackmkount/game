extends GutTest
## El personaje vivo (biblia de arte §7.7–7.8): las capas de animación de
## CharacterAnimator, sus gestos, sus caras y sus reacciones, sin la escena
## principal.

const ROOM: Rect2 = Rect2(-3.0, -3.0, 6.0, 6.0)
const FRAME: float = 1.0 / 60.0
## Hacia dónde mira la cámara del juego (giro del personaje de frente a ella).
const CAMERA_YAW: float = deg_to_rad(45.0)

var _root: Node3D
var _grid: WalkGrid
var _controller: CharacterController
var _animator: CharacterAnimator


func before_each() -> void:
	_root = Node3D.new()
	add_child_autofree(_root)
	_grid = WalkGrid.new(ROOM)
	_grid.build()
	_controller = _new_controller(Vector3(0.0, 0.0, 0.0))
	_animator = _controller.animator


func test_a_failed_print_puts_the_hands_on_the_head_and_a_worried_face_quickly() -> void:
	var resting: float = _hand(1.0).y
	var printer: Vector3 = Vector3(1.0, 0.5, 1.4)
	_animator.react(CharacterAnimator.Reaction.PRINT_FAILED, printer)
	_run(0.2)
	assert_eq(_animator.expression(), FacePainter.Face.WORRIED, "Preocupado en 0,2 s")
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.HANDS_ON_HEAD)
	for side: float in [-1.0, 1.0]:
		assert_gt(_hand(side).y - resting, 0.4, "Las manos ya van subiendo")
	_run(CharacterGestures.peak_of(CharacterGestures.Gesture.HANDS_ON_HEAD) - 0.2)
	var skull: Vector3 = _node("Body/Head").global_transform * CharacterModel.SKULL_CENTER
	for side: float in [-1.0, 1.0]:
		var hand: Vector3 = _hand(side)
		assert_lt(hand.distance_to(skull), 0.3, "Mano en la cabeza")
		assert_gt(hand.y, skull.y - 0.08, "A la altura de la cabeza")
		assert_gt(hand.x * side, 0.15, "A su lado")
	assert_gt(_node("Body/Head").rotation.y, 0.1, "Mira hacia la impresora que falló (a su izquierda, +X)")
	_run(CharacterFace.WORRIED_TIME)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.NONE, "El gesto termina solo")
	assert_ne(_animator.emotion(), FacePainter.Face.WORRIED, "Y la preocupación también")


func test_a_delivery_on_time_is_a_happy_fist_pump_and_a_late_one_a_scratch() -> void:
	_animator.react(CharacterAnimator.Reaction.DELIVERED)
	_run(CharacterGestures.peak_of(CharacterGestures.Gesture.CHEER))
	assert_eq(_animator.emotion(), FacePainter.Face.HAPPY)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.CHEER)
	assert_gt(_hand(1.0).y, 1.1, "El puño arriba")
	_run(CharacterFace.HAPPY_TIME)
	assert_eq(_animator.emotion(), FacePainter.Face.NEUTRAL, "Feliz 2,6 s")
	_animator.react(CharacterAnimator.Reaction.DELIVERED_LATE)
	_run(0.5)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.SCRATCH_HEAD, "Atrasado: se rasca la cabeza")
	assert_eq(_animator.emotion(), FacePainter.Face.NEUTRAL, "Sin festejo")


func test_a_level_up_jumps_with_squash_and_stretch() -> void:
	var body: Node3D = _node("Body")
	var rest_y: float = body.position.y
	_animator.react(CharacterAnimator.Reaction.LEVEL_UP)
	_run(FRAME)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.JUMP)
	assert_eq(_animator.expression(), FacePainter.Face.SURPRISE, "Primero sorpresa")
	var highest: float = -INF
	var lowest_sole: float = INF
	var squash: float = INF
	var stretch: float = -INF
	for i: int in ceili(CharacterGestures.length_of(CharacterGestures.Gesture.JUMP) / FRAME):
		_run(FRAME)
		highest = maxf(highest, body.position.y - rest_y)
		lowest_sole = minf(lowest_sole, minf(_sole(-1.0).y, _sole(1.0).y))
		squash = minf(squash, body.scale.y)
		stretch = maxf(stretch, body.scale.y)
		if absf(body.position.y - rest_y - highest) < 0.0001 and highest > 0.1:
			assert_gt(minf(_sole(-1.0).y, _sole(1.0).y), 0.1, "En lo alto, los pies en el aire")
	assert_gt(highest, 0.12, "Salta")
	assert_lt(squash, 0.94, "Se aplasta al agacharse y al caer")
	assert_gt(stretch, 1.06, "Se estira al despegar")
	assert_gt(lowest_sole, -0.02, "Nunca mete los pies en el piso")
	assert_eq(_animator.emotion(), FacePainter.Face.HAPPY, "Después feliz")
	_run(CharacterFace.LEVEL_UP_TIME)
	assert_eq(_animator.emotion(), FacePainter.Face.NEUTRAL, "3 s en total")


func test_the_same_seed_blinks_the_same() -> void:
	var other: CharacterController = _new_controller(Vector3(2.0, 0.0, 2.0))
	var third: CharacterController = _new_controller(Vector3(-2.0, 0.0, 2.0))
	# Sin gestos sueltos (algunos cierran los ojos a propósito).
	for controller: CharacterController in [_controller, other, third]:
		controller.animator.panel_open = true
	_animator.reseed(7)
	other.animator.reseed(7)
	third.animator.reseed(8)
	var blinks: Array[int] = []
	var other_blinks: Array[int] = []
	var third_blinks: Array[int] = []
	for frame: int in ceili(20.0 / FRAME):
		_controller.step(FRAME)
		other.step(FRAME)
		third.step(FRAME)
		if _animator.expression() == FacePainter.Face.BLINK:
			blinks.append(frame)
		if other.animator.expression() == FacePainter.Face.BLINK:
			other_blinks.append(frame)
		if third.animator.expression() == FacePainter.Face.BLINK:
			third_blinks.append(frame)
	assert_eq(blinks, other_blinks, "Misma semilla, mismos parpadeos")
	assert_ne(blinks, third_blinks, "Otra semilla, otros")
	var starts: int = 0
	for i: int in blinks.size():
		if i == 0 or blinks[i] != blinks[i - 1] + 1:
			starts += 1
	assert_between(starts, 4, 9, "Cada 2,4 a 5 s en 20 s")
	assert_between(blinks.size(), starts * 6, starts * 9, "Cada parpadeo dura unos 0,12 s")


func test_idle_without_a_target_it_turns_three_quarters_to_the_camera() -> void:
	_controller.camera_yaw = CAMERA_YAW
	_controller.yaw = deg_to_rad(-160.0)
	_run(1.0)
	assert_almost_eq(_controller.yaw, deg_to_rad(-160.0), 0.001, "Antes de 2 s no se gira")
	_run(2.0)
	var from_camera: float = rad_to_deg(absf(wrapf(_controller.yaw - CAMERA_YAW, -PI, PI)))
	assert_lte(from_camera, 20.0, "Mira a 45° ± 20° (hacia la cámara)")
	assert_gt(from_camera, 5.0, "A 3/4, no de frente plano")
	_controller.yaw = deg_to_rad(-160.0)
	_controller.look_target = Vector3(-1.0, 0.5, -1.0)
	_run(3.0)
	assert_almost_eq(_controller.yaw, deg_to_rad(-160.0), 0.001, "Con algo que mirar no se gira")


func test_walking_cancels_a_gesture() -> void:
	_animator.react(CharacterAnimator.Reaction.TAPPED)
	_run(0.4)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.WAVE)
	var waving: float = _hand(1.0).y
	_controller.stick = Vector2(1.0, 0.0)
	_run(0.1)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.NONE, "Caminar lo corta")
	_run(0.2)
	assert_lt(_hand(1.0).y, waving - 0.3, "El brazo vuelve a la caminata")
	assert_false(_animator.play(CharacterGestures.Gesture.CHEER), "Caminando no empieza otro")


func test_the_knee_bends_in_the_step_and_the_feet_stay_on_the_floor() -> void:
	_controller.stick = Vector2(0.0, 1.0)
	_controller.floor_position = Vector2(0.0, -2.5)
	var knee: float = 0.0
	var elbow: float = 0.0
	var lowest: float = INF
	var highest: float = -INF
	for i: int in 60:
		_run(FRAME)
		knee = maxf(knee, _node("HipL/KneeL").rotation.x)
		elbow = minf(elbow, _node("Body/ShoulderL/ElbowL").rotation.x)
		var sole: float = minf(_sole(-1.0).y, _sole(1.0).y)
		if i > 10:
			lowest = minf(lowest, sole)
			highest = maxf(highest, sole)
	assert_gt(knee, 0.4, "La rodilla se dobla en el paso")
	assert_lt(elbow, -0.9, "Codos doblados al trotar")
	assert_almost_eq(lowest, 0.0, 0.01, "El pie de apoyo no se hunde")
	assert_almost_eq(highest, 0.0, 0.01, "Ni flota: el cuerpo baja lo que suben las piernas")


func test_idle_never_moves_the_legs_even_with_breathing_and_fidgets() -> void:
	var hip: Node3D = _node("HipL")
	var fidgets: int = 0
	var breathing: float = 0.0
	for i: int in ceili(30.0 / FRAME):
		_controller.step(FRAME)
		assert_almost_eq(hip.rotation.x, 0.0, 0.001)
		if _animator.current_gesture() != CharacterGestures.Gesture.NONE:
			fidgets += 1
		breathing = maxf(breathing, _node("Body").scale.y)
	assert_gt(fidgets, 0, "Después de 8 s hace gestos sueltos")
	assert_gt(breathing, 1.01, "Respira con el pecho")


func test_freeze_idle_keeps_still_what_is_random() -> void:
	_animator.freeze_idle = true
	var before: Transform3D = _node("Body").transform
	for i: int in ceili(20.0 / FRAME):
		_controller.step(FRAME)
		assert_ne(_animator.expression(), FacePainter.Face.BLINK, "Sin parpadeos")
		assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.NONE, "Sin gestos sueltos")
	assert_true(_node("Body").transform.is_equal_approx(before), "Sin respirar")


func test_the_phone_comes_out_only_for_a_message_when_idle_and_free() -> void:
	var phone: Node3D = _node("Body/ShoulderR/ElbowR/Phone")
	assert_lt(phone.scale.x, 0.01, "Guardado")
	_animator.panel_open = true
	_animator.react(CharacterAnimator.Reaction.OFFER)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.NONE, "Con un panel abierto no lo saca")
	_animator.panel_open = false
	_animator.react(CharacterAnimator.Reaction.OFFER)
	_run(CharacterGestures.peak_of(CharacterGestures.Gesture.PHONE))
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.PHONE)
	assert_almost_eq(phone.scale.x, 1.0, 0.001, "Lo mira")
	var head: Node3D = _node("Body/Head")
	var to_phone: Vector3 = (phone.global_position - head.global_transform * CharacterModel.FACE_AXIS).normalized()
	assert_gt(to_phone.dot(head.global_basis.z), 0.3, "Delante de la cara")
	assert_lt(to_phone.y, -0.2, "Más abajo que los ojos: mira hacia abajo")
	var screen: Vector3 = phone.global_basis.z.normalized()
	assert_gt(screen.dot(-to_phone), 0.8, "La pantalla mira a sus ojos")
	_run(CharacterGestures.length_of(CharacterGestures.Gesture.PHONE))
	assert_lt(phone.scale.x, 0.01, "Lo guarda")
	_controller.stick = Vector2(1.0, 0.0)
	_run(0.2)
	_animator.react(CharacterAnimator.Reaction.OFFER)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.NONE, "Caminando no lo saca")


func test_talking_alternates_two_mouths_eight_times_a_second() -> void:
	_animator.freeze_idle = true
	_animator.talking = true
	var changes: int = 0
	var last: FacePainter.Face = _animator.expression()
	for i: int in 60:
		_run(FRAME)
		var face: FacePainter.Face = _animator.expression()
		assert_true(face in [FacePainter.Face.TALK_A, FacePainter.Face.TALK_B], "Habla")
		if face != last:
			changes += 1
		last = face
	assert_between(changes, 7, 9, "8 cambios por segundo")
	_animator.talking = false
	_run(FRAME)
	assert_eq(_animator.expression(), FacePainter.Face.NEUTRAL)


func test_modeling_near_the_desk_shows_a_focused_face() -> void:
	_animator.freeze_idle = true
	_animator.desk_area = Rect2(0.5, -0.5, 1.0, 1.0)
	_animator.modeling = true
	_run(FRAME)
	assert_eq(_animator.expression(), FacePainter.Face.FOCUSED, "A 0,5 m del escritorio")
	_controller.floor_position = Vector2(-2.5, 0.0)
	_run(FRAME)
	assert_eq(_animator.expression(), FacePainter.Face.NEUTRAL, "Lejos, cara de siempre")


func test_the_hair_and_the_strings_swing_after_a_sudden_stop() -> void:
	var head: GeometryInstance3D = _node("Body/Head/Mesh")
	var body: GeometryInstance3D = _node("Rig/Mesh")
	_controller.floor_position = Vector2(0.0, -2.0)
	_controller.stick = Vector2(0.0, 1.0)
	_run(1.0)
	_controller.stick = Vector2.ZERO
	var hair: float = 0.0
	var strings: float = 0.0
	for i: int in 30:
		_run(FRAME)
		var hair_swing: Vector3 = head.get_instance_shader_parameter(&"swing")
		var string_swing: Vector3 = body.get_instance_shader_parameter(&"swing")
		hair = maxf(hair, absf(hair_swing.x))
		strings = maxf(strings, string_swing.length())
		assert_lte(absf(hair_swing.x), CharacterAnimator.HAIR_MAX + 0.0001, "El pelo se mueve 6° como mucho")
		assert_eq(_node("Body/Head/Outline").get_instance_shader_parameter(&"swing"), hair_swing, "El contorno lo sigue")
	assert_gt(hair, 0.02, "El pelo se va hacia adelante al frenar")
	assert_gt(strings, 0.004, "Los cordones también")
	_run(3.0)
	var rest: Vector3 = head.get_instance_shader_parameter(&"swing")
	assert_lt(rest.length(), 0.003, "Y se asientan")


func test_hold_freezes_a_gesture_at_its_peak_for_the_screenshots() -> void:
	_animator.hold(CharacterGestures.Gesture.HANDS_ON_HEAD, FacePainter.Face.WORRIED)
	_run(FRAME)
	var pose: Vector3 = _hand(1.0)
	_run(2.0)
	assert_true(_hand(1.0).is_equal_approx(pose), "Quieto en su punto alto")
	assert_eq(_animator.expression(), FacePainter.Face.WORRIED)
	_animator.release()
	_run(0.5)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.NONE)
	assert_eq(_animator.emotion(), FacePainter.Face.NEUTRAL)


func test_the_arm_reaches_where_a_gesture_puts_the_hand() -> void:
	var targets: Array[Vector3] = [Vector3(0.235, 1.16, 0.05), Vector3(0.18, 0.8, 0.24), Vector3(0.03, 1.06, 0.2), Vector3(0.215, 0.56, 0.0)]
	for side: float in [-1.0, 1.0]:
		for target: Vector3 in targets:
			var hand: Vector3 = Vector3(target.x * side, target.y, target.z)
			var pole: Vector3 = Vector3(side, -0.5, 0.2)
			var arm: Array[Quaternion] = CharacterGestures.solve_arm(side, hand, pole)
			assert_almost_eq(CharacterGestures.hand_position(side, arm[0], arm[1]).distance_to(hand), 0.0, 0.001, "La mano llega a %s" % hand)
			var elbow: Vector3 = arm[1].get_euler()
			assert_lte(elbow.x, 0.03, "El codo se dobla hacia adelante")
			assert_almost_eq(elbow.y, 0.0, 0.001, "El codo es una bisagra")
	var far: Vector3 = Vector3(0.3, 1.6, 0.0)
	var stretched: Array[Quaternion] = CharacterGestures.solve_arm(1.0, far, Vector3.RIGHT)
	var reached: Vector3 = CharacterGestures.hand_position(1.0, stretched[0], stretched[1])
	var shoulder: Vector3 = CharacterModel.model_rest(CharacterModel.Bone.SHOULDER_R).origin
	assert_gt((reached - shoulder).normalized().dot((far - shoulder).normalized()), 0.999, "Si no alcanza, se estira hacia el punto")


func test_every_gesture_is_well_formed() -> void:
	var known: Array[String] = ["hand_l", "hand_r", "phone_at"]
	known.append_array(CharacterGestures.BONE_NAMES)
	known.append_array(CharacterGestures.VECTOR_NAMES)
	assert_eq(CharacterGestures.BONE_NAMES.size(), CharacterModel.Bone.size(), "Un canal por hueso")
	for gesture: int in range(1, CharacterGestures.Gesture.size()):
		var data: Dictionary = CharacterGestures.DATA[gesture]
		var keys: Array = data["keys"]
		var label: String = CharacterGestures.Gesture.keys()[gesture]
		assert_eq(keys[0][0], 0.0, label + " empieza en 0")
		assert_almost_eq(float(keys[keys.size() - 1][0]), float(data["length"]), 0.0001, label + " termina en su largo")
		assert_true((keys[0][1] as Dictionary).is_empty() and (keys[keys.size() - 1][1] as Dictionary).is_empty(), label + " sale y vuelve a la pose suelta")
		assert_between(float(data["peak"]), 0.0, float(data["length"]), label)
		for k: int in keys.size():
			if k > 0:
				assert_gt(float(keys[k][0]), float(keys[k - 1][0]), label + ": tiempos en orden")
			for channel: String in keys[k][1]:
				assert_has(known, channel, label + ": canal conocido")
		assert_false(CharacterGestures.drives(gesture as CharacterGestures.Gesture, CharacterModel.Bone.HIP_L) and gesture != CharacterGestures.Gesture.JUMP,
			label + ": solo el salto mueve las piernas")
	for fidget: CharacterGestures.Gesture in CharacterAnimator.FIDGETS:
		assert_false(CharacterGestures.drives(fidget, CharacterModel.Bone.HIP_L), "Los gestos sueltos no mueven las piernas")


func _new_controller(at: Vector3) -> CharacterController:
	var controller: CharacterController = CharacterController.new()
	add_child_autofree(controller)
	var model: Node3D = CharacterModel.build(_root, "Character")
	controller.setup(model, _grid, Transform3D(Basis.IDENTITY, at), ControlsTuning.new())
	return controller


func _node(path: String) -> Node3D:
	return _controller.model.get_node(path)


## Centro de la mano de ese lado (-1 izquierda, 1 derecha), en el mundo.
func _hand(side: float) -> Vector3:
	var elbow: Node3D = _node("Body/ShoulderL/ElbowL" if side < 0.0 else "Body/ShoulderR/ElbowR")
	return elbow.global_transform * (CharacterModel.HAND + Vector3(0.0, CharacterModel.ELBOW_DROP, 0.0))


## Planta del pie de ese lado, en el mundo.
func _sole(side: float) -> Vector3:
	var knee: Node3D = _node("HipL/KneeL" if side < 0.0 else "HipR/KneeR")
	return knee.global_transform * Vector3(0.0, -CharacterModel.SHIN, 0.0)


func _run(seconds: float) -> void:
	var steps: int = maxi(1, roundi(seconds / FRAME))
	for i: int in steps:
		_controller.step(FRAME)

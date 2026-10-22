class_name CharacterController
extends Node
## Mueve y anima al personaje: con el joystick (o el teclado) o caminando solo
## hasta un punto por el camino más corto.
##
## Es solo presentación: la simulación no sabe dónde está el personaje y nunca
## lo espera.

## Tiempo máximo de cada paso de cálculo: si el navegador se traba un cuadro,
## el movimiento se reparte en pasos cortos y no atraviesa nada.
const MAX_STEP_TIME: float = 1.0 / 30.0
const WAYPOINT_RADIUS: float = 0.06
## Segundos sin avanzar por un camino antes de rendirse.
const STUCK_TIME: float = 0.5
## Segundos quieto antes de mirar lo que tiene cerca.
const GLANCE_DELAY: float = 1.5
## La cabeza gira como mucho MAX_GLANCE hacia lo que mira (más, y la cámara
## alta deja de verle la cara); las pupilas siguen GAZE_REACH más allá,
## hasta correrse MAX_GAZE (fracción del ancho de la cara, biblia de arte
## §7.5).
const MAX_GLANCE: float = deg_to_rad(20.0)
const GAZE_REACH: float = deg_to_rad(35.0)
const MAX_GAZE: float = 0.03
## Lo que tiene que cambiar la mirada para avisarle a la cara.
const GAZE_STEP: float = 0.0005
## Animación al caminar, a velocidad máxima.
const LEG_SWING: float = 0.55
const ARM_SWING: float = 0.45
const STEP_BOB: float = 0.035
const LEAN: float = 0.12
const BREATH: float = 0.012

var tuning: ControlsTuning
var grid: WalkGrid
var model: Node3D
## Posición en el piso (x, z) y orientación (radianes; 0 mira hacia +Z).
var floor_position: Vector2 = Vector2.ZERO
var yaw: float = 0.0
var velocity: Vector2 = Vector2.ZERO
## Dirección pedida por el joystick o el teclado en el piso, con largo de 0
## a 1 (fracción de la velocidad máxima). Anula cualquier camino en curso.
var stick: Vector2 = Vector2.ZERO
## Punto que mira cuando está quieto (por ejemplo, el objeto resaltado).
var look_target: Variant = null
## Metros caminados desde el inicio (lo usa la pista de "arrastra para caminar").
var distance_walked: float = 0.0

var _path: PackedVector2Array = PackedVector2Array()
var _path_index: int = 0
var _stuck_time: float = 0.0
var _idle_time: float = 0.0
var _time: float = 0.0
var _face_goal: Variant = null

var _body: Node3D
var _head: Node3D
## La malla de la cabeza (sus pupilas) y hacia dónde mira, suavizado.
var _face: GeometryInstance3D
var _look: float = 0.0
var _gaze: float = 0.0
var _hips: Array[Node3D] = []
var _shoulders: Array[Node3D] = []
var _body_base_y: float = 0.0


func setup(p_model: Node3D, p_grid: WalkGrid, start: Transform3D, p_tuning: ControlsTuning = null) -> void:
	model = p_model
	grid = p_grid
	tuning = p_tuning if p_tuning != null else ControlsTuning.current
	_body = model.get_node("Body")
	_head = _body.get_node("Head")
	_face = _head.get_node("Mesh")
	_hips = [model.get_node("HipL"), model.get_node("HipR")]
	_shoulders = [_body.get_node("ShoulderL"), _body.get_node("ShoulderR")]
	_body_base_y = _body.position.y
	floor_position = grid.resolve(Vector2(start.origin.x, start.origin.z))
	yaw = start.basis.get_euler().y
	_apply_to_model(0.0)


## Camina solo hasta `point`. Devuelve false si no hay camino.
func walk_to(point: Vector2) -> bool:
	var path: PackedVector2Array = grid.find_path(floor_position, point)
	if path.is_empty():
		return false
	_face_goal = null
	_path = path
	_path_index = 0
	_stuck_time = 0.0
	return true


func is_following_path() -> bool:
	return not _path.is_empty()


## Punto adonde termina el camino actual (o donde está, si no camina solo).
func path_end() -> Vector2:
	return _path[_path.size() - 1] if not _path.is_empty() else floor_position


## Deja de caminar por el camino (el joystick sigue funcionando).
func stop_path() -> void:
	_path = PackedVector2Array()
	_path_index = 0
	_stuck_time = 0.0


## Gira para mirar un punto del piso.
func face(point: Vector2) -> void:
	_face_goal = point


## Avanza `delta` segundos. Lo llama RoomView.step() en cada cuadro.
func step(delta: float) -> void:
	var remaining: float = delta
	while remaining > 0.0:
		var dt: float = minf(remaining, MAX_STEP_TIME)
		_step_once(dt)
		remaining -= dt
	_apply_to_model(delta)


func _step_once(dt: float) -> void:
	_time += dt
	var desired: Vector2 = Vector2.ZERO
	if stick.length_squared() > 0.0001:
		stop_path()
		_face_goal = null
		desired = stick.limit_length(1.0) * tuning.walk_speed
	elif not _path.is_empty():
		desired = _path_velocity()
	var speeding_up: bool = desired.length() > velocity.length()
	var ramp_time: float = tuning.acceleration_time if speeding_up else tuning.deceleration_time
	velocity = velocity.move_toward(desired, tuning.walk_speed / maxf(ramp_time, 0.001) * dt)

	var before: Vector2 = floor_position
	floor_position = grid.move(floor_position, velocity * dt)
	var moved: Vector2 = floor_position - before
	distance_walked += moved.length()
	# Contra una pared la velocidad es la que de verdad avanzó: así no queda en
	# pose de caminar ni la cámara se adelanta a un personaje quieto.
	if dt > 0.0 and moved.length() < (velocity * dt).length() - 0.0001:
		velocity = moved / dt
	if not desired.is_zero_approx() and stick.length_squared() > 0.0001:
		# Con el joystick mira hacia donde se empuja, aunque esté bloqueado.
		_turn_toward(desired, dt)
	elif moved.length() > 0.0005:
		_turn_toward(moved, dt)
	if moved.length() > 0.0005:
		_idle_time = 0.0
	else:
		_idle_time += dt
		if _face_goal != null:
			var to_goal: Vector2 = (_face_goal as Vector2) - floor_position
			if to_goal.length() > 0.01:
				_turn_toward(to_goal, dt)
	_follow_path(moved.length(), dt)


func _path_velocity() -> Vector2:
	var waypoint: Vector2 = _path[_path_index]
	var to_point: Vector2 = waypoint - floor_position
	var distance: float = to_point.length()
	var speed: float = tuning.walk_speed
	if _path_index == _path.size() - 1:
		# Frena suave al llegar.
		speed = minf(speed, distance / maxf(tuning.deceleration_time * 2.0, 0.05) + 0.3)
	return to_point / maxf(distance, 0.0001) * speed


func _follow_path(moved: float, dt: float) -> void:
	if _path.is_empty():
		return
	if floor_position.distance_to(_path[_path_index]) <= WAYPOINT_RADIUS:
		_path_index += 1
		_stuck_time = 0.0
		if _path_index >= _path.size():
			stop_path()
		return
	if moved < 0.0005:
		_stuck_time += dt
		if _stuck_time > STUCK_TIME:
			stop_path()
	else:
		_stuck_time = 0.0


func _turn_toward(direction: Vector2, dt: float) -> void:
	var goal: float = atan2(direction.x, direction.y)
	var difference: float = wrapf(goal - yaw, -PI, PI)
	var max_turn: float = deg_to_rad(tuning.turn_speed_degrees) * dt
	if absf(difference) > deg_to_rad(150.0) or absf(difference) <= max_turn:
		yaw = goal
	else:
		yaw += signf(difference) * max_turn
	yaw = wrapf(yaw, -PI, PI)


func _apply_to_model(delta: float) -> void:
	model.position = Vector3(floor_position.x, 0.0, floor_position.y)
	model.rotation.y = yaw
	var speed_ratio: float = clampf(velocity.length() / maxf(tuning.walk_speed, 0.001), 0.0, 1.0)
	# El paso depende de la distancia recorrida, no del tiempo: los pies no
	# se deslizan cuando camina despacio.
	var phase: float = distance_walked / maxf(tuning.stride_length, 0.01) * TAU
	var swing: float = sin(phase) * speed_ratio
	_hips[0].rotation.x = swing * LEG_SWING
	_hips[1].rotation.x = -swing * LEG_SWING
	_shoulders[0].rotation.x = -swing * ARM_SWING
	_shoulders[1].rotation.x = swing * ARM_SWING
	var bob: float = absf(sin(phase)) * STEP_BOB * speed_ratio
	var breath: float = sin(_time * 2.6) * BREATH * (1.0 - speed_ratio)
	_body.position.y = _body_base_y + bob + breath
	_body.rotation.x = LEAN * speed_ratio
	var look: float = 0.0
	if _idle_time > GLANCE_DELAY and look_target != null:
		var target: Vector3 = look_target
		var local_angle: float = wrapf(atan2(target.x - floor_position.x, target.z - floor_position.y) - yaw, -PI, PI)
		look = clampf(local_angle, -MAX_GLANCE - GAZE_REACH, MAX_GLANCE + GAZE_REACH)
	_look = lerpf(_look, look, 1.0 - exp(-6.0 * delta))
	_head.rotation.y = clampf(_look, -MAX_GLANCE, MAX_GLANCE)
	var gaze: float = (_look - _head.rotation.y) / GAZE_REACH * MAX_GAZE
	if absf(gaze - _gaze) > GAZE_STEP:
		_gaze = gaze
		_face.set_instance_shader_parameter(&"gaze", Vector2(_gaze, 0.0))

class_name CharacterController
extends Node
## Mueve al personaje: con el joystick (o el teclado) o caminando solo hasta
## un punto por el camino más corto. Quieto y sin nada que mirar, después de
## IDLE_TURN_DELAY segundos se gira a 3/4 hacia la cámara (así se le ve la
## cara). Lo anima su CharacterAnimator, que avanza justo después de moverlo.
##
## Es solo presentación: la simulación no sabe dónde está el personaje y nunca
## lo espera.

## Tiempo máximo de cada paso de cálculo: si el navegador se traba un cuadro,
## el movimiento se reparte en pasos cortos y no atraviesa nada.
const MAX_STEP_TIME: float = 1.0 / 30.0
const WAYPOINT_RADIUS: float = 0.06
## Segundos sin avanzar por un camino antes de rendirse.
const STUCK_TIME: float = 0.5
## Quieto sin objetivo: segundos antes de girarse hacia la cámara, cuánto se
## queda de lado (3/4: la cara se lee hasta unos 30°) y a qué velocidad gira
## (grados por segundo).
const IDLE_TURN_DELAY: float = 2.0
const IDLE_TURN_ANGLE: float = deg_to_rad(15.0)
const IDLE_TURN_SPEED: float = 160.0

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
## Hacia dónde mira la cámara (su giro, en radianes, el mismo que tendría el
## personaje mirándola de frente). NAN: no se gira hacia ella.
var camera_yaw: float = NAN
## Escribe la pose del personaje (lo arma setup()).
var animator: CharacterAnimator

var _path: PackedVector2Array = PackedVector2Array()
var _path_index: int = 0
var _stuck_time: float = 0.0
var _idle_time: float = 0.0
var _face_goal: Variant = null


func setup(p_model: Node3D, p_grid: WalkGrid, start: Transform3D, p_tuning: ControlsTuning = null) -> void:
	model = p_model
	grid = p_grid
	tuning = p_tuning if p_tuning != null else ControlsTuning.current
	floor_position = grid.resolve(Vector2(start.origin.x, start.origin.z))
	yaw = start.basis.get_euler().y
	_place_model()
	animator = CharacterAnimator.new(self)
	animator.step(0.0)


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


## Gira para mirar a la cámara de frente (por ejemplo, para saludar).
func face_camera() -> void:
	if not is_nan(camera_yaw):
		face(floor_position + Vector2(sin(camera_yaw), cos(camera_yaw)))


## Segundos que lleva quieto y sin que lo empujen con el joystick.
func idle_time() -> float:
	return _idle_time


## Avanza `delta` segundos: lo mueve y después lo anima. Lo llama
## RoomView.step() en cada cuadro.
func step(delta: float) -> void:
	var remaining: float = delta
	while remaining > 0.0:
		var dt: float = minf(remaining, MAX_STEP_TIME)
		_step_once(dt)
		remaining -= dt
	_place_model()
	animator.step(delta)


func _step_once(dt: float) -> void:
	var desired: Vector2 = Vector2.ZERO
	var pushing: bool = stick.length_squared() > 0.0001
	if pushing:
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
	if pushing:
		# Con el joystick mira hacia donde se empuja, aunque esté bloqueado.
		_turn_toward(desired, dt)
	elif moved.length() > 0.0005:
		_turn_toward(moved, dt)
	# Empujar contra una pared no es estar quieto: ni se gira hacia la cámara
	# ni hace gestos sueltos.
	if pushing or moved.length() > 0.0005:
		_idle_time = 0.0
	else:
		_idle_time += dt
		if _face_goal != null:
			var to_goal: Vector2 = (_face_goal as Vector2) - floor_position
			if to_goal.length() > 0.01:
				_turn_toward(to_goal, dt)
		elif look_target == null and _idle_time > IDLE_TURN_DELAY and not is_nan(camera_yaw):
			_turn_to_camera(dt)
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


## Gira despacio hasta quedar a 3/4 de la cámara, del lado hacia donde ya
## mira.
func _turn_to_camera(dt: float) -> void:
	var side: float = 1.0 if wrapf(yaw - camera_yaw, -PI, PI) >= 0.0 else -1.0
	var difference: float = wrapf(camera_yaw + IDLE_TURN_ANGLE * side - yaw, -PI, PI)
	var max_turn: float = deg_to_rad(IDLE_TURN_SPEED) * dt
	yaw = wrapf(yaw + clampf(difference, -max_turn, max_turn), -PI, PI)


func _place_model() -> void:
	model.position = Vector3(floor_position.x, 0.0, floor_position.y)
	model.rotation.y = yaw

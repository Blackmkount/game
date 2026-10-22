class_name CharacterAnimator
extends RefCounted
## La animación del personaje por capas (biblia de arte §7.7–7.8). Es el
## ÚNICO que escribe los giros, lugares y escalas de los pivotes de
## CharacterModel. CharacterController lo avanza justo después de moverlo, y
## RoomView copia después la pose a los huesos (controlador → animador →
## CharacterRig.follow).
##
## Las capas, de abajo hacia arriba:
## 1. Locomoción: a 2,2 m/s es un trote suave. Piernas con rodillas que se
##    doblan en el paso, codos doblados, balanceo de cadera, giro de hombros
##    contra las piernas, inclinación con un resorte (se asienta al frenar en
##    seco) y un anticipo al arrancar (se aplasta). Los pies se apoyan solos: el cuerpo
##    baja lo que suben las piernas abiertas o dobladas (el rebote del paso).
##    Al girar en el lugar levanta los pies por turnos.
## 2. Quieto: respira (escala del pecho), cambia el peso (solo Body: las
##    piernas no se mueven), mira lo que tiene cerca (la cabeza gira hasta
##    20° y las pupilas siguen) y, después de FIDGET_DELAY segundos, hace
##    gestos sueltos al azar (el celular, estirarse, rascarse la cabeza, mirar
##    la impresora; de noche, bostezar).
## 3. Gestos (CharacterGestures): de una vez, con mezcla al entrar y salir;
##    se cortan al caminar y nunca bloquean nada.
## 4. Expresiones (CharacterFace): parpadeo, emociones con su tiempo, hablar
##    mientras se ve el globo, concentrado al modelar cerca del escritorio.
## 5. Movimiento secundario: resortes en el pelo, los cordones y la capucha
##    (los mueven los sombreadores, ver kit_body.gdshaderinc).
## 6. Estirar y aplastar con la escala de Body (saltar, aterrizar, arrancar).
##
## Las reacciones (react) son siempre cosméticas: la simulación nunca las
## espera. Todo usa arreglos reservados al armarse: sin memoria nueva por
## cuadro. El azar tiene su propia semilla (reseed) y freeze_idle deja quieto
## lo que es al azar o de adorno, para las capturas.

## Lo que le pasa al personaje (biblia §7.8).
enum Reaction { DELIVERED, DELIVERED_LATE, PRINT_FAILED, LEVEL_UP, OFFER, PRINTER_READY, TAPPED, ACTION_FAILED, PACKED }

## Locomoción, a la velocidad máxima (todo se escala con la velocidad):
## piernas, rodilla de apoyo y en el aire (con su adelanto en la fase: se
## dobla al despegar el pie de atrás), brazos, codos (y cuánto más se doblan
## adelante), balanceo de cadera, giro de hombros e inclinación.
const LEG_SWING: float = 0.4
const KNEE_STANCE: float = 0.12
const KNEE_SWING: float = 0.9
const KNEE_LEAD: float = 0.4
const ARM_SWING: float = 0.5
const ELBOW_RUN: float = -1.1
const ELBOW_PUMP: float = 0.15
const HIP_SWAY: float = 0.05
const SHOULDER_TWIST: float = 0.08
const LEAN: float = 0.12
## Resorte de la inclinación (rigidez, amortiguación) y su empujón al frenar
## en seco (rad/s): el cuerpo se va un poco hacia adelante y se asienta.
const LEAN_SPRING: Vector2 = Vector2(260.0, 20.0)
const STOP_PITCH: float = 1.4
## Anticipo al arrancar: se aplasta un poco durante KICK_TIME.
const KICK_TIME: float = 0.1
const KICK_SQUASH: float = 0.04
## Velocidades (fracción de la máxima): arrancó, frenó, venía corriendo y
## "camina" (corta los gestos y no deja empezar otros).
const STARTED: float = 0.25
const STOPPED: float = 0.05
const RUNNING: float = 0.5
const MOVING: float = 0.15
## Al girar en el lugar levanta los pies por turnos: cuánto dobla la rodilla,
## cuánto gira por paso (rad) y la velocidad de giro (rad/s) del paso entero.
const SHUFFLE_KNEE: float = 0.45
const SHUFFLE_STEP: float = 0.6
const SHUFFLE_FULL: float = 3.0
## Quieto: respiración (veces por segundo, escala del pecho y cabeceo), y el
## cambio de peso (rad de Body hacia los lados, veces por segundo).
const BREATH_RATE: float = 0.35
const BREATH_SCALE: Vector3 = Vector3(0.008, 0.015, 0.008)
const BREATH_NOD: float = 0.012
const WEIGHT_SHIFT: float = 0.022
const WEIGHT_RATE: float = 0.11
## Mirada (biblia §7.5): segundos quieto antes de mirar lo que tiene cerca; la
## cabeza gira como mucho MAX_GLANCE (más, y la cámara alta deja de verle la
## cara); las pupilas siguen GAZE_REACH más allá, hasta correrse MAX_GAZE
## (fracción del ancho de la cara). Lo que tiene que cambiar la mirada para
## avisarle a la cara, y qué tan rápido la sigue.
const GLANCE_DELAY: float = 1.5
const MAX_GLANCE: float = deg_to_rad(20.0)
const GAZE_REACH: float = deg_to_rad(35.0)
const MAX_GAZE: float = 0.03
const GAZE_STEP: float = 0.0005
const LOOK_RATE: float = 6.0
## Gestos sueltos (biblia §7.7.2): segundos quieto antes del primero, lo más
## que se espera además para el primero y entre uno y otro. Cuáles hay, hasta
## dónde busca una impresora que mirar (m), y la noche (horas) en que bosteza
## (una vez por hora de juego).
const FIDGET_DELAY: float = 8.0
const FIDGET_FIRST: float = 2.0
const FIDGET_GAP: Vector2 = Vector2(6.0, 12.0)
const FIDGETS: Array[CharacterGestures.Gesture] = [
	CharacterGestures.Gesture.PHONE, CharacterGestures.Gesture.STRETCH,
	CharacterGestures.Gesture.SCRATCH_HEAD, CharacterGestures.Gesture.WATCH,
]
const WATCH_RANGE: float = 2.5
const NIGHT: Vector2 = Vector2(22.0, 5.0)
## Las reacciones a algo cercano (biblia §7.8) son a esta distancia o menos.
const NEAR: float = 1.2
## Segundos que mira la impresora que terminó.
const LOOK_READY: float = 1.5
## Mezcla al cortar o cambiar un gesto (s).
const CUT_BLEND: float = 0.12
## Movimiento secundario: resortes (rigidez, amortiguación) del pelo y de
## los cordones; cuánto los empuja la aceleración (rad o m por m/s²) y el giro
## (rad por rad/s); cuánto cuelgan los cordones al inclinarse (m por rad) y lo
## más que se mueven (biblia: el pelo ≤ 6°).
const HAIR_SPRING: Vector2 = Vector2(110.0, 7.0)
const HAIR_PUSH: Vector2 = Vector2(0.003, 0.006)
const HAIR_MAX: float = deg_to_rad(6.0)
const STRING_SPRING: Vector2 = Vector2(150.0, 8.0)
const STRING_PUSH: float = 0.0008
const STRING_LEAN: float = 0.08
const STRING_MAX: float = 0.025
const SWING_STEP: float = 0.0003
## Paso de los resortes (s), y los topes de lo que los empuja (m/s², rad/s).
const SPRING_STEP: float = 1.0 / 60.0
const MAX_ACCEL: float = 40.0
const MAX_TURN_RATE: float = 12.0

const BONES: int = CharacterGestures.BONES
const MOVE: int = CharacterGestures.MOVE
const SHAPE: int = CharacterGestures.SHAPE
const EYES: int = CharacterGestures.EYES

## Lo pone WorldControls en cada cuadro: si se ve el globo de diálogo y si
## hay un panel o una pantalla abierta (entonces no saca el celular ni hace
## gestos sueltos).
var talking: bool = false
var panel_open: bool = false
## Lo pone RoomView: si el computador está modelando, dónde está el
## escritorio (para la cara concentrada de cerca), los cabezales de las
## impresoras (para mirarlos) y la hora del juego (para bostezar de noche).
var modeling: bool = false
var desk_area: Rect2 = Rect2()
var watch_points: Array[Node3D] = []
var game_minutes: float = 0.0
## Para las capturas: sin respiración, cambio de peso, parpadeos ni gestos
## sueltos (todo lo demás sigue igual).
var freeze_idle: bool = false:
	set(value):
		freeze_idle = value
		_face.freeze_blinks = value
## Para las capturas: el tiempo del personaje no avanza (mientras el
## ejecutor espera en tiempo real que se vayan los avisos, la pose no cambia
## según lo rápido que dibuje la máquina).
var paused: bool = false

var _controller: CharacterController
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _face: CharacterFace = CharacterFace.new()
var _pivots: Array[Node3D] = []
var _rest_euler: PackedVector3Array = PackedVector3Array()
var _rest_position: PackedVector3Array = PackedVector3Array()
var _head_mesh: GeometryInstance3D
var _head_outline: GeometryInstance3D
var _body_mesh: GeometryInstance3D
var _body_outline: GeometryInstance3D
## La pose de este cuadro (giro de cada hueso respecto de su padre, y los
## vectores MOVE, SHAPE y EYES), la del gesto, la que se escribió en el
## cuadro anterior y desde la que se mezcla al cortar un gesto.
var _rot: Array[Quaternion] = []
var _vec: Array[Vector3] = []
var _gesture_rot: Array[Quaternion] = []
var _gesture_vec: Array[Vector3] = []
var _out_rot: Array[Quaternion] = []
var _out_vec: Array[Vector3] = []
var _from_rot: Array[Quaternion] = []
var _from_vec: Array[Vector3] = []
var _cut_weight: float = 0.0

var _clock: float = 0.0
var _speed: float = 0.0
var _phase: float = 0.0
var _last_yaw: float = 0.0
var _turn_rate: float = 0.0
var _last_velocity: Vector3 = Vector3.ZERO
## Aceleración en el espacio del personaje (+Z adelante).
var _accel: Vector3 = Vector3.ZERO
## Lo que sube o baja el cuerpo (m), en este cuadro y en el anterior, y su
## velocidad (m/s).
var _lift: float = 0.0
var _last_lift: float = 0.0
var _lift_speed: float = 0.0
var _lean: float = 0.0
var _lean_speed: float = 0.0
var _kick: float = 0.0
var _shuffle: float = 0.0
var _shuffle_phase: float = 0.0
var _breath: float = 0.0

var _gesture: CharacterGestures.Gesture = CharacterGestures.Gesture.NONE
var _gesture_time: float = 0.0
var _held: bool = false
var _fidget_armed: bool = false
var _fidget_wait: float = 0.0
var _last_fidget: CharacterGestures.Gesture = CharacterGestures.Gesture.NONE
var _yawn_hour: int = -1
var _watch_point: Vector3 = Vector3.ZERO

var _look_point: Vector3 = Vector3.ZERO
var _look_left: float = 0.0
var _look_angle: float = 0.0
var _gaze: Vector2 = Vector2.ZERO
var _shown_gaze: Vector2 = Vector2.ZERO
var _shown_face: FacePainter.Face = FacePainter.Face.NEUTRAL

var _hair: Vector3 = Vector3.ZERO
var _hair_speed: Vector3 = Vector3.ZERO
var _strings: Vector3 = Vector3.ZERO
var _strings_speed: Vector3 = Vector3.ZERO
var _shown_hair: Vector3 = Vector3.ZERO
var _shown_strings: Vector3 = Vector3.ZERO


func _init(controller: CharacterController) -> void:
	_controller = controller
	var model: Node3D = controller.model
	for bone: int in BONES:
		var rest: Transform3D = CharacterModel.local_rest(bone as CharacterModel.Bone)
		_pivots.append(model.get_node(CharacterModel.PIVOT_PATHS[bone]))
		_rest_euler.append(rest.basis.get_euler())
		_rest_position.append(rest.origin)
	_head_mesh = model.get_node("Body/Head/Mesh")
	_head_outline = model.get_node("Body/Head/Outline")
	_body_mesh = model.get_node("Rig/Mesh")
	_body_outline = model.get_node("Rig/Outline")
	for buffer: Array[Quaternion] in [_rot, _gesture_rot, _out_rot, _from_rot]:
		buffer.resize(BONES)
		buffer.fill(Quaternion.IDENTITY)
	for buffer: Array[Vector3] in [_vec, _gesture_vec, _out_vec, _from_vec]:
		buffer.resize(CharacterGestures.VECTORS)
		buffer.fill(Vector3.ZERO)
	_last_yaw = controller.yaw
	reseed(0)


## Empieza el azar (gestos sueltos y parpadeos) de nuevo con esa semilla.
func reseed(seed_value: int) -> void:
	_rng.seed = seed_value
	_face.reseed(_rng.randi())
	_fidget_armed = false


## Partida nueva o cargada: sin gestos, emociones ni miradas pendientes.
func reset() -> void:
	_gesture = CharacterGestures.Gesture.NONE
	_held = false
	_cut_weight = 0.0
	_look_left = 0.0
	_fidget_armed = false
	_yawn_hour = -1
	_face.clear()


## Avanza `delta` segundos y escribe la pose en los pivotes y la cara en la
## cabeza. Lo llama CharacterController.step() después de moverse.
func step(delta: float) -> void:
	var dt: float = 0.0 if _held or paused else delta
	_clock += dt
	_read_motion(delta, dt)
	_update_gesture(dt)
	_update_fidgets(dt)
	_base_pose()
	_gesture_pose()
	_look(dt)
	_blend_cut(dt)
	_write()
	_secondary(dt)
	_update_face(dt)


## Reacciona a algo que pasó (biblia §7.8). `point`: lo que mira (la
## impresora que falló o terminó).
func react(reaction: Reaction, point: Variant = null) -> void:
	match reaction:
		Reaction.DELIVERED:
			_face.show(FacePainter.Face.HAPPY, CharacterFace.HAPPY_TIME)
			play(CharacterGestures.Gesture.CHEER)
		Reaction.DELIVERED_LATE:
			play(CharacterGestures.Gesture.SCRATCH_HEAD)
		Reaction.PRINT_FAILED:
			_face.show(FacePainter.Face.WORRIED, CharacterFace.WORRIED_TIME)
			play(CharacterGestures.Gesture.HANDS_ON_HEAD)
			if point != null:
				look_at(point, CharacterFace.WORRIED_TIME)
		Reaction.LEVEL_UP:
			_face.show(FacePainter.Face.SURPRISE, CharacterFace.SURPRISE_TIME, FacePainter.Face.HAPPY, CharacterFace.LEVEL_UP_TIME - CharacterFace.SURPRISE_TIME)
			play(CharacterGestures.Gesture.JUMP)
		Reaction.OFFER:
			if not panel_open:
				play(CharacterGestures.Gesture.PHONE, false)
		Reaction.PRINTER_READY:
			_face.show(FacePainter.Face.HAPPY, CharacterFace.READY_HAPPY_TIME)
			play(CharacterGestures.Gesture.THUMBS_UP)
			if point != null:
				look_at(point, LOOK_READY)
		Reaction.TAPPED:
			_face.show(FacePainter.Face.HAPPY, CharacterFace.WAVE_HAPPY_TIME)
			play(CharacterGestures.Gesture.WAVE)
		Reaction.ACTION_FAILED:
			play(CharacterGestures.Gesture.SHRUG)
		Reaction.PACKED:
			play(CharacterGestures.Gesture.PACK)


## Empieza un gesto si está quieto. Con `interrupt` reemplaza al que esté
## haciendo (mezclando desde la pose de ahora); sin él, espera su turno (no
## lo hace). Devuelve si empezó.
func play(gesture: CharacterGestures.Gesture, interrupt: bool = true) -> bool:
	if _held or _speed > MOVING:
		return false
	if _gesture != CharacterGestures.Gesture.NONE:
		if not interrupt:
			return false
		_snapshot()
	_gesture = gesture
	_gesture_time = 0.0
	return true


## Mira ese punto por `seconds` segundos (la cabeza hasta 20° y las pupilas),
## aunque haya algo más cerca.
func look_at(point: Vector3, seconds: float) -> void:
	_look_point = point
	_look_left = seconds


## Para las capturas: deja el gesto quieto en su punto alto con esa cara,
## hasta release().
func hold(gesture: CharacterGestures.Gesture, face: FacePainter.Face) -> void:
	_gesture = gesture
	_gesture_time = CharacterGestures.peak_of(gesture)
	_cut_weight = 0.0
	_face.show(face, 1.0)
	_held = true


func release() -> void:
	_held = false
	_gesture = CharacterGestures.Gesture.NONE
	_face.clear()


func current_gesture() -> CharacterGestures.Gesture:
	return _gesture


## Segundos desde que empezó el gesto actual.
func gesture_time() -> float:
	return _gesture_time


## La cara que se ve (FacePainter.Face).
func expression() -> FacePainter.Face:
	return _shown_face


## La emoción del momento (sin parpadeos ni boca de hablar).
func emotion() -> FacePainter.Face:
	return _face.emotion()


# --- Capas ---------------------------------------------------------------------

func _read_motion(delta: float, dt: float) -> void:
	var controller: CharacterController = _controller
	var speed: float = clampf(controller.velocity.length() / maxf(controller.tuning.walk_speed, 0.001), 0.0, 1.0)
	if speed > STARTED and _speed < STOPPED:
		_kick = 1.0
	if speed < STOPPED and _speed > RUNNING:
		_lean_speed += STOP_PITCH
	_speed = speed
	_phase = controller.distance_walked / maxf(controller.tuning.stride_length, 0.01) * TAU
	var turn: float = wrapf(controller.yaw - _last_yaw, -PI, PI)
	_last_yaw = controller.yaw
	var velocity: Vector3 = Vector3(controller.velocity.x, 0.0, controller.velocity.y)
	if delta > 0.0:
		_turn_rate = clampf(turn / delta, -MAX_TURN_RATE, MAX_TURN_RATE)
		var accel: Vector3 = (velocity - _last_velocity) / delta
		_accel = accel.limit_length(MAX_ACCEL).rotated(Vector3.UP, -controller.yaw)
	_last_velocity = velocity
	var turning: float = clampf(absf(_turn_rate) / SHUFFLE_FULL, 0.0, 1.0) if speed < MOVING else 0.0
	_shuffle = move_toward(_shuffle, turning, delta * 6.0)
	if speed < MOVING:
		_shuffle_phase = fmod(_shuffle_phase + absf(turn) / SHUFFLE_STEP * PI, TAU)
	_kick = maxf(_kick - dt / KICK_TIME, 0.0)
	var remaining: float = dt
	while remaining > 0.0:
		var h: float = minf(remaining, SPRING_STEP)
		_lean_speed += (LEAN_SPRING.x * (LEAN * speed - _lean) - LEAN_SPRING.y * _lean_speed) * h
		_lean += _lean_speed * h
		remaining -= h


func _update_gesture(dt: float) -> void:
	if _gesture == CharacterGestures.Gesture.NONE:
		return
	if _speed > MOVING and not _held:
		_snapshot()
		_gesture = CharacterGestures.Gesture.NONE
		return
	_gesture_time += dt
	if _gesture_time >= CharacterGestures.length_of(_gesture):
		_gesture = CharacterGestures.Gesture.NONE


func _update_fidgets(dt: float) -> void:
	var idle: float = _controller.idle_time()
	if idle < FIDGET_DELAY:
		_fidget_armed = false
		return
	if freeze_idle or _held or panel_open or _gesture != CharacterGestures.Gesture.NONE:
		return
	if not _fidget_armed:
		_fidget_armed = true
		_fidget_wait = _rng.randf_range(0.0, FIDGET_FIRST)
	_fidget_wait -= dt
	if _fidget_wait > 0.0:
		return
	var fidget: CharacterGestures.Gesture = _pick_fidget()
	play(fidget, false)
	if fidget == CharacterGestures.Gesture.WATCH:
		look_at(_watch_point, CharacterGestures.length_of(fidget))
	_fidget_wait = _rng.randf_range(FIDGET_GAP.x, FIDGET_GAP.y)


## Un gesto suelto al azar (sin repetir el anterior): de noche, bostezar (una
## vez por hora de juego); mirar la impresora solo si hay una cerca.
func _pick_fidget() -> CharacterGestures.Gesture:
	var hour: float = fmod(game_minutes / 60.0, 24.0)
	var hour_index: int = floori(game_minutes / 60.0)
	if (hour >= NIGHT.x or hour < NIGHT.y) and hour_index != _yawn_hour:
		_yawn_hour = hour_index
		_last_fidget = CharacterGestures.Gesture.YAWN
		return CharacterGestures.Gesture.YAWN
	var can_watch: bool = _find_watch_point()
	var fidget: CharacterGestures.Gesture = CharacterGestures.Gesture.STRETCH
	for attempt: int in FIDGETS.size():
		var candidate: CharacterGestures.Gesture = FIDGETS[_rng.randi_range(0, FIDGETS.size() - 1)]
		if candidate != _last_fidget and (candidate != CharacterGestures.Gesture.WATCH or can_watch):
			fidget = candidate
			break
	_last_fidget = fidget
	return fidget


## El cabezal de impresora más cercano a WATCH_RANGE o menos (en
## _watch_point). Devuelve si hay uno.
func _find_watch_point() -> bool:
	var feet: Vector2 = _controller.floor_position
	var best: float = WATCH_RANGE
	var found: bool = false
	for point: Node3D in watch_points:
		var at: Vector3 = point.global_position
		var distance: float = feet.distance_to(Vector2(at.x, at.z))
		if distance <= best:
			best = distance
			_watch_point = at
			found = true
	return found


## Locomoción y quieto, en `_rot` y `_vec`.
func _base_pose() -> void:
	var speed: float = _speed
	var still: float = 1.0 - speed
	var swing: float = sin(_phase) * speed
	_breath = 0.0
	var shift: float = 0.0
	if not freeze_idle:
		_breath = (0.5 - 0.5 * cos(TAU * BREATH_RATE * _clock)) * still
		shift = sin(TAU * WEIGHT_RATE * _clock) * still
	var knee_l: float = speed * (KNEE_STANCE + KNEE_SWING * pow(maxf(-cos(_phase + KNEE_LEAD), 0.0), 1.5))
	var knee_r: float = speed * (KNEE_STANCE + KNEE_SWING * pow(maxf(cos(_phase + KNEE_LEAD), 0.0), 1.5))
	knee_l += SHUFFLE_KNEE * _shuffle * maxf(sin(_shuffle_phase), 0.0)
	knee_r += SHUFFLE_KNEE * _shuffle * maxf(-sin(_shuffle_phase), 0.0)
	_set_euler(CharacterModel.Bone.HIP_L, Vector3(swing * LEG_SWING, 0.0, 0.0))
	_set_euler(CharacterModel.Bone.HIP_R, Vector3(-swing * LEG_SWING, 0.0, 0.0))
	_set_euler(CharacterModel.Bone.KNEE_L, Vector3(knee_l, 0.0, 0.0))
	_set_euler(CharacterModel.Bone.KNEE_R, Vector3(knee_r, 0.0, 0.0))
	var hang: float = CharacterGestures.ARM_HANG.x * still
	_set_euler(CharacterModel.Bone.SHOULDER_L, Vector3(hang - swing * ARM_SWING, 0.0, 0.0))
	_set_euler(CharacterModel.Bone.SHOULDER_R, Vector3(hang + swing * ARM_SWING, 0.0, 0.0))
	var elbow: float = lerpf(CharacterGestures.ARM_HANG.y, ELBOW_RUN, speed)
	_set_euler(CharacterModel.Bone.ELBOW_L, Vector3(elbow - ELBOW_PUMP * maxf(swing, 0.0), 0.0, 0.0))
	_set_euler(CharacterModel.Bone.ELBOW_R, Vector3(elbow - ELBOW_PUMP * maxf(-swing, 0.0), 0.0, 0.0))
	var twist: float = SHOULDER_TWIST * swing
	_set_euler(CharacterModel.Bone.BODY, Vector3(_lean + BREATH_NOD * 0.5 * _breath, twist, HIP_SWAY * swing + WEIGHT_SHIFT * shift))
	# La cabeza compensa la inclinación, el giro de hombros y el cambio de
	# peso: sigue mirando hacia adelante.
	_set_euler(CharacterModel.Bone.HEAD, Vector3(-0.8 * _lean + BREATH_NOD * _breath, -twist, -0.6 * WEIGHT_SHIFT * shift))
	_set_euler(CharacterModel.Bone.PHONE, Vector3.ZERO)
	var kick: float = smoothstep(0.0, 1.0, _kick)
	_vec[MOVE] = Vector3.ZERO
	_vec[SHAPE] = Vector3(-KICK_SQUASH * kick, 0.0, 0.0)
	_vec[EYES] = Vector3.ZERO


func _set_euler(bone: int, offset: Vector3) -> void:
	_rot[bone] = Quaternion.from_euler(_rest_euler[bone] + offset)


## El gesto encima: reemplaza los huesos que mueve (en el cuerpo y la
## cabeza, se suma) con su peso de mezcla.
func _gesture_pose() -> void:
	_face.gesture_face = -1
	if _gesture == CharacterGestures.Gesture.NONE:
		return
	var weight: float = CharacterGestures.sample(_gesture, _gesture_time, _gesture_rot, _gesture_vec)
	for bone: int in BONES:
		if not CharacterGestures.drives(_gesture, bone):
			continue
		if bone == CharacterModel.Bone.BODY or bone == CharacterModel.Bone.HEAD:
			_rot[bone] = _rot[bone] * Quaternion.IDENTITY.slerp(_gesture_rot[bone], weight)
		else:
			_rot[bone] = _rot[bone].slerp(_gesture_rot[bone], weight)
	for c: int in CharacterGestures.VECTORS:
		_vec[c] += _gesture_vec[c] * weight
	_face.gesture_face = CharacterGestures.face_at(_gesture, _gesture_time)


## La mirada: la cabeza gira hasta MAX_GLANCE hacia lo que mira y las pupilas
## siguen el resto.
func _look(dt: float) -> void:
	var target: Variant = null
	if _look_left > 0.0:
		target = _look_point
	elif _controller.idle_time() > GLANCE_DELAY:
		target = _controller.look_target
	var look: float = 0.0
	if target != null:
		var point: Vector3 = target
		var feet: Vector2 = _controller.floor_position
		var local_angle: float = wrapf(atan2(point.x - feet.x, point.z - feet.y) - _controller.yaw, -PI, PI)
		look = clampf(local_angle, -MAX_GLANCE - GAZE_REACH, MAX_GLANCE + GAZE_REACH)
	_look_left = maxf(_look_left - dt, 0.0)
	_look_angle = lerpf(_look_angle, look, 1.0 - exp(-LOOK_RATE * dt))
	var head_yaw: float = clampf(_look_angle, -MAX_GLANCE, MAX_GLANCE)
	_rot[CharacterModel.Bone.HEAD] = Quaternion(Vector3.UP, head_yaw) * _rot[CharacterModel.Bone.HEAD]
	var eyes: Vector3 = _vec[EYES]
	_gaze = Vector2((_look_angle - head_yaw) / GAZE_REACH * MAX_GAZE + eyes.x, eyes.y)


## Al cortar o cambiar un gesto, la pose sale de la que tenía y llega a la
## nueva en CUT_BLEND segundos.
func _blend_cut(dt: float) -> void:
	if _cut_weight > 0.0:
		_cut_weight = maxf(_cut_weight - dt / CUT_BLEND, 0.0)
		var k: float = smoothstep(0.0, 1.0, _cut_weight)
		for bone: int in BONES:
			_rot[bone] = _rot[bone].slerp(_from_rot[bone], k)
		for c: int in CharacterGestures.VECTORS:
			_vec[c] = _vec[c].lerp(_from_vec[c], k)
	for bone: int in BONES:
		_out_rot[bone] = _rot[bone]
	for c: int in CharacterGestures.VECTORS:
		_out_vec[c] = _vec[c]


func _snapshot() -> void:
	for bone: int in BONES:
		_from_rot[bone] = _out_rot[bone]
	for c: int in CharacterGestures.VECTORS:
		_from_vec[c] = _out_vec[c]
	_cut_weight = 1.0


## Escribe la pose en los pivotes. El cuerpo y las caderas bajan lo que suben
## las piernas (los pies quedan en el piso) más lo que el gesto despega.
func _write() -> void:
	for bone: int in BONES:
		_pivots[bone].quaternion = _rot[bone]
	var move: Vector3 = _vec[MOVE]
	var lift: float = move.y + _plant()
	var body: Node3D = _pivots[CharacterModel.Bone.BODY]
	body.position = _rest_position[CharacterModel.Bone.BODY] + Vector3(move.x, lift, move.z)
	_pivots[CharacterModel.Bone.HIP_L].position = _rest_position[CharacterModel.Bone.HIP_L] + Vector3(0.0, lift, 0.0)
	_pivots[CharacterModel.Bone.HIP_R].position = _rest_position[CharacterModel.Bone.HIP_R] + Vector3(0.0, lift, 0.0)
	var shape: Vector3 = _vec[SHAPE]
	_pivots[CharacterModel.Bone.HEAD].position = _rest_position[CharacterModel.Bone.HEAD] + Vector3(0.0, shape.z, 0.0)
	# Estirar y aplastar sin cambiar el volumen; respirar infla el pecho.
	var stretch: float = maxf(1.0 + shape.x, 0.5)
	var wide: float = 1.0 / sqrt(stretch)
	body.scale = Vector3(wide, stretch, wide) * (Vector3.ONE + BREATH_SCALE * _breath)
	var shown: float = smoothstep(0.0, 1.0, clampf(shape.y, 0.0, 1.0))
	_pivots[CharacterModel.Bone.PHONE].scale = Vector3.ONE * lerpf(CharacterModel.PHONE_HIDDEN, 1.0, shown)
	_lift = lift


## Cuánto baja el cuerpo para que el pie más bajo toque el piso (negativo).
func _plant() -> float:
	var thigh: Vector3 = Vector3(0.0, -CharacterModel.KNEE_DROP, 0.0)
	var shin: Vector3 = Vector3(0.0, -CharacterModel.SHIN, 0.0)
	var foot_l: Vector3 = _rot[CharacterModel.Bone.HIP_L] * (thigh + _rot[CharacterModel.Bone.KNEE_L] * shin)
	var foot_r: Vector3 = _rot[CharacterModel.Bone.HIP_R] * (thigh + _rot[CharacterModel.Bone.KNEE_R] * shin)
	return -(CharacterModel.HIP_HEIGHT + minf(foot_l.y, foot_r.y))


## Los resortes del pelo (giros) y de los cordones y la capucha
## (corrimiento): se quedan atrás cuando el cuerpo acelera o gira y rebotan.
## Los mueven los sombreadores (instance uniform `swing`).
func _secondary(dt: float) -> void:
	# Lo que sube o baja el cuerpo (saltar, el rebote del paso) también empuja
	# los cordones.
	if dt > 0.0:
		var vertical_speed: float = (_lift - _last_lift) / dt
		_accel.y = clampf((vertical_speed - _lift_speed) / dt, -MAX_ACCEL, MAX_ACCEL)
		_lift_speed = vertical_speed
	_last_lift = _lift
	var hair_goal: Vector3 = Vector3(HAIR_PUSH.x * _accel.z, -HAIR_PUSH.y * _turn_rate, -HAIR_PUSH.x * _accel.x)
	var pitch: float = _rot[CharacterModel.Bone.BODY].get_euler().x
	var strings_goal: Vector3 = -_accel * STRING_PUSH + Vector3(0.0, 0.0, STRING_LEAN * pitch)
	var remaining: float = dt
	while remaining > 0.0:
		var h: float = minf(remaining, SPRING_STEP)
		_hair_speed += (HAIR_SPRING.x * (hair_goal - _hair) - HAIR_SPRING.y * _hair_speed) * h
		_hair = (_hair + _hair_speed * h).clampf(-HAIR_MAX, HAIR_MAX)
		_strings_speed += (STRING_SPRING.x * (strings_goal - _strings) - STRING_SPRING.y * _strings_speed) * h
		_strings = (_strings + _strings_speed * h).limit_length(STRING_MAX)
		remaining -= h
	if _hair.distance_to(_shown_hair) > SWING_STEP:
		_shown_hair = _hair
		_head_mesh.set_instance_shader_parameter(&"swing", _hair)
		_head_outline.set_instance_shader_parameter(&"swing", _hair)
	if _strings.distance_to(_shown_strings) > SWING_STEP:
		_shown_strings = _strings
		_body_mesh.set_instance_shader_parameter(&"swing", _strings)
		_body_outline.set_instance_shader_parameter(&"swing", _strings)


func _update_face(dt: float) -> void:
	_face.talking = talking
	_face.focused = modeling and desk_area.has_area() and WalkGrid.distance_to_rect(_controller.floor_position, desk_area) <= NEAR
	_face.step(dt)
	var face: FacePainter.Face = _face.current()
	if face != _shown_face:
		_shown_face = face
		_head_mesh.set_instance_shader_parameter(&"expression", face)
	if _gaze.distance_to(_shown_gaze) > GAZE_STEP:
		_shown_gaze = _gaze
		_head_mesh.set_instance_shader_parameter(&"gaze", _gaze)

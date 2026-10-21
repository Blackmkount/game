class_name TouchTracker
extends RefCounted
## Interpreta los dedos sobre el mundo: toque, joystick flotante o pellizco
## para el zoom. No sabe nada del mundo ni de la interfaz: recibe posiciones
## en píxeles de la interfaz y deja el resultado en sus variables.
##
## - Toque: el dedo baja y sube sin moverse más de tap_slop_px. No importa
##   cuánto tiempo estuvo apoyado.
## - Joystick: el dedo se movió más de tap_slop_px. El aro aparece donde se
##   apoyó y lo sigue si el dedo se sale del aro.
## - Pellizco: un segundo dedo cambia la distancia entre los dos en más de
##   pinch_start_px. Corta el joystick; hasta que se levanten todos los dedos
##   no empieza otro gesto.

enum State { IDLE, PRESSED, JOYSTICK, PINCH, LOCKED }

var tuning: ControlsTuning
## Zona donde un dedo puede empezar un gesto (la pantalla sin los bordes).
var area: Rect2 = Rect2(0.0, 0.0, 720.0, 1280.0)

var state: State = State.IDLE
## Centro del aro del joystick y posición del dedo.
var joystick_base: Vector2 = Vector2.ZERO
var joystick_knob: Vector2 = Vector2.ZERO
## Distancia actual entre los dos dedos dividida por la inicial.
var pinch_ratio: float = 1.0

var _primary: int = -1
var _secondary: int = -1
var _press_position: Vector2 = Vector2.ZERO
var _positions: Dictionary[int, Vector2] = {}
var _pinch_start_distance: float = 0.0


func _init(p_tuning: ControlsTuning = null) -> void:
	tuning = p_tuning if p_tuning != null else ControlsTuning.current


## Un dedo bajó. Devuelve true si el gesto le interesa al mundo.
func press(index: int, position: Vector2) -> bool:
	if _positions.has(index):
		# Se perdió la subida de este dedo: empezamos de cero.
		cancel()
	match state:
		State.IDLE:
			if not area.has_point(position):
				return false
			_positions[index] = position
			_primary = index
			_press_position = position
			state = State.PRESSED
			return true
		State.PRESSED, State.JOYSTICK:
			if _secondary != -1 or not area.has_point(position):
				return false
			_positions[index] = position
			_secondary = index
			_pinch_start_distance = maxf(position.distance_to(_positions[_primary]), 1.0)
			return true
		State.PINCH, State.LOCKED:
			_positions[index] = position
			return true
	return false


## Un dedo se movió.
func drag(index: int, position: Vector2) -> void:
	if not _positions.has(index):
		return
	_positions[index] = position
	if state == State.PINCH:
		_update_pinch()
		return
	if _secondary != -1 and state in [State.PRESSED, State.JOYSTICK]:
		var distance: float = _positions[_primary].distance_to(_positions[_secondary])
		if absf(distance - _pinch_start_distance) >= tuning.pinch_start_px:
			state = State.PINCH
			_update_pinch()
			return
	if index != _primary:
		return
	if state == State.PRESSED and position.distance_to(_press_position) > tuning.tap_slop_px:
		state = State.JOYSTICK
		joystick_base = _press_position
	if state == State.JOYSTICK:
		joystick_knob = position
		var offset: Vector2 = joystick_knob - joystick_base
		if offset.length() > tuning.joystick_ring_px:
			# El aro sigue al dedo: cambiar de dirección es inmediato.
			joystick_base = joystick_knob - offset.normalized() * tuning.joystick_ring_px


## Un dedo subió. Devuelve la posición del toque si fue un toque, o null.
func release(index: int, position: Vector2) -> Variant:
	if not _positions.has(index):
		return null
	_positions.erase(index)
	if index == _secondary and state in [State.PRESSED, State.JOYSTICK]:
		# El segundo dedo no llegó a pellizcar: el gesto del primero sigue.
		_secondary = -1
		return null
	if state == State.PINCH and index != _primary and index != _secondary:
		# Un tercer dedo (o la palma) que se levanta no corta el pellizco.
		return null
	var tap: Variant = null
	if index == _primary and state == State.PRESSED and _secondary == -1 \
			and position.distance_to(_press_position) <= tuning.tap_slop_px:
		tap = _press_position
	if _positions.is_empty():
		_reset()
	else:
		# Queda otro dedo apoyado: no empieza nada nuevo hasta que suba.
		state = State.LOCKED
	return tap


## Olvida todos los dedos (la app pasó a segundo plano, se abrió un panel...).
func cancel() -> void:
	_positions.clear()
	_reset()


func is_joystick() -> bool:
	return state == State.JOYSTICK


func is_pinching() -> bool:
	return state == State.PINCH


## Dirección del joystick en la pantalla (x a la derecha, y hacia abajo),
## con largo igual a la fracción de velocidad (0 a 1).
func joystick_vector() -> Vector2:
	if state != State.JOYSTICK:
		return Vector2.ZERO
	var offset: Vector2 = joystick_knob - joystick_base
	var fraction: float = tuning.speed_fraction(offset.length())
	if fraction <= 0.0:
		return Vector2.ZERO
	return offset.normalized() * fraction


func _update_pinch() -> void:
	var a: Vector2 = _positions[_primary]
	var b: Vector2 = _positions[_secondary]
	pinch_ratio = a.distance_to(b) / _pinch_start_distance


func _reset() -> void:
	state = State.IDLE
	_primary = -1
	_secondary = -1
	pinch_ratio = 1.0
	_pinch_start_distance = 0.0

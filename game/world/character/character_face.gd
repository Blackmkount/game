class_name CharacterFace
extends RefCounted
## Qué cara pone el personaje (biblia de arte §7.7, capa de expresiones): la
## celda del atlas de FacePainter que se ve en cada momento.
##
## De más a menos importante:
## 1. una emoción con su tiempo (feliz al cobrar, preocupado si falla una
##    pieza...), que puede seguir con otra (sorpresa y después feliz);
## 2. la cara de un gesto (los ojos cerrados al bostezar o al estirarse);
## 3. hablar: mientras se ve el globo de diálogo la boca alterna las celdas
##    TALK_A y TALK_B a TALK_RATE cambios por segundo;
## 4. concentrado mientras modela cerca del escritorio;
## 5. la cara normal.
## Encima de la normal, de hablar y de concentrado, parpadea cada 2,4 a 5 s
## (al azar, con la semilla del animador: dos caras con la misma semilla
## parpadean igual).
##
## Sin memoria nueva por cuadro: la llama CharacterAnimator.step().

## Segundos entre un parpadeo y el siguiente (al azar entre los dos) y lo que
## dura cerrado.
const BLINK_GAP: Vector2 = Vector2(2.4, 5.0)
const BLINK_TIME: float = 0.12
## Cambios de boca por segundo al hablar.
const TALK_RATE: float = 8.0
## Cuánto dura cada cara de las reacciones (segundos, biblia §7.8). Las usa
## también el retrato del HUD (ProfileCard).
const HAPPY_TIME: float = 2.6
const WORRIED_TIME: float = 3.2
const SURPRISE_TIME: float = 0.6
const LEVEL_UP_TIME: float = 3.0
const READY_HAPPY_TIME: float = 1.5
const WAVE_HAPPY_TIME: float = 1.2

## Las caras sobre las que se parpadea (las demás ya tienen los ojos
## cerrados, muy abiertos o preocupados).
const BLINKS_OVER: Array[FacePainter.Face] = [
	FacePainter.Face.NEUTRAL, FacePainter.Face.TALK_A, FacePainter.Face.TALK_B, FacePainter.Face.FOCUSED,
]

## Lo pone el animador en cada cuadro: si se ve el globo de diálogo, si
## modela cerca del escritorio y la cara del gesto que hace (o -1).
var talking: bool = false
var focused: bool = false
var gesture_face: int = -1
## Para las capturas: sin parpadeos (la cara queda quieta).
var freeze_blinks: bool = false

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _emotion: FacePainter.Face = FacePainter.Face.NEUTRAL
var _emotion_left: float = 0.0
var _next: FacePainter.Face = FacePainter.Face.NEUTRAL
var _next_time: float = 0.0
var _blink_wait: float = 0.0
var _blink_left: float = 0.0
var _talk_clock: float = 0.0


func _init(seed_value: int = 0) -> void:
	reseed(seed_value)


## Empieza los parpadeos de nuevo con esa semilla.
func reseed(seed_value: int) -> void:
	_rng.seed = seed_value
	_blink_left = 0.0
	_blink_wait = _rng.randf_range(BLINK_GAP.x, BLINK_GAP.y)


## Pone una emoción por `seconds` segundos; después, `then` por
## `then_seconds` (si los hay) y al final vuelve a la cara de siempre.
func show(face: FacePainter.Face, seconds: float, then: FacePainter.Face = FacePainter.Face.NEUTRAL, then_seconds: float = 0.0) -> void:
	_emotion = face
	_emotion_left = seconds
	_next = then
	_next_time = then_seconds


## Sin emociones (partida nueva o cargada).
func clear() -> void:
	_emotion_left = 0.0
	_next_time = 0.0


## La emoción que se ve ahora (NEUTRAL si no hay ninguna).
func emotion() -> FacePainter.Face:
	return _emotion if _emotion_left > 0.0 else FacePainter.Face.NEUTRAL


func is_blinking() -> bool:
	return _blink_left > 0.0


func step(delta: float) -> void:
	if _emotion_left > 0.0:
		_emotion_left -= delta
		if _emotion_left <= 0.0 and _next_time > 0.0:
			show(_next, _next_time)
	_talk_clock = _talk_clock + delta if talking else 0.0
	if freeze_blinks:
		_blink_left = 0.0
		return
	if _blink_left > 0.0:
		_blink_left -= delta
		if _blink_left <= 0.0:
			_blink_wait = _rng.randf_range(BLINK_GAP.x, BLINK_GAP.y)
		return
	_blink_wait -= delta
	if _blink_wait <= 0.0:
		_blink_left = BLINK_TIME


## La celda del atlas que se ve ahora.
func current() -> FacePainter.Face:
	var face: FacePainter.Face = FacePainter.Face.NEUTRAL
	if _emotion_left > 0.0:
		face = _emotion
	elif gesture_face >= 0:
		face = gesture_face as FacePainter.Face
	elif talking:
		face = FacePainter.Face.TALK_A if fmod(_talk_clock * TALK_RATE, 2.0) < 1.0 else FacePainter.Face.TALK_B
	elif focused:
		face = FacePainter.Face.FOCUSED
	if _blink_left > 0.0 and face in BLINKS_OVER:
		return FacePainter.Face.BLINK
	return face

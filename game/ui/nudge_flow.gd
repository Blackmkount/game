class_name NudgeFlow
extends RefCounted
## Cuándo el personaje recuerda en voz alta lo próximo que conviene hacer en
## el taller ("¡Terminó! Voy a sacar la pieza."). Solo decide; quien lo usa
## (LoopFeedback) le pasa el paso de OrderQueries.next_step y hace hablar al
## personaje.
##
## Habla cuando el paso cambió y se mantuvo STABLE_SECONDS (así un cambio que
## dura un instante no se anuncia), cuando puede hablar (en la habitación, sin
## panel ni otro globo) y si no dijo lo mismo en los últimos COOLDOWN_SECONDS.
## Si en ese momento no puede hablar, lo dice apenas pueda. El primer paso que
## ve (al abrir el juego) no es un cambio: no lo anuncia.
##
## El tiempo entra como parámetro, en segundos.

const STABLE_SECONDS: float = 1.5
const COOLDOWN_SECONDS: float = 20.0
## Clave de texto de cada paso (OrderQueries.NextStep). NONE no se anuncia.
const KEYS: Dictionary[int, String] = {
	OrderQueries.NextStep.FAILED: "NUDGE_FAILED",
	OrderQueries.NextStep.REMOVE: "NUDGE_REMOVE",
	OrderQueries.NextStep.PACK: "NUDGE_PACK",
	OrderQueries.NextStep.DISPATCH: "NUDGE_DISPATCH",
	OrderQueries.NextStep.PRINT: "NUDGE_PRINT",
	OrderQueries.NextStep.MESSAGES: "SPEECH_NEW_MESSAGE",
	OrderQueries.NextStep.WAIT: "NUDGE_WAIT",
	OrderQueries.NextStep.NO_MAKEABLE: "NUDGE_NO_MAKEABLE",
}
## Todavía no vio ningún paso.
const UNSEEN: int = -1

var _step: int = UNSEEN
## Desde cuándo está el paso actual.
var _since: float = 0.0
## El paso actual cambió y todavía no se anunció.
var _pending: bool = false
## Cuándo se dijo por última vez cada paso.
var _said_at: Dictionary[int, float] = {}


## Lo que conviene decir ahora (clave de texto), o "" si nada. Si devuelve una
## clave, la da por dicha.
func update(step: int, now_s: float, can_talk: bool) -> String:
	if step != _step:
		_pending = _step != UNSEEN
		_step = step
		_since = now_s
	if not _pending or not can_talk or now_s - _since < STABLE_SECONDS:
		return ""
	_pending = false
	var key: String = KEYS.get(step, "")
	if key.is_empty() or (_said_at.has(step) and now_s - _said_at[step] < COOLDOWN_SECONDS):
		return ""
	_said_at[step] = now_s
	return key


## Algo ya lo dijo por otro lado (por ejemplo, al llegar un mensaje): no se
## repite enseguida.
func mark_said(step: int, now_s: float) -> void:
	_said_at[step] = now_s
	if step == _step:
		_pending = false

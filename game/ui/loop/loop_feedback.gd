class_name LoopFeedback
extends Node
## Lo que celebra o comenta el ciclo de pedidos. Es hijo de WorldControls, que
## lo crea al armarse.
##
## - Al despachar: "+$6" vuela del rincón de despacho al dinero (que da un
##   saltito al llegar) y "+5 XP" a la barra de experiencia, una vez por cuadro
##   aunque se despachen varios; el agradecimiento del cliente aparece como
##   aviso, y si iba atrasado, también eso.
## - El personaje dice algo cuando llega un mensaje, cuando falla una pieza y
##   al subir de nivel, y recuerda lo próximo que conviene hacer (NudgeFlow).
##   Solo habla en la habitación sin un panel abierto (subir de nivel se dice
##   igual con el panel abierto).
##
## Se actualiza con las señales de Events y el reloj, nunca en cada cuadro.

## Lo que tarda en volar lo que se cobra hasta el HUD.
const FLY_SECONDS: float = 0.8
## La experiencia sale un poco más abajo que el dinero, para no taparse.
const XP_FLOAT_OFFSET: Vector2 = Vector2(0.0, 44.0)

var _controls: WorldControls
var _nudges: NudgeFlow = NudgeFlow.new()
## Lo próximo que conviene hacer (OrderQueries.NextStep), recalculado con las
## señales.
var _step: int = OrderQueries.NextStep.NONE
var _step_queued: bool = false
## Lo cobrado en este cuadro, que vuela junto al final del cuadro.
var _cents: int = 0
var _xp: int = 0
var _payout_queued: bool = false


func _init(controls: WorldControls) -> void:
	_controls = controls


func _ready() -> void:
	Events.order_delivered.connect(_on_order_delivered)
	Events.offer_arrived.connect(_on_offer_arrived.unbind(1))
	Events.print_failed.connect(_on_print_failed)
	Events.level_up.connect(_on_level_up)
	Events.clock_ticked.connect(_on_clock_ticked)
	Events.game_loaded.connect(_on_game_loaded)
	Events.printer_changed.connect(_queue_step.unbind(1))
	Events.computer_changed.connect(_queue_step)
	Events.order_changed.connect(_queue_step.unbind(1))
	Events.order_removed.connect(_queue_step.unbind(1))
	Events.offers_changed.connect(_queue_step)
	Events.spools_changed.connect(_queue_step)
	_update_step()


## El personaje dice `text` (por ejemplo, por qué no se pudo una acción de la
## burbuja de cercanía).
func say(text: String) -> void:
	_controls.hud.speech.say(text)


func _on_order_delivered(order_uid: int, order_id: String, cents: int, xp: int, late: bool) -> void:
	_cents += cents
	_xp += xp
	if not _payout_queued:
		_payout_queued = true
		_show_payout.call_deferred()
	var rules: SimRules = Game.rules
	var client: String = tr(rules.clients[rules.orders[order_id]["client"]]["name_key"])
	for delivery: Delivery in Game.state.recent_deliveries:
		if delivery.order_uid == order_uid:
			_controls.hud.feedback.toast(UiFormat.tr_format("FEEDBACK_THANKS", [client, tr(delivery.thanks_key)]))
	if late:
		_controls.hud.feedback.toast(tr("FEEDBACK_LATE"), UiPalette.BADGE)


## Lo cobrado en el cuadro vuela desde el rincón de despacho hasta el HUD.
func _show_payout() -> void:
	_payout_queued = false
	var hud: Hud = _controls.hud
	var corner: Vector2 = _controls.world_to_ui(_controls.room.dispatch_item.top_center())
	var from: Vector2 = hud.keep_in_world(Rect2(corner, Vector2.ZERO))
	if _cents != 0:
		hud.feedback.fly(UiFormat.tr_format("FEEDBACK_MONEY", [UiFormat.money(_cents)]), UiPalette.GOLD, from, hud.money_pill_center(), FLY_SECONDS, hud.bump_money)
	if _xp != 0:
		hud.feedback.fly(UiFormat.tr_format("FORMAT_XP_REWARD", [_xp]), UiPalette.XP_FILL, from + XP_FLOAT_OFFSET, hud.xp_bar_center(), FLY_SECONDS)
	_cents = 0
	_xp = 0


## Si el personaje ya está diciendo algo (por ejemplo, que falló una pieza en
## el mismo momento), no lo tapa: el recordatorio lo dirá después.
func _on_offer_arrived() -> void:
	if _can_speak() and not _controls.hud.speech.is_talking():
		say(tr("SPEECH_NEW_MESSAGE"))
		_nudges.mark_said(OrderQueries.NextStep.MESSAGES, _now_seconds())


func _on_print_failed(_printer_uid: int, failure_type: String) -> void:
	if _can_speak():
		say(UiFormat.tr_format("SPEECH_FAILED", [tr("FAILURE_" + failure_type.to_upper())]))
		_nudges.mark_said(OrderQueries.NextStep.FAILED, _now_seconds())


func _on_level_up(level: int) -> void:
	if _controls.hud.current_screen_id() == "home":
		say(UiFormat.tr_format("SPEECH_LEVEL_UP", [level]))


## Una vez por segundo real: si conviene, el personaje recuerda lo próximo.
func _on_clock_ticked(_game_seconds: int) -> void:
	var can_talk: bool = _can_speak() and not _controls.hud.speech.is_talking()
	var key: String = _nudges.update(_step, _now_seconds(), can_talk)
	if not key.is_empty():
		say(tr(key))


## Partida nueva o cargada: se olvida lo dicho y lo cobrado sin mostrar.
func _on_game_loaded() -> void:
	_nudges = NudgeFlow.new()
	_cents = 0
	_xp = 0
	_queue_step()


func _queue_step() -> void:
	if _step_queued:
		return
	_step_queued = true
	_update_step.call_deferred()


func _update_step() -> void:
	_step_queued = false
	if Game.state != null:
		_step = OrderQueries.next_step(Game.state, Game.rules)


func _can_speak() -> bool:
	return _controls.hud.current_screen_id() == "home" and not _controls.hud.has_sheet()


## Segundos reales de juego: el reloj de los recordatorios. Sale de la partida,
## así que se detiene con ella.
func _now_seconds() -> float:
	return float(Game.state.game_seconds) / Game.rules.game_seconds_per_real_second

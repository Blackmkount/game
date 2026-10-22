extends GutTest
## Cuándo el personaje recuerda lo próximo que conviene hacer (NudgeFlow):
## solo si el paso cambió y se mantuvo, si puede hablar y si no lo dijo hace
## poco.

var _nudges: NudgeFlow


func before_each() -> void:
	_nudges = NudgeFlow.new()
	# Lo primero que ve es el punto de partida, no un cambio.
	assert_eq(_nudges.update(OrderQueries.NextStep.WAIT, 0.0, true), "")


func test_the_first_step_seen_is_not_announced() -> void:
	assert_eq(_nudges.update(OrderQueries.NextStep.WAIT, NudgeFlow.STABLE_SECONDS + 1.0, true), "")
	assert_eq(_nudges.update(OrderQueries.NextStep.WAIT, 60.0, true), "", "Ni más tarde")


func test_a_new_step_is_said_once_it_stayed_stable() -> void:
	assert_eq(_nudges.update(OrderQueries.NextStep.REMOVE, 10.0, true), "", "Recién cambió")
	assert_eq(_nudges.update(OrderQueries.NextStep.REMOVE, 10.0 + NudgeFlow.STABLE_SECONDS - 0.1, true), "")
	assert_eq(_nudges.update(OrderQueries.NextStep.REMOVE, 10.0 + NudgeFlow.STABLE_SECONDS, true), "NUDGE_REMOVE")
	assert_eq(_nudges.update(OrderQueries.NextStep.REMOVE, 13.0, true), "", "Lo dice una sola vez")


func test_a_step_that_changes_quickly_is_not_said() -> void:
	assert_eq(_nudges.update(OrderQueries.NextStep.PACK, 10.0, true), "")
	assert_eq(_nudges.update(OrderQueries.NextStep.DISPATCH, 11.0, true), "", "Embalar duró un segundo")
	assert_eq(_nudges.update(OrderQueries.NextStep.DISPATCH, 11.0 + NudgeFlow.STABLE_SECONDS, true), "NUDGE_DISPATCH", "Cuenta desde el último cambio")


func test_every_step_has_its_line_and_none_says_nothing() -> void:
	var expected: Dictionary[int, String] = {
		OrderQueries.NextStep.FAILED: "NUDGE_FAILED",
		OrderQueries.NextStep.REMOVE: "NUDGE_REMOVE",
		OrderQueries.NextStep.PACK: "NUDGE_PACK",
		OrderQueries.NextStep.DISPATCH: "NUDGE_DISPATCH",
		OrderQueries.NextStep.PRINT: "NUDGE_PRINT",
		OrderQueries.NextStep.MESSAGES: "SPEECH_NEW_MESSAGE",
		OrderQueries.NextStep.NO_MAKEABLE: "NUDGE_NO_MAKEABLE",
		OrderQueries.NextStep.NONE: "",
	}
	var now: float = 100.0
	for step: int in expected:
		_nudges.update(step, now, true)
		assert_eq(_nudges.update(step, now + NudgeFlow.STABLE_SECONDS, true), expected[step], "Paso %d" % step)
		now += 10.0
	_nudges.update(OrderQueries.NextStep.WAIT, now, true)
	assert_eq(_nudges.update(OrderQueries.NextStep.WAIT, now + NudgeFlow.STABLE_SECONDS, true), "NUDGE_WAIT")


func test_it_waits_until_it_can_talk() -> void:
	_nudges.update(OrderQueries.NextStep.PRINT, 10.0, false)
	assert_eq(_nudges.update(OrderQueries.NextStep.PRINT, 15.0, false), "", "Con un panel abierto no habla")
	assert_eq(_nudges.update(OrderQueries.NextStep.PRINT, 16.0, true), "NUDGE_PRINT", "Lo dice apenas puede")


func test_the_same_kind_is_not_repeated_within_the_cooldown() -> void:
	_nudges.update(OrderQueries.NextStep.REMOVE, 10.0, true)
	assert_eq(_nudges.update(OrderQueries.NextStep.REMOVE, 12.0, true), "NUDGE_REMOVE")
	_nudges.update(OrderQueries.NextStep.PACK, 13.0, true)
	assert_eq(_nudges.update(OrderQueries.NextStep.PACK, 15.0, true), "NUDGE_PACK", "Otro tipo sí se dice")
	_nudges.update(OrderQueries.NextStep.REMOVE, 16.0, true)
	assert_eq(_nudges.update(OrderQueries.NextStep.REMOVE, 18.0, true), "", "El mismo, 6 s después, no")
	assert_eq(_nudges.update(OrderQueries.NextStep.REMOVE, 40.0, true), "", "Ese cambio ya pasó")
	_nudges.update(OrderQueries.NextStep.PACK, 50.0, true)
	_nudges.update(OrderQueries.NextStep.REMOVE, 51.0, true)
	assert_eq(_nudges.update(OrderQueries.NextStep.REMOVE, 51.0 + NudgeFlow.STABLE_SECONDS, true), "NUDGE_REMOVE", "Pasado el tiempo, otra vez")


func test_something_said_elsewhere_counts_as_said() -> void:
	_nudges.mark_said(OrderQueries.NextStep.MESSAGES, 10.0)
	_nudges.update(OrderQueries.NextStep.MESSAGES, 10.5, true)
	assert_eq(_nudges.update(OrderQueries.NextStep.MESSAGES, 13.0, true), "", "Ya lo dijo al llegar el mensaje")
	_nudges.update(OrderQueries.NextStep.PRINT, 14.0, true)
	_nudges.mark_said(OrderQueries.NextStep.PRINT, 14.5)
	assert_eq(_nudges.update(OrderQueries.NextStep.PRINT, 16.0, true), "", "Marcar el paso actual lo da por dicho")
	_nudges.update(OrderQueries.NextStep.MESSAGES, 40.0, true)
	assert_eq(_nudges.update(OrderQueries.NextStep.MESSAGES, 42.0, true), "SPEECH_NEW_MESSAGE", "Pasado el tiempo, otra vez")

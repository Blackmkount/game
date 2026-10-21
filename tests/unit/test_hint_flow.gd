extends GutTest
## Orden de las pistas para jugadores nuevos y que se recuerden.

const SETTINGS_PATH: String = "user://test_hint_flow_settings.cfg"

var _previous_path: String


func before_each() -> void:
	_previous_path = UserSettings.path
	UserSettings.path = SETTINGS_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	UserSettings.path = _previous_path


func test_first_teaches_walking_then_tapping_then_nothing() -> void:
	var hints: HintFlow = HintFlow.new(UserSettings.load_settings())
	assert_eq(hints.mode(), MoveHint.Mode.MOVE)
	hints.add_walk(HintFlow.WALK_DISTANCE * 0.5)
	assert_eq(hints.mode(), MoveHint.Mode.MOVE, "Un paso no basta")
	hints.add_walk(HintFlow.WALK_DISTANCE)
	assert_eq(hints.mode(), MoveHint.Mode.TAP)
	hints.sheet_opened()
	assert_eq(hints.mode(), MoveHint.Mode.NONE)


func test_opening_a_panel_first_skips_the_tap_hint_later() -> void:
	var hints: HintFlow = HintFlow.new(UserSettings.load_settings())
	hints.sheet_opened()
	assert_eq(hints.mode(), MoveHint.Mode.MOVE, "Todavía falta aprender a caminar")
	hints.add_walk(HintFlow.WALK_DISTANCE)
	assert_eq(hints.mode(), MoveHint.Mode.NONE, "Ya sabe tocar objetos: no se le repite")


func test_walking_by_tapping_the_floor_also_teaches_moving() -> void:
	var hints: HintFlow = HintFlow.new(UserSettings.load_settings())
	hints.walked_by_tap()
	assert_eq(hints.mode(), MoveHint.Mode.TAP)


func test_what_was_learned_is_remembered_next_time() -> void:
	var hints: HintFlow = HintFlow.new(UserSettings.load_settings())
	hints.add_walk(HintFlow.WALK_DISTANCE)
	var next_time: HintFlow = HintFlow.new(UserSettings.load_settings())
	assert_eq(next_time.mode(), MoveHint.Mode.TAP)

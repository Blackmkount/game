extends GutTest
## Cuándo el juego se abrió para una herramienta (pruebas, capturas) y no
## debe tocar la partida ni las preferencias del jugador.


func test_scripts_and_the_gut_panel_are_tool_runs() -> void:
	assert_true(RunMode.is_tool_run_for(PackedStringArray(["-s", "res://addons/gut/gut_cmdln.gd"])), "run_tests.sh")
	assert_true(RunMode.is_tool_run_for(PackedStringArray(["--script", "res://tools/screenshots.gd"])), "Capturas")
	assert_true(RunMode.is_tool_run_for(PackedStringArray(["res://addons/gut/gui/run_from_editor.tscn"])), "Panel GUT del editor")


func test_playing_is_not_a_tool_run() -> void:
	assert_false(RunMode.is_tool_run_for(PackedStringArray([])), "Exportado o web")
	assert_false(RunMode.is_tool_run_for(PackedStringArray(["res://game/scenes/main.tscn"])), "Jugar desde el editor")


func test_these_tests_never_touch_the_players_files() -> void:
	assert_true(RunMode.is_tool_run())
	assert_false(SaveManager.enabled, "La partida del jugador queda intacta")
	assert_ne(UserSettings.TOOL_PATH, UserSettings.PLAYER_PATH)

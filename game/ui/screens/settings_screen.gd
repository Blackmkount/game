class_name SettingsScreen
extends ScreenBase
## Ajustes: idioma, empezar una partida nueva y créditos.

## Avisa cuando cambia el idioma, para que la pantalla se vuelva a armar.
signal language_changed

const LANGUAGES: Array[Dictionary] = [
	{"locale": "es", "text": "SETTINGS_SPANISH"},
	{"locale": "en", "text": "SETTINGS_ENGLISH"},
]
## Segundos que "Empezar partida nueva" espera el segundo toque que confirma.
const CONFIRM_SECONDS: float = 3.0
## Alto del botón "Empezar partida nueva": el mínimo táctil de ESTILO.
const NEW_GAME_HEIGHT: float = 88.0

## Qué hace la partida nueva después de guardarse: volver a armar la escena.
## Las pruebas lo cambian para no recargar el programa de pruebas.
var restart: Callable = func() -> void: get_tree().reload_current_scene.call_deferred()

var _new_game_button: Button
var _confirm_timer: Timer


func _init() -> void:
	super("gear", "SCREEN_SETTINGS")
	_confirm_timer = Timer.new()
	_confirm_timer.name = "ConfirmTimer"
	_confirm_timer.one_shot = true
	_confirm_timer.timeout.connect(_on_confirm_timeout)
	add_child(_confirm_timer)


func _build_content() -> void:
	add_section("SETTINGS_LANGUAGE")
	var row: HBoxContainer = UiKit.hbox(10)
	content.add_child(row)
	var group: ButtonGroup = ButtonGroup.new()
	for language: Dictionary in LANGUAGES:
		var button: Button = Button.new()
		button.name = "Language_" + language["locale"]
		button.text = tr(language["text"])
		button.theme_type_variation = "TabButton"
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = TranslationServer.get_locale().begins_with(language["locale"])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void: _set_language(language["locale"]))
		row.add_child(button)
	_new_game_button = Button.new()
	_new_game_button.name = "NewGame"
	_new_game_button.text = tr("SETTINGS_NEW_GAME")
	_new_game_button.focus_mode = Control.FOCUS_NONE
	_new_game_button.custom_minimum_size = Vector2(0, NEW_GAME_HEIGHT)
	_new_game_button.pressed.connect(_on_new_game_pressed)
	content.add_child(_new_game_button)
	add_section("SETTINGS_CREDITS")
	content.add_child(UiKit.label(tr("SETTINGS_CREDITS_TEXT"), "MutedLabel", true))


func _set_language(locale: String) -> void:
	if TranslationServer.get_locale().begins_with(locale):
		return
	TranslationServer.set_locale(locale)
	language_changed.emit()


## Primer toque: pide confirmar durante CONFIRM_SECONDS. Segundo toque: borra
## la partida, guarda la nueva y vuelve a armar todo.
func _on_new_game_pressed() -> void:
	if _confirm_timer.is_stopped():
		_new_game_button.text = tr("SETTINGS_NEW_GAME_CONFIRM")
		_confirm_timer.start(CONFIRM_SECONDS)
		return
	_confirm_timer.stop()
	Game.reset_game(randi())
	SaveManager.save_now()
	restart.call()


func _on_confirm_timeout() -> void:
	_new_game_button.text = tr("SETTINGS_NEW_GAME")

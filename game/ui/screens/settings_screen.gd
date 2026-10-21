class_name SettingsScreen
extends ScreenBase
## Ajustes: idioma y créditos.

## Avisa cuando cambia el idioma, para que la pantalla se vuelva a armar.
signal language_changed

const LANGUAGES: Array[Dictionary] = [
	{"locale": "es", "text": "SETTINGS_SPANISH"},
	{"locale": "en", "text": "SETTINGS_ENGLISH"},
]


func _init() -> void:
	super("gear", "SCREEN_SETTINGS")


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
	add_section("SETTINGS_CREDITS")
	content.add_child(UiKit.label(tr("SETTINGS_CREDITS_TEXT"), "MutedLabel", true))


func _set_language(locale: String) -> void:
	if TranslationServer.get_locale().begins_with(locale):
		return
	TranslationServer.set_locale(locale)
	language_changed.emit()

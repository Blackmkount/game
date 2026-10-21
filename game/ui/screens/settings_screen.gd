class_name SettingsScreen
extends ScreenBase
## Ajustes: idioma, controles (solo para pruebas durante el desarrollo) y
## créditos.

## Avisa que hay que volver a armar la pantalla: cambió el idioma o se
## reiniciaron los controles.
signal rebuild_requested

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
	_build_controls()
	add_section("SETTINGS_CREDITS")
	content.add_child(UiKit.label(tr("SETTINGS_CREDITS_TEXT"), "MutedLabel", true))


## Deslizadores para probar en el teléfono cómo se sienten los controles. Se
## quitan de aquí cuando exista el menú de pruebas (Fase 1, tarea 4).
func _build_controls() -> void:
	var tuning: ControlsTuning = ControlsTuning.current
	add_section("SETTINGS_CONTROLS")
	content.add_child(UiKit.label(tr("SETTINGS_CONTROLS_NOTE"), "MutedLabel", true))
	_slider("WalkSpeed", "SETTINGS_WALK_SPEED", 1.5, 4.0, 0.1, tuning.walk_speed,
		func(value: float) -> void: tuning.walk_speed = value,
		func(value: float) -> String: return UiFormat.decimal(value))
	# Más allá del radio del aro el dedo arrastra el aro: no se podría llegar a
	# la velocidad máxima.
	_slider("FullSpeed", "SETTINGS_FULL_SPEED", 32.0, tuning.joystick_ring_px, 2.0, tuning.joystick_full_speed_px,
		func(value: float) -> void: tuning.joystick_full_speed_px = value,
		func(value: float) -> int: return roundi(value))
	_slider("Follow", "SETTINGS_FOLLOW", 0.05, 0.5, 0.01, tuning.camera_follow_time,
		func(value: float) -> void: tuning.camera_follow_time = value,
		func(value: float) -> String: return UiFormat.decimal(value, 2))
	_slider("Reach", "SETTINGS_REACH", 0.4, 1.2, 0.05, tuning.reach_enter,
		func(value: float) -> void:
			tuning.reach_enter = value
			tuning.reach_exit = value + 0.2,
		func(value: float) -> String: return UiFormat.decimal(value, 2))
	# Interruptor con el mismo estilo que las pestañas: encendido = cian.
	var aligned: Button = Button.new()
	aligned.name = "Aligned"
	aligned.theme_type_variation = "TabButton"
	aligned.toggle_mode = true
	aligned.button_pressed = tuning.joystick_screen_aligned
	aligned.text = UiFormat.tr_format("SETTINGS_ALIGNED", [tr("SETTINGS_ON" if aligned.button_pressed else "SETTINGS_OFF")])
	aligned.focus_mode = Control.FOCUS_NONE
	aligned.toggled.connect(func(on: bool) -> void:
		tuning.joystick_screen_aligned = on
		aligned.text = UiFormat.tr_format("SETTINGS_ALIGNED", [tr("SETTINGS_ON" if on else "SETTINGS_OFF")]))
	content.add_child(aligned)
	var reset: Button = Button.new()
	reset.name = "ResetControls"
	reset.text = tr("SETTINGS_RESET_CONTROLS")
	reset.focus_mode = Control.FOCUS_NONE
	reset.pressed.connect(func() -> void:
		ControlsTuning.reset()
		rebuild_requested.emit())
	content.add_child(reset)


## Fila con un texto que muestra el valor y un deslizador debajo.
func _slider(node_name: String, text_key: String, minimum: float, maximum: float, step: float, value: float, apply: Callable, shown: Callable) -> void:
	var label: Label = UiKit.label(UiFormat.tr_format(text_key, [shown.call(value)]))
	content.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.name = node_name
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(0, 56)
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(func(new_value: float) -> void:
		apply.call(new_value)
		label.text = UiFormat.tr_format(text_key, [shown.call(new_value)]))
	content.add_child(slider)


func _set_language(locale: String) -> void:
	if TranslationServer.get_locale().begins_with(locale):
		return
	TranslationServer.set_locale(locale)
	rebuild_requested.emit()

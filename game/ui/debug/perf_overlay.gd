class_name PerfOverlay
extends PanelContainer
## Panel de depuración (biblia de arte §13): lo que hay que medir en el
## teléfono del dueño. Se abre con "#debug" al final de la dirección de la
## versión web o con cinco toques seguidos sobre la tarjeta de nivel
## (ProfileCard), y se cierra con su botón.
##
## Muestra, cada REFRESH_SECONDS: cuadros por segundo, llamadas de dibujo y
## triángulos del cuadro entero (con la interfaz) y del mundo, el nivel de
## calidad gráfica y su modo, el ancho y el suavizado del dibujo del mundo y
## si el sol da sombra, el resultado de ColorProbe, si las impresoras están
## en su versión lejana, cuánto tardó en armarse el cuarto (el primero, con
## las cachés vacías: si pasa de 1 s, decisión D4) y la hora del juego.
##
## Con "Menos" queda solo con los números (para ver el cuarto mientras se
## mide); con "Más" vuelven los botones.
##
## Deja cambiar la calidad (como en Ajustes) y probar escenas sin tocar la
## partida del jugador (Game.start_trial: nada se guarda hasta volver a abrir
## el juego): el cuarto inicial, el taller lleno con trabajos (el mismo de la
## prueba de presupuesto y de la captura 43) y la mañana, la tarde o la noche.

## Cada cuánto se actualizan los números (s).
const REFRESH_SECONDS: float = 0.5
## Lo que hay que escribir después de "#" en la dirección.
const URL_FLAG: String = "debug"
## Las horas que se pueden probar (horas de juego): la mañana, la tarde
## dorada y la noche (biblia §6.1).
const HOURS: Dictionary[String, float] = {"DEBUG_MORNING": 8.0, "DEBUG_GOLDEN": 17.25, "DEBUG_NIGHT": 22.0}
const PROBE_TEXT: Dictionary[ColorProbe.Status, String] = {
	ColorProbe.Status.PENDING: "DEBUG_PROBE_PENDING",
	ColorProbe.Status.MEASURED: "DEBUG_PROBE_MEASURED",
	ColorProbe.Status.OUT_OF_RANGE: "DEBUG_PROBE_OUT_OF_RANGE",
	ColorProbe.Status.NO_SCREEN: "DEBUG_PROBE_NO_SCREEN",
}
## Ancho del panel: el de la pantalla menos los márgenes del HUD (tapa los
## objetivos en vez de quedar a medias encima).
const WIDTH: float = 688.0
const BUTTON_HEIGHT: float = 64.0
const HEADER_BUTTON_WIDTH: float = 140.0
const FONT_SIZE: int = 20

var _room: RoomView
var _world_view: WorldViewport
var _stats: Label
var _trial_note: Label
## Los botones (se esconden con "Menos") y el botón que los esconde.
var _controls: VBoxContainer
var _more: Button
var _mode_buttons: Dictionary[GraphicsQuality.Mode, Button] = {}


func _init(room: RoomView, world_view: WorldViewport) -> void:
	_room = room
	_world_view = world_view
	name = "PerfOverlay"
	custom_minimum_size = Vector2(WIDTH, 0.0)


## Si la parte de la dirección después de "#" (`url_hash`, con o sin el
## "#") pide el panel: "#debug", o "debug" entre otras opciones separadas con
## "&".
static func requested_by(url_hash: String) -> bool:
	return URL_FLAG in url_hash.trim_prefix("#").split("&")


## Si la dirección de la versión web pide el panel (fuera de la web, no).
static func requested_by_url() -> bool:
	if not OS.has_feature("web"):
		return false
	var url_hash: Variant = JavaScriptBridge.eval("window.location.hash", true)
	return url_hash is String and requested_by(url_hash)


func _ready() -> void:
	# Fondo opaco: que no se lean a través los textos de abajo.
	theme_type_variation = "CardPanel"
	var rows: VBoxContainer = UiKit.vbox(8)
	add_child(rows)
	var header: HBoxContainer = UiKit.hbox(8)
	rows.add_child(header)
	var title: Label = UiKit.label(tr("DEBUG_TITLE"), "BoldLabel")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_more = _button("More", "DEBUG_LESS", _toggle_controls)
	_more.size_flags_horizontal = Control.SIZE_SHRINK_END
	_more.custom_minimum_size.x = HEADER_BUTTON_WIDTH
	header.add_child(_more)
	var close: Button = _button("Close", "DEBUG_CLOSE", queue_free)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.custom_minimum_size.x = HEADER_BUTTON_WIDTH
	header.add_child(close)
	_stats = UiKit.label("", "SmallLabel", true)
	rows.add_child(_stats)

	_controls = UiKit.vbox(8)
	rows.add_child(_controls)
	var modes: HBoxContainer = UiKit.hbox(6)
	_controls.add_child(modes)
	var group: ButtonGroup = ButtonGroup.new()
	for mode: GraphicsQuality.Mode in SettingsScreen.GRAPHICS_MODES:
		var button: Button = _button("Quality_" + GraphicsQuality.MODE_NAMES[mode], SettingsScreen.GRAPHICS_MODES[mode], GraphicsQuality.current.set_mode.bind(mode))
		button.theme_type_variation = "TabButton"
		button.toggle_mode = true
		button.button_group = group
		modes.add_child(button)
		_mode_buttons[mode] = button

	_controls.add_child(UiKit.label(tr("DEBUG_TRY"), "MutedLabel", true))
	var scenes: HBoxContainer = UiKit.hbox(6)
	_controls.add_child(scenes)
	scenes.add_child(_button("Room_start", "DEBUG_ROOM_START", _try_starting_room))
	scenes.add_child(_button("Room_full", "DEBUG_ROOM_FULL", _try_full_workshop))
	var hours: HBoxContainer = UiKit.hbox(6)
	_controls.add_child(hours)
	for key: String in HOURS:
		hours.add_child(_button("Hour_" + key.trim_prefix("DEBUG_").to_lower(), key, _try_hour.bind(HOURS[key])))
	_trial_note = UiKit.label(tr("DEBUG_TRIAL"), "MutedLabel", true)
	rows.add_child(_trial_note)

	var timer: Timer = Timer.new()
	timer.name = "RefreshTimer"
	timer.wait_time = REFRESH_SECONDS
	timer.autostart = true
	timer.timeout.connect(refresh)
	add_child(timer)
	GraphicsQuality.current.changed.connect(refresh)
	refresh()


## Vuelve a escribir los números y marca el modo de calidad elegido.
func refresh() -> void:
	var quality: GraphicsQuality = GraphicsQuality.current
	for mode: GraphicsQuality.Mode in _mode_buttons:
		_mode_buttons[mode].set_pressed_no_signal(mode == quality.mode)
	_trial_note.visible = Game.trial
	var fps: float = Engine.get_frames_per_second()
	var world: SubViewport = _world_view.get_node("SubViewport")
	var world_calls: int = world.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME) \
		+ world.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	var lines: PackedStringArray = PackedStringArray([
		UiFormat.tr_format("DEBUG_FPS", [UiFormat.decimal(fps), UiFormat.decimal(1000.0 / fps if fps > 0.0 else 0.0)]),
		UiFormat.tr_format("DEBUG_DRAW", [
			UiFormat.number(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))),
			UiFormat.number(world_calls),
			UiFormat.number(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))]),
		UiFormat.tr_format("DEBUG_QUALITY", [tr(SettingsScreen.GRAPHICS_LEVELS[quality.level]), tr(SettingsScreen.GRAPHICS_MODES[quality.mode])]),
		UiFormat.tr_format("DEBUG_WORLD", [world.size.x, _msaa_samples(world.msaa_3d), _yes_no(quality.sun_shadow())]),
		UiFormat.tr_format("DEBUG_PROBE", [tr(PROBE_TEXT[ColorProbe.status]),
			UiFormat.decimal(ColorProbe.base_reading, 3), ColorProbe.base_fix,
			UiFormat.decimal(ColorProbe.sun_reading, 3), ColorProbe.sun_fix]),
		UiFormat.tr_format("DEBUG_FAR", [_yes_no(_room.far_printers)]),
		UiFormat.tr_format("DEBUG_BUILD", [UiFormat.number(roundi(RoomView.first_build_msec)), UiFormat.number(roundi(_room.build_msec))]),
		UiFormat.tr_format("DEBUG_HOUR", [UiFormat.date(Game.state.game_minutes) if Game.state != null else "-"]),
	])
	_stats.text = "\n".join(lines)


## "Menos" esconde los botones (queda solo con los números); "Más" los
## vuelve a mostrar.
func _toggle_controls() -> void:
	_controls.visible = not _controls.visible
	_more.text = tr("DEBUG_LESS") if _controls.visible else tr("DEBUG_MORE")
	reset_size()


## Prueba con una partida nueva (el cuarto del comienzo).
func _try_starting_room() -> void:
	Game.start_trial(GameState.new_game(Game.rules, randi()))


## Prueba con el taller lleno, en el nivel del taller y con trabajos en cada
## estado: lo más pesado que se puede dibujar hoy.
func _try_full_workshop() -> void:
	Game.start_trial(DebugTools.busy_workshop(Game.rules, randi()))


## Adelanta el reloj hasta la próxima vez que marque `hour` (en una copia de
## la partida si todavía no se estaba probando: la de verdad no cambia).
func _try_hour(hour: float) -> void:
	if Game.state == null:
		return
	if not Game.trial:
		var errors: Array[String] = []
		var copy: GameState = SaveCodec.decode(SaveCodec.encode(Game.state), Game.rules, errors)
		if copy == null:
			return
		Game.start_trial(copy)
	var minutes: float = fposmod(hour * GameClock.MINUTES_PER_HOUR - Game.state.game_minutes, GameClock.MINUTES_PER_DAY)
	Game.advance(minutes * GameClock.SECONDS_PER_MINUTE / Game.rules.game_seconds_per_real_second)
	refresh()


func _button(button_name: String, text_key: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.name = button_name
	button.text = tr(text_key)
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0.0, BUTTON_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.pressed.connect(action)
	return button


func _yes_no(value: bool) -> String:
	return tr("DEBUG_YES") if value else tr("DEBUG_NO")


static func _msaa_samples(msaa: Viewport.MSAA) -> int:
	match msaa:
		Viewport.MSAA_2X:
			return 2
		Viewport.MSAA_4X:
			return 4
		Viewport.MSAA_8X:
			return 8
	return 1

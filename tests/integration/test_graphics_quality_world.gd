extends GutTest
## La calidad gráfica en el juego (biblia de arte §2.2, D7): el nivel se
## aplica al mundo (ancho y suavizado del dibujo, sombra del sol, polvo,
## oclusión del piso) y a las vistas de la interfaz, también al cambiarlo
## jugando; Ajustes ofrece Automática, Alta y Baja; el panel de depuración se
## abre con cinco toques en la tarjeta de nivel (o "#debug" en la dirección
## de la versión web), muestra lo que hay que medir y deja probar escenas sin
## tocar la partida del jugador.

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
const SEED: int = 1234
const SETTINGS_PATH: String = "user://test_graphics_quality_world_settings.cfg"
## Partida guardada de esta prueba (la "del jugador" al probar escenas).
const SAVE_PATH: String = "user://test_graphics_quality_world_save.json"
## Tamaño de ventana que da la pantalla real de 720×1280 de la interfaz.
const WINDOW_SIZE: Vector2i = Vector2i(405, 720)
## Uid del escritorio en una partida nueva (FloorAO lo oscurece).
const DESK_UID: int = 1

var _main: Control
var _room: RoomView
var _hud: Hud
var _quality: GraphicsQuality
var _previous_quality: GraphicsQuality
var _previous_settings_path: String
var _previous_processing: bool
var _previous_window_size: Vector2i
var _previous_save_enabled: bool
var _previous_save_path: String


func before_each() -> void:
	_previous_processing = Game.is_processing()
	Game.set_process(false)
	Game.reset_game(SEED)
	_previous_window_size = get_tree().root.size
	get_tree().root.size = WINDOW_SIZE
	_previous_save_enabled = SaveManager.enabled
	_previous_save_path = SaveManager.path
	SaveManager.path = SAVE_PATH
	_remove_save()
	_previous_quality = GraphicsQuality.current
	_previous_settings_path = UserSettings.path
	UserSettings.path = SETTINGS_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	_quality = GraphicsQuality.new(UserSettings.load_settings())
	_quality.set_mode(GraphicsQuality.Mode.HIGH)
	GraphicsQuality.current = _quality


func after_each() -> void:
	Game.trial = false
	SaveManager.enabled = _previous_save_enabled
	_remove_save()
	SaveManager.path = _previous_save_path
	GraphicsQuality.current = _previous_quality
	UserSettings.path = _previous_settings_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	get_tree().root.size = _previous_window_size
	Game.reset_game(SEED)
	Game.set_process(_previous_processing)


func test_the_low_level_is_applied_to_the_world() -> void:
	# Una pantalla de 1080 px: en Alta se dibujaría a 1080.
	get_tree().root.size = Vector2i(1080, 1920)
	_quality.set_mode(GraphicsQuality.Mode.LOW)
	await _load()
	var view: SubViewport = _main.get_node("WorldView/SubViewport")
	assert_eq(view.msaa_3d, Viewport.MSAA_2X, "Menos suavizado")
	assert_eq(view.size.x, int(GraphicsQuality.MAX_WIDTH[GraphicsQuality.Level.LOW]), "Hasta 720 px de ancho")
	assert_false(_sun().shadow_enabled, "El sol sin sombra")
	assert_false(_room.decor.dust.enabled, "Sin polvo")
	assert_false(_room.decor.dust.visible, "Ni a las 08:00, con el haz de la ventana")
	assert_almost_eq(_floor_shade_under_desk(), 1.0 - FloorAO.STRENGTH * GraphicsQuality.FLOOR_AO[GraphicsQuality.Level.LOW], 2.0 / 255.0, "El piso se oscurece más bajo el escritorio")


func test_switching_the_level_while_playing_reapplies_everything() -> void:
	await _load()
	var view: SubViewport = _main.get_node("WorldView/SubViewport")
	var portrait_sun: DirectionalLight3D = _hud.get_node("TopBar/ProfileCard").find_children("*", "DirectionalLight3D", true, false)[0]
	assert_true(_sun().shadow_enabled, "Alta: el sol con sombra")
	assert_true(portrait_sun.shadow_enabled, "Y el del retrato también")
	assert_true(_room.decor.dust.visible, "Alta, a las 08:00: el polvo del haz")
	var high_shade: float = _floor_shade_under_desk()
	assert_almost_eq(high_shade, 1.0 - FloorAO.STRENGTH, 2.0 / 255.0)
	_quality.set_mode(GraphicsQuality.Mode.LOW)
	await wait_process_frames(1)
	assert_false(_sun().shadow_enabled, "Baja: sin sombra")
	assert_false(portrait_sun.shadow_enabled, "El retrato sigue al mundo (misma cuenta de color)")
	assert_false(_room.decor.dust.visible, "Sin polvo")
	assert_lt(_floor_shade_under_desk(), high_shade, "Más oscuro bajo el escritorio")
	assert_eq(view.msaa_3d, Viewport.MSAA_2X)
	_quality.set_mode(GraphicsQuality.Mode.HIGH)
	await wait_process_frames(1)
	assert_true(_sun().shadow_enabled, "De vuelta en Alta")
	assert_true(portrait_sun.shadow_enabled)
	assert_true(_room.decor.dust.visible)
	assert_almost_eq(_floor_shade_under_desk(), high_shade, 0.0001)
	assert_eq(view.msaa_3d, Viewport.MSAA_4X)


func test_the_settings_offer_automatic_high_and_low() -> void:
	await _load()
	_hud.open_screen("settings")
	await wait_process_frames(1)
	var settings: SettingsScreen = _hud.get_node("ScreenHost/Screen")
	var buttons: Dictionary[GraphicsQuality.Mode, Button] = {}
	for mode: GraphicsQuality.Mode in SettingsScreen.GRAPHICS_MODES:
		buttons[mode] = settings.find_child("Graphics_" + GraphicsQuality.MODE_NAMES[mode], true, false)
		assert_not_null(buttons[mode], "Opción %s" % GraphicsQuality.MODE_NAMES[mode])
		assert_eq(buttons[mode].text, tr(SettingsScreen.GRAPHICS_MODES[mode]), "Con su texto traducido")
		assert_gte(buttons[mode].size.y, SettingsScreen.BUTTON_HEIGHT, "Del alto táctil mínimo de ESTILO")
	for language: Dictionary in SettingsScreen.LANGUAGES:
		var language_button: Button = settings.find_child("Language_" + String(language["locale"]), true, false)
		assert_gte(language_button.size.y, SettingsScreen.BUTTON_HEIGHT, "Idioma: del alto táctil mínimo")
	assert_true(buttons[GraphicsQuality.Mode.HIGH].button_pressed, "Marca la elegida")
	buttons[GraphicsQuality.Mode.LOW].pressed.emit()
	await wait_process_frames(1)
	assert_eq(_quality.mode, GraphicsQuality.Mode.LOW, "Baja elegida")
	assert_false(_sun().shadow_enabled, "Y se ve enseguida")
	assert_true(_settings_text(settings).contains(UiFormat.tr_format("SETTINGS_GRAPHICS_NOTE", [tr("SETTINGS_GRAPHICS_LOW")])), "Dice en qué nivel se ve")
	assert_eq(UserSettings.load_settings().graphics_value(GraphicsQuality.MODE_KEY, ""), "low", "Se guarda")
	buttons[GraphicsQuality.Mode.AUTO].pressed.emit()
	await wait_process_frames(1)
	assert_eq(_quality.mode, GraphicsQuality.Mode.AUTO)
	assert_eq(_quality.level, GraphicsQuality.Level.HIGH, "La automática empieza en Alta")
	assert_true(_quality.is_measuring(), "Y mide de nuevo")
	assert_true(_settings_text(settings).contains(UiFormat.tr_format("SETTINGS_GRAPHICS_NOTE", [tr("SETTINGS_GRAPHICS_HIGH")])))


func test_the_debug_panel_is_asked_by_the_url_hash() -> void:
	assert_true(PerfOverlay.requested_by("#debug"))
	assert_true(PerfOverlay.requested_by("debug"))
	assert_true(PerfOverlay.requested_by("#lang=en&debug"))
	assert_false(PerfOverlay.requested_by(""))
	assert_false(PerfOverlay.requested_by("#debugger"))
	assert_false(PerfOverlay.requested_by_url(), "Fuera de la versión web, nunca")


func test_five_quick_taps_on_the_level_card_open_the_debug_panel() -> void:
	await _load()
	var card: ProfileCard = _hud.get_node("TopBar/ProfileCard")
	await _tap(card, ProfileCard.DEBUG_TAPS - 1)
	assert_null(_hud.get_node_or_null("PerfOverlay"), "Con cuatro toques, nada")
	await _tap(card, 1)
	var overlay: PerfOverlay = _hud.get_node_or_null("PerfOverlay")
	assert_not_null(overlay, "Con cinco, el panel")
	await _tap(card, ProfileCard.DEBUG_TAPS)
	await wait_process_frames(1)
	assert_null(_hud.get_node_or_null("PerfOverlay"), "Otros cinco lo cierran")


func test_the_debug_panel_shows_what_to_measure_and_changes_the_quality() -> void:
	await _load()
	_hud.toggle_debug(_room, _main.get_node("WorldView"))
	var overlay: PerfOverlay = _hud.get_node("PerfOverlay")
	var text: String = _overlay_text(overlay)
	for expected: String in [
		UiFormat.tr_format("DEBUG_QUALITY", [tr("SETTINGS_GRAPHICS_HIGH"), tr("SETTINGS_GRAPHICS_HIGH")]),
		UiFormat.tr_format("DEBUG_FAR", [tr("DEBUG_NO")]),
		tr("DEBUG_PROBE_NO_SCREEN"),
	]:
		assert_true(text.contains(expected), "Muestra: " + expected)
	assert_true(text.contains(UiFormat.tr_format("DEBUG_WORLD", [(_main.get_node("WorldView/SubViewport") as SubViewport).size.x, 4, tr("DEBUG_YES")])), "El ancho, el suavizado y la sombra")
	(overlay.find_child("Quality_low", true, false) as Button).pressed.emit()
	await wait_process_frames(1)
	assert_eq(_quality.mode, GraphicsQuality.Mode.LOW, "Cambia la calidad, como Ajustes")
	assert_false(_sun().shadow_enabled)
	assert_true(_overlay_text(overlay).contains(UiFormat.tr_format("DEBUG_QUALITY", [tr("SETTINGS_GRAPHICS_LOW"), tr("SETTINGS_GRAPHICS_LOW")])), "Y lo muestra")
	_room.camera.set_zoom_index(0)
	_room.camera.snap_to_goal()
	await wait_process_frames(2)
	overlay.refresh()
	assert_true(_overlay_text(overlay).contains(UiFormat.tr_format("DEBUG_FAR", [tr("DEBUG_YES")])), "Con el zoom lejos, las impresoras lejanas")
	var more: Button = overlay.find_child("More", true, false)
	var quality_low: Button = overlay.find_child("Quality_low", true, false)
	more.pressed.emit()
	assert_false(quality_low.is_visible_in_tree(), "Con Menos, solo los números")
	assert_true(_overlay_text(overlay).contains(tr("DEBUG_YES")), "Que se siguen viendo")
	assert_eq(more.text, tr("DEBUG_MORE"))
	more.pressed.emit()
	assert_true(quality_low.is_visible_in_tree(), "Con Más vuelven los botones")
	(overlay.find_child("Close", true, false) as Button).pressed.emit()
	await wait_process_frames(1)
	assert_null(_hud.get_node_or_null("PerfOverlay"), "Se cierra con su botón")


## Probar el taller lleno o la noche no toca la partida del jugador: se
## guarda antes y después ya no se guarda nada (Game.trial).
func test_trying_scenes_never_touches_the_players_game() -> void:
	# Como en el juego: el guardado prendido (en un archivo de esta prueba).
	SaveManager.enabled = true
	await _load()
	var player_state: GameState = Game.state
	var saved: Dictionary = SaveCodec.encode(player_state)
	_hud.toggle_debug(_room, _main.get_node("WorldView"))
	var overlay: PerfOverlay = _hud.get_node("PerfOverlay")
	var trial_note: Label = overlay.find_children("*", "Label", true, false).filter(func(label: Label) -> bool: return label.text == tr("DEBUG_TRIAL"))[0]
	assert_false(trial_note.visible, "Sin probar nada, sin aviso")
	(overlay.find_child("Hour_night", true, false) as Button).pressed.emit()
	await wait_process_frames(2)
	assert_true(Game.trial, "Modo de prueba")
	assert_true(FileAccess.file_exists(SAVE_PATH), "Antes guardó la partida de verdad")
	var on_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	assert_eq(int(on_disk["state"]["game_seconds"]), player_state.game_seconds, "La de verdad, no la de prueba")
	assert_false(SaveManager.enabled, "Nada se guarda")
	assert_false(SaveManager.save_now(), "Ni pidiéndolo")
	assert_ne(Game.state, player_state, "En una copia de la partida")
	assert_eq(GameClock.hour(Game.state.game_minutes), 22, "Ya es de noche")
	assert_eq(SaveCodec.encode(player_state), saved, "La partida del jugador no cambió")
	assert_true(trial_note.visible, "Avisa que es una prueba")
	(overlay.find_child("Room_full", true, false) as Button).pressed.emit()
	await wait_process_frames(2)
	assert_eq(Game.state.printers.size(), 16, "El taller lleno")
	assert_eq(Game.level(), DebugTools.WORKSHOP_LEVEL, "En el nivel del taller")
	assert_not_null(_room.get_node_or_null("Printer%d" % Game.state.printers[15].uid), "El cuarto lo muestra")
	var working: int = 0
	for printer: OwnedPrinter in Game.state.printers:
		if printer.job != null:
			working += 1
	assert_eq(working, 12, "Con trabajos en cada estado")
	(overlay.find_child("Room_start", true, false) as Button).pressed.emit()
	await wait_process_frames(2)
	assert_eq(Game.state.printers.size(), 1, "De vuelta el cuarto del comienzo")
	assert_eq(SaveCodec.encode(player_state), saved, "La partida del jugador sigue igual")
	# Una partida nueva (Ajustes) es de verdad: la prueba termina y se guarda.
	Game.reset_game(SEED + 1)
	assert_false(Game.trial, "La partida nueva termina la prueba")
	assert_true(SaveManager.enabled, "Y se vuelve a guardar")
	assert_true(SaveManager.save_now(), "Ajustes la puede guardar")


## Al cerrar el panel sin salir de la prueba, el HUD lo sigue diciendo con
## el botón "Salir de la prueba" (antes no quedaba ninguna señal de que nada
## se guardaba). El botón vuelve a la partida del jugador, tal como estaba, y
## el guardado vuelve.
func test_leaving_a_trial_brings_back_the_players_game() -> void:
	SaveManager.enabled = true
	await _load()
	var player_state: GameState = Game.state
	var saved: Dictionary = SaveCodec.encode(player_state)
	var leave: Button = _hud.get_node("TrialBadge")
	assert_false(leave.visible, "Sin probar nada, sin botón")
	_hud.toggle_debug(_room, _main.get_node("WorldView"))
	var overlay: PerfOverlay = _hud.get_node("PerfOverlay")
	(overlay.find_child("Room_full", true, false) as Button).pressed.emit()
	(overlay.find_child("Close", true, false) as Button).pressed.emit()
	await wait_process_frames(2)
	assert_true(Game.trial, "Sigue probando con el panel cerrado")
	assert_true(leave.visible, "y lo dice")
	assert_eq(leave.text, tr("TRIAL_LEAVE"))
	assert_gte(leave.size.y, SettingsScreen.BUTTON_HEIGHT, "Del alto táctil mínimo")
	_hud.open_screen("shop")
	assert_false(leave.visible, "Sobre una sección no se ve (como el zoom)")
	_hud.open_screen("home")
	assert_true(leave.visible)
	leave.pressed.emit()
	await wait_process_frames(2)
	assert_false(Game.trial, "Salió de la prueba")
	assert_eq(Game.state, player_state, "Vuelve la partida del jugador")
	assert_eq(SaveCodec.encode(Game.state), saved, "Tal como estaba")
	assert_eq(_room.find_children("Printer*", "", false, false).size(), player_state.printers.size(), "El cuarto es el suyo")
	assert_true(SaveManager.enabled, "Y se vuelve a guardar")
	assert_false(leave.visible, "Sin el botón")


## Con el taller lleno, las horas lo vuelven a armar a esa hora con sus
## trabajos en cada estado (el de la captura 43): adelantar el reloj
## terminaba todas las impresiones y de noche ninguna imprimía.
func test_the_full_workshop_keeps_its_jobs_at_every_hour() -> void:
	await _load()
	_hud.toggle_debug(_room, _main.get_node("WorldView"))
	var overlay: PerfOverlay = _hud.get_node("PerfOverlay")
	(overlay.find_child("Room_full", true, false) as Button).pressed.emit()
	await wait_process_frames(2)
	var printing: int = _count_printing()
	assert_eq(printing, 4, "Cuatro imprimiendo")
	for hour: String in ["Hour_night", "Hour_golden", "Hour_morning"]:
		(overlay.find_child(hour, true, false) as Button).pressed.emit()
		await wait_process_frames(2)
		assert_eq(_count_printing(), printing, "%s: siguen imprimiendo" % hour)
		assert_eq(Game.state.printers.size(), 16, "%s: el taller lleno" % hour)
	assert_eq(GameClock.hour(Game.state.game_minutes), 8, "Ya es de mañana")
	(overlay.find_child("Room_start", true, false) as Button).pressed.emit()
	(overlay.find_child("Hour_night", true, false) as Button).pressed.emit()
	await wait_process_frames(2)
	assert_eq(Game.state.printers.size(), 1, "Con el cuarto del comienzo, la hora adelanta el reloj")
	assert_eq(GameClock.hour(Game.state.game_minutes), 22)


func _count_printing() -> int:
	var printing: int = 0
	for printer: OwnedPrinter in Game.state.printers:
		if printer.job != null and printer.job.status == PrintJob.Status.PRINTING:
			printing += 1
	return printing


func _load() -> void:
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	await wait_process_frames(3)
	_room = _main.get_node("WorldView/SubViewport/Room")
	_hud = _main.get_node("Hud")


func _remove_save() -> void:
	for suffix: String in ["", SaveManager.TMP_SUFFIX, SaveManager.BAD_SUFFIX]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH + suffix))


func _sun() -> DirectionalLight3D:
	return _room.get_node("Sun")


## Lo que muestra el mapa de oclusión del piso bajo el centro del escritorio.
func _floor_shade_under_desk() -> float:
	var desk: Rect2 = _room.item_for(WorldInteractable.Kind.FURNITURE, DESK_UID).footprint()
	var bounds: Rect2 = _room.grid.bounds
	var texel: Vector2i = Vector2i(((desk.get_center() - bounds.position) / bounds.size * FloorAO.TEXELS).floor())
	return _room.floor_ao.get_image().get_pixelv(texel).r


## Toques seguidos de verdad (como un dedo) en el centro de `control`.
func _tap(control: Control, count: int) -> void:
	var center: Vector2 = get_tree().root.get_final_transform() * control.get_global_rect().get_center()
	for i: int in count:
		for pressed: bool in [true, false]:
			var touch: InputEventScreenTouch = InputEventScreenTouch.new()
			touch.index = 0
			touch.pressed = pressed
			touch.position = center
			Input.parse_input_event(touch)
			await wait_process_frames(1)


func _overlay_text(overlay: PerfOverlay) -> String:
	overlay.refresh()
	return _labels_text(overlay)


func _settings_text(settings: Control) -> String:
	return _labels_text(settings)


func _labels_text(root: Node) -> String:
	var texts: PackedStringArray = PackedStringArray()
	for node: Node in root.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return "\n".join(texts)

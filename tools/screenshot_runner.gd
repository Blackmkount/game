extends Node
## Ejecutor de tools/screenshots.gd: arma la escena principal, la lleva por
## varias situaciones y guarda una captura de cada una.

const MAIN_SCENE: String = "res://game/scenes/main.tscn"

var _out: String = ""
var _main: Control
var _hud: Hud
var _controls: WorldControls
var _room: RoomView


func _init(out_dir: String) -> void:
	_out = out_dir


func _ready() -> void:
	# Ajustes en un archivo aparte, para que las pistas se vean siempre.
	UserSettings.path = "user://screenshots_settings.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(UserSettings.path))
	_run.call_deferred()


func _run() -> void:
	_main = load(MAIN_SCENE).instantiate()
	get_tree().root.add_child(_main)
	await _frames(30)
	_hud = _main.get_node("Hud")
	_controls = _main.get_node("WorldControls")
	_room = _main.get_node("WorldView/SubViewport/Room")

	await _capture("01_inicio")
	_room.camera.set_zoom_index(0)
	await _frames(40)
	await _capture("02_zoom_lejos")
	_room.camera.set_zoom_index(2)
	await _frames(40)
	await _capture("03_zoom_cerca")
	_room.camera.set_zoom_index(CameraRig.DEFAULT_ZOOM_INDEX)
	await _frames(30)

	# Joystick a mitad de un arrastre, caminando hacia la impresora.
	var printer: WorldInteractable = _first(WorldInteractable.Kind.PRINTER)
	var start: Vector2 = Vector2(360.0, 900.0)
	var direction: Vector2 = (_controls.world_to_ui(printer.top_center()) - _controls.world_to_ui(_room.character_focus_point())).normalized()
	_controls.tracker.press(0, start)
	_controls.tracker.drag(0, start + direction * 50.0)
	await _frames(6)
	await _capture("04_joystick")
	await _frames(40)
	_controls.tracker.release(0, start + direction * 50.0)
	await _frames(20)
	await _capture("05_cerca_de_la_impresora")

	_controls.open_sheet(printer)
	await _frames(30)
	await _capture("06_panel_impresora")
	_hud.close_sheet()
	await _frames(20)

	_controls.open_sheet(_first(WorldInteractable.Kind.FURNITURE))
	await _frames(30)
	await _capture("07_panel_computador")
	_controls.open_sheet(_first(WorldInteractable.Kind.SLOT))
	await _frames(30)
	await _capture("08_panel_lugar_libre")
	_controls.open_sheet(_first(WorldInteractable.Kind.DOOR))
	await _frames(30)
	await _capture("09_panel_puerta")
	_hud.close_sheet()
	await _frames(20)

	_hud.speech.say(TranslationServer.translate("CHARACTER_LINE_1"))
	await _frames(10)
	await _capture("10_globo_personaje")

	_hud.open_screen("shop", "furniture")
	await _frames(10)
	await _capture("11_tienda_muebles")
	_hud.open_screen("settings")
	await _frames(10)
	await _capture("12_ajustes")
	_hud.open_screen("home")
	get_tree().quit()


func _first(kind: WorldInteractable.Kind) -> WorldInteractable:
	for item: WorldInteractable in _room.interactables:
		if item.kind == kind:
			return item
	return null


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png(_out.path_join(file_name + ".png"))

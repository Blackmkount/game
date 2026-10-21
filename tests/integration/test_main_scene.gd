extends GutTest
## La escena principal arma la habitación inicial y la interfaz, y las
## secciones se abren y se cierran.

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")

var _main: Control
var _hud: Hud
var _room: Node3D
var _previous_locale: String


func before_each() -> void:
	_previous_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	await wait_process_frames(2)
	_hud = _main.get_node("Hud")
	_room = _main.get_node("WorldView/SubViewport/Room")


func after_each() -> void:
	TranslationServer.set_locale(_previous_locale)


func test_room_starts_with_table_printer_on_floor_and_character() -> void:
	assert_not_null(_room.get_node_or_null("Furniture%d" % Game.state.furniture[0].uid))
	assert_not_null(_room.get_node_or_null("Printer%d" % Game.state.printers[0].uid))
	assert_not_null(_room.get_node_or_null("Character"))
	var free_slots: Array[Node] = _room.find_children("FreeSlot*", "", false, false)
	assert_eq(free_slots.size(), 5, "La habitación tiene 6 lugares y la mesa ocupa uno")


func test_top_bar_shows_level_and_money() -> void:
	var labels: Array[String] = _label_texts(_hud.get_node("TopBar"))
	assert_has(labels, "Nivel 1")
	assert_has(labels, "$250")


func test_shop_lists_all_printers_and_furniture() -> void:
	_hud.open_screen("shop")
	var shop: ShopScreen = _hud.get_node("ScreenHost/Screen")
	assert_eq(_cards(shop).size(), (Game.catalog.files["printers"] as Array).size())
	shop.show_category("furniture")
	assert_eq(_cards(shop).size(), 6, "La mesa del computador no se vende")


func test_closing_a_screen_goes_back_home() -> void:
	_hud.open_screen("inventory")
	assert_not_null(_hud.get_node_or_null("ScreenHost/Screen"))
	_hud.open_screen("home")
	await wait_process_frames(1)
	assert_eq(_hud.current_screen_id(), "home")
	assert_null(_hud.get_node_or_null("ScreenHost/Screen"))


func test_every_screen_opens() -> void:
	for screen_id: String in ["workshop", "inventory", "shop", "profile", "orders", "tasks", "map", "settings"]:
		_hud.open_screen(screen_id)
		assert_not_null(_hud.get_node_or_null("ScreenHost/Screen"), screen_id)


func _cards(screen: ScreenBase) -> Array[Node]:
	return screen.content.get_children().filter(func(child: Node) -> bool: return child is ItemCard)


func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for node: Node in root.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return texts

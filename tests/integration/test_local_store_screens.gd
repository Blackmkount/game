extends GutTest
## La ferretería del barrio en la escena principal:
## - en Pedidos aparece en la línea de arriba solo cuando nadie pide algo que
##   se pueda hacer, y comprar ahí devuelve la cuenta regresiva;
## - en Inventario tiene su sección, y la pantalla muestra el carrete nuevo;
## - un botón que no se puede usar está deshabilitado con el motivo, y una
##   compra que falla lo dice en un aviso rojo.

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
const SEED: int = 1234

var _main: Control
var _hud: Hud
var _controls: WorldControls
var _previous_locale: String
var _previous_processing: bool


func before_each() -> void:
	_previous_processing = Game.is_processing()
	# La partida solo avanza cuando la prueba lo pide.
	Game.set_process(false)
	Game.reset_game(SEED)
	_previous_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	await wait_process_frames(2)
	_hud = _main.get_node("Hud")
	_controls = _main.get_node("WorldControls")


func after_each() -> void:
	TranslationServer.set_locale(_previous_locale)
	Game.set_process(_previous_processing)


func test_the_orders_header_offers_the_store_only_when_nothing_can_be_made() -> void:
	var screen: OrdersScreen = _open("orders")
	assert_string_starts_with(_header(screen), "Llega un mensaje nuevo en ")
	assert_null(screen.find_child("BuyLocal_pla", true, false), "Con material no hace falta")
	_empty_the_spool()
	await wait_process_frames(1)
	assert_eq(_header(screen), "Ahora nadie te pide algo que puedas hacer. Revisa tu material.")
	assert_eq(_label(screen, "LocalStoreTitle"), "Ferretería: al instante, 50% más cara")
	assert_eq(_button(screen, "BuyLocal_pla").text, "PLA · 1.000 g · $27")
	assert_eq(_button(screen, "BuyLocal_petg").text, "PETG · 1.000 g · $30")
	assert_false(_button(screen, "BuyLocal_pla").disabled)
	assert_null(screen.find_child("BuyLocalNote", true, false))


func test_buying_from_the_orders_header_brings_the_countdown_back() -> void:
	var screen: OrdersScreen = _open("orders")
	_empty_the_spool()
	await wait_process_frames(1)
	_button(screen, "BuyLocal_pla").pressed.emit()
	assert_eq(Game.state.money_cents, 25000 - 2700)
	assert_eq(Game.state.spools.size(), 2)
	assert_eq(Game.state.spools[1].material_id, "pla")
	assert_eq(_money_text(), "$223")
	await wait_process_frames(1)
	assert_string_starts_with(_header(screen), "Llega un mensaje nuevo en ")
	assert_null(screen.find_child("BuyLocal_pla", true, false), "La ferretería se va con el material")


func test_store_buttons_say_why_they_cannot_be_used() -> void:
	_empty_the_spool()
	Game.state.money_cents = 2800
	var screen: OrdersScreen = _open("orders")
	assert_false(_button(screen, "BuyLocal_pla").disabled, "$28 alcanzan para el PLA")
	assert_true(_button(screen, "BuyLocal_petg").disabled)
	assert_eq(_label(screen, "BuyLocalNote"), "Te falta dinero: cuesta $30.")
	# Solo cambia el dinero: los botones se revisan de nuevo.
	Game.state.money_cents = 100
	Events.money_changed.emit(100)
	await wait_process_frames(1)
	assert_true(_button(screen, "BuyLocal_pla").disabled)
	assert_eq(_label(screen, "BuyLocalNote"), "Te falta dinero: cuesta $27.\nTe falta dinero: cuesta $30.")


func test_the_inventory_sells_at_the_store_and_shows_the_new_spool() -> void:
	var screen: InventoryScreen = _open("inventory")
	assert_eq(_label(screen, "SectionLocalStore"), "Ferretería: al instante, 50% más cara")
	assert_does_not_have(_texts(screen), "PETG · Blanco")
	_button(screen, "BuyLocal_petg").pressed.emit()
	assert_eq(Game.state.money_cents, 25000 - 3000)
	await wait_process_frames(1)
	var texts: Array[String] = _texts(screen)
	assert_has(texts, "PETG · Blanco", "La pantalla se arma de nuevo con el carrete comprado")
	assert_has(texts, "2,0 / 4,0 kg")
	# Solo cambia el dinero: los botones se revisan de nuevo.
	Game.state.money_cents = 0
	Events.money_changed.emit(0)
	await wait_process_frames(1)
	assert_true(_button(screen, "BuyLocal_petg").disabled)
	assert_eq(_label(screen, "BuyLocalNote"), "Te falta dinero: cuesta $27.\nTe falta dinero: cuesta $30.")


func test_the_inventory_store_says_when_there_is_no_room() -> void:
	Game.state.spools[0].grams = 3500
	var screen: InventoryScreen = _open("inventory")
	assert_true(_button(screen, "BuyLocal_pla").disabled)
	assert_true(_button(screen, "BuyLocal_petg").disabled)
	assert_eq(_label(screen, "BuyLocalNote"), "No cabe: tu espacio guarda hasta 4.000 g.", "El mismo motivo se dice una vez")
	# Solo cambia el material (por ejemplo, una impresión aparta gramos).
	Game.state.spools[0].grams = 2000
	Events.spools_changed.emit()
	await wait_process_frames(1)
	assert_false(_button(screen, "BuyLocal_pla").disabled)
	assert_has(_texts(screen), "2.000 g")
	assert_null(screen.find_child("BuyLocalNote", true, false))


func test_a_purchase_that_fails_says_why() -> void:
	_controls.loop.run_local_store("tpu")
	var toast: Control = _hud.feedback.get_node("Toast")
	assert_true(toast.visible)
	assert_has(_texts(toast), "La ferretería no vende eso.")
	assert_eq(Game.state.spools.size(), 1)


## Sin material, nadie pide algo que se pueda hacer.
func _empty_the_spool() -> void:
	Game.state.spools[0].grams = 0
	Events.spools_changed.emit()


func _open(screen_id: String) -> ScreenBase:
	_hud.open_screen(screen_id)
	return _hud.get_node("ScreenHost/Screen")


func _header(screen: OrdersScreen) -> String:
	var header: Control = screen.find_child("HeaderLine", true, false)
	if not header.visible:
		return ""
	return _label(header, "HeaderText")


func _money_text() -> String:
	var pill: Control = _hud.get_node("TopBar").find_child("MoneyPill", true, false)
	return _texts(pill)[0]


func _button(root: Node, button_name: String) -> Button:
	var button: Button = root.find_child(button_name, true, false)
	assert_not_null(button, button_name)
	return button


func _label(root: Node, label_name: String) -> String:
	var label: Label = root.find_child(label_name, true, false)
	assert_not_null(label, label_name)
	return label.text if label != null else ""


func _texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for node: Node in root.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return texts

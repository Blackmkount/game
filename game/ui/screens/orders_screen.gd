class_name OrdersScreen
extends ScreenBase
## Pedidos, con estilo de chat: los mensajes nuevos de los clientes, los
## pedidos en curso con el paso en que van y lo último que se entregó. Arriba,
## cuándo llega el próximo mensaje, o por qué no llega; si es porque nadie pide
## algo que se pueda hacer, ahí mismo se puede comprar material en la
## ferretería.
##
## Se mantiene al día sola:
## - Se vuelve a armar (sin perder el desplazamiento) cuando cambian los
##   mensajes, los pedidos, las impresoras, el material, el dinero o el nivel.
##   Nunca dentro del botón que se tocó: al final del cuadro y una sola vez.
## - Con el reloj (una vez por segundo real) solo cambian las cuentas
##   regresivas y las barras.
##
## Los botones de las tarjetas avisan con card_action; el Hud lo reenvía y el
## ciclo de pedidos (OrderLoopController) corre el comando. Lo mismo con los
## botones de la ferretería (local_store_requested).

## Botón de una tarjeta: `verb` es "accept" o "reject" (uid del mensaje), o
## "cancel", "focus", "print", "see_printer", "remove", "pack" o "dispatch"
## (uid del pedido). Hud lo reenvía como order_card_action.
signal card_action(verb: String, uid: int)
## Se tocó comprar un carrete en la ferretería. Hud lo reenvía.
signal local_store_requested(material_id: String)

## Segundos que "Cancelar pedido" espera el segundo toque que confirma.
const CANCEL_CONFIRM_SECONDS: float = 3.0

## Qué dice la línea de arriba (la primera que corresponde gana).
enum Header { HIDDEN, BOARD_FULL, NONE_MAKEABLE, NEXT_OFFER }

var _header: PanelContainer
var _header_label: Label
## Debajo del texto de arriba: la ferretería, cuando nada se puede hacer.
var _store_box: VBoxContainer
var _header_mode: Header = Header.HIDDEN
var _order_cards: Array[OrderCard] = []
## Pedido con el primer toque de "Cancelar pedido" hecho, o -1.
var _cancel_uid: int = -1
var _cancel_timer: Timer


func _init() -> void:
	super("chat", "SCREEN_ORDERS")
	_cancel_timer = Timer.new()
	_cancel_timer.name = "CancelTimer"
	_cancel_timer.one_shot = true
	_cancel_timer.timeout.connect(_set_cancel_uid.bind(-1))
	add_child(_cancel_timer)


func _ready() -> void:
	super()
	Events.offers_changed.connect(queue_rebuild)
	Events.order_changed.connect(queue_rebuild.unbind(1))
	Events.order_removed.connect(queue_rebuild.unbind(1))
	Events.printer_changed.connect(queue_rebuild.unbind(1))
	Events.spools_changed.connect(queue_rebuild)
	Events.money_changed.connect(queue_rebuild.unbind(1))
	Events.level_up.connect(queue_rebuild.unbind(1))
	Events.game_loaded.connect(queue_rebuild)
	Events.clock_ticked.connect(_on_clock_ticked)


func _build_header(column: VBoxContainer) -> void:
	_header = UiKit.panel("ActivePanel")
	_header.name = "HeaderLine"
	var row: HBoxContainer = UiKit.hbox(10)
	_header.add_child(row)
	var star: TextureRect = UiKit.icon("star", 28, UiPalette.GOLD)
	star.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(star)
	var lines: VBoxContainer = UiKit.vbox(10)
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lines)
	_header_label = UiKit.label("", "MutedLabel", true)
	_header_label.name = "HeaderText"
	lines.add_child(_header_label)
	_store_box = UiKit.vbox(8)
	_store_box.name = "LocalStoreBox"
	lines.add_child(_store_box)
	column.add_child(_header)


func _build_content() -> void:
	_order_cards.clear()
	var state: GameState = Game.state
	if state == null:
		_header.visible = false
		return
	var rules: SimRules = Game.rules
	_refresh_header(state, rules)
	if not state.offers.is_empty():
		add_heading(UiFormat.tr_format("ORDERS_SECTION_NEW", [state.offers.size()])).name = "SectionNew"
		for offer: OrderOffer in state.offers:
			var offer_card: OfferCard = OfferCard.new(offer)
			offer_card.card_action.connect(card_action.emit)
			content.add_child(offer_card)
	add_heading(UiFormat.tr_format("ORDERS_SECTION_ACTIVE", [state.orders.size(), rules.max_active_orders])).name = "SectionActive"
	if state.orders.is_empty():
		content.add_child(UiKit.label(tr("ORDERS_NO_ACTIVE"), "MutedLabel", true))
	for order: Order in state.orders:
		var order_card: OrderCard = OrderCard.new(order, order.uid == _cancel_uid)
		order_card.card_action.connect(card_action.emit)
		order_card.cancel_tapped.connect(_on_cancel_tapped)
		content.add_child(order_card)
		_order_cards.append(order_card)
	if not state.recent_deliveries.is_empty():
		add_heading(tr("ORDERS_SECTION_DONE")).name = "SectionDone"
		for delivery: Delivery in state.recent_deliveries:
			content.add_child(_delivery_card(rules, delivery))
	var locked: int = 0
	var level: int = OrderQueries.level(state, rules)
	for order_id: String in rules.order_list:
		if int(rules.orders[order_id]["min_level"]) > level:
			locked += 1
	if locked > 0:
		content.add_child(UiKit.label(UiFormat.tr_format("ORDERS_LOCKED_MORE", [locked]), "MutedLabel", true))


## La línea de arriba: tablero lleno, nada que se pueda hacer, o cuánto falta
## para el próximo mensaje (esta última es la única que cuenta hacia atrás).
func _refresh_header(state: GameState, rules: SimRules) -> void:
	if state.offers.size() >= rules.board_slots:
		_header_mode = Header.BOARD_FULL
	elif not OrderBoard.has_makeable(state, rules):
		_header_mode = Header.NONE_MAKEABLE
	elif OrderQueries.seconds_to_next_offer(state) >= 0:
		_header_mode = Header.NEXT_OFFER
	else:
		_header_mode = Header.HIDDEN
	_header.visible = _header_mode != Header.HIDDEN
	match _header_mode:
		Header.BOARD_FULL:
			_header_label.text = tr("ORDERS_BOARD_FULL")
		Header.NONE_MAKEABLE:
			_header_label.text = tr("ORDERS_NONE_MAKEABLE")
		Header.NEXT_OFFER:
			_header_label.text = _next_offer_text(state, rules)
	_refresh_local_store(rules)


## Si nadie pide algo que se pueda hacer, la ferretería: material al instante.
func _refresh_local_store(rules: SimRules) -> void:
	for child: Node in _store_box.get_children():
		_store_box.remove_child(child)
		child.queue_free()
	_store_box.visible = _header_mode == Header.NONE_MAKEABLE
	if not _store_box.visible:
		return
	var store_title: Label = UiKit.label(LocalStoreButtons.title(rules), "SmallLabel", true)
	store_title.name = "LocalStoreTitle"
	_store_box.add_child(store_title)
	var buttons: LocalStoreButtons = LocalStoreButtons.new()
	buttons.buy_requested.connect(local_store_requested.emit)
	_store_box.add_child(buttons)


func _next_offer_text(state: GameState, rules: SimRules) -> String:
	var wait: String = UiFormat.real_duration(OrderQueries.seconds_to_next_offer(state), rules.game_seconds_per_real_second)
	return UiFormat.tr_format("ORDERS_NEXT_OFFER", [wait])


## Un pedido entregado: nombre, lo cobrado y la experiencia, y el
## agradecimiento del cliente.
func _delivery_card(rules: SimRules, delivery: Delivery) -> Control:
	var definition: Dictionary = rules.orders[delivery.order_id]
	var card: PanelContainer = UiKit.panel("CardPanel")
	card.name = "Delivered_%d" % delivery.order_uid
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var row: HBoxContainer = UiKit.hbox(12)
	card.add_child(row)
	var check: TextureRect = UiKit.icon("check", 32, UiPalette.XP_FILL)
	check.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(check)
	var column: VBoxContainer = UiKit.vbox(4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	column.add_child(UiKit.label(UiFormat.tr_format("ORDERS_DELIVERED_LINE", [
		tr(definition["name_key"]), UiFormat.money(delivery.cents), delivery.xp,
	]), "BoldLabel", true))
	var client: String = tr(rules.clients[definition["client"]]["name_key"])
	column.add_child(UiKit.label(UiFormat.tr_format("FEEDBACK_THANKS", [client, tr(delivery.thanks_key)]), "MutedLabel", true))
	return card


## Una vez por segundo real: solo las cuentas regresivas y las barras.
func _on_clock_ticked(game_seconds: int) -> void:
	if Game.state == null:
		return
	if _header_mode == Header.NEXT_OFFER:
		_header_label.text = _next_offer_text(Game.state, Game.rules)
	for card: OrderCard in _order_cards:
		card.tick(game_seconds)


## Primer toque: pide confirmar durante CANCEL_CONFIRM_SECONDS. Segundo toque
## del mismo pedido: lo cancela.
func _on_cancel_tapped(uid: int) -> void:
	if uid == _cancel_uid and not _cancel_timer.is_stopped():
		_cancel_timer.stop()
		_set_cancel_uid(-1)
		card_action.emit("cancel", uid)
		return
	_set_cancel_uid(uid)
	_cancel_timer.start(CANCEL_CONFIRM_SECONDS)


func _set_cancel_uid(uid: int) -> void:
	_cancel_uid = uid
	for card: OrderCard in _order_cards:
		card.set_confirming(card.uid == uid)

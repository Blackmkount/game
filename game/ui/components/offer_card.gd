class_name OfferCard
extends PanelContainer
## Tarjeta de un mensaje sin responder, con estilo de chat: quién escribe y
## cuándo, el globo con lo que pide, el pedido con sus datos, cuánto tarda y
## cuánto deja, y los botones Rechazar y Aceptar.
##
## Aceptar se deshabilita con el motivo debajo cuando no se puede
## (OrderBoard.check_accept, la misma revisión que hace el comando).

## Botón de la tarjeta: "accept" o "reject", con el uid del mensaje.
signal card_action(verb: String, uid: int)

const AVATAR_SIZE: float = 56.0
const CHIP_ICON_SIZE: float = 24.0
const BUTTON_HEIGHT: float = 72.0

var _offer: OrderOffer


func _init(offer: OrderOffer) -> void:
	_offer = offer
	name = "Offer_%d" % offer.uid
	theme_type_variation = "CardPanel"
	# Deja pasar el arrastre a la lista, para poder desplazarla desde la tarjeta.
	mouse_filter = Control.MOUSE_FILTER_PASS


func _ready() -> void:
	var rules: SimRules = Game.rules
	var order_id: String = _offer.order_id
	var order: Dictionary = rules.orders[order_id]
	var column: VBoxContainer = UiKit.vbox(10)
	add_child(column)
	column.add_child(_header(rules, order))
	var bubble: PanelContainer = UiKit.panel("BubblePanel")
	bubble.name = "Ask"
	bubble.mouse_filter = Control.MOUSE_FILTER_PASS
	bubble.add_child(UiKit.label(tr(order["ask_key"]), "BubbleLabel", true))
	column.add_child(bubble)
	column.add_child(UiKit.label(tr(order["name_key"]), "BoldLabel", true))
	column.add_child(_chips(rules, order_id, order))
	var rate: int = rules.game_seconds_per_real_second
	var plan: PrintPlan = PrintPlanner.estimate_for_offer(Game.state, rules, order_id)
	var estimate: String = UiFormat.tr_format("ORDERS_ESTIMATE", [
		UiFormat.real_duration(rules.design_seconds[order_id], rate),
		UiFormat.real_duration(plan.total_seconds, rate),
	])
	column.add_child(UiKit.label(estimate, "MutedLabel", true))
	column.add_child(_reward(rules, order_id, order, plan))
	_add_buttons(column)


## Avatar del cliente con su color, su nombre y la hora del mensaje.
func _header(rules: SimRules, order: Dictionary) -> Control:
	var row: HBoxContainer = UiKit.hbox(12)
	var client_id: String = order["client"]
	var avatar: PanelContainer = UiKit.icon_tile("user", AVATAR_SIZE, ClientStyle.color(client_id))
	avatar.name = "Avatar"
	avatar.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(avatar)
	var client: Label = UiKit.label(tr(rules.clients[client_id]["name_key"]), "BoldLabel", true)
	client.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(client)
	var arrived: Label = UiKit.label(UiFormat.date(_offer.arrived_at / float(GameClock.SECONDS_PER_MINUTE)), "SmallLabel")
	arrived.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(arrived)
	return row


## Datos del pedido en píldoras con icono y texto (nunca solo color): tamaño,
## calidad, materiales, piezas, plazo y, si corresponde, multicolor.
func _chips(rules: SimRules, order_id: String, order: Dictionary) -> Control:
	var flow: HFlowContainer = HFlowContainer.new()
	flow.name = "Chips"
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow.add_child(_chip("box", UiFormat.tr_format("ORDERS_SIZE", [order["size"]])))
	flow.add_child(_chip("star", UiFormat.tr_format("ORDERS_QUALITY", [int(order["min_quality"])])))
	var materials: Array[String] = []
	for material_id: String in order["materials"]:
		materials.append(tr(rules.materials[material_id]["name_key"]))
	flow.add_child(_chip("spool", "/".join(materials)))
	var pieces: int = int(order["pieces"])
	flow.add_child(_chip("printer", UiFormat.tr_format("ORDERS_PIECES" if pieces > 1 else "ORDERS_PIECE", [pieces])))
	var deadline: int = rules.deadline_seconds[order_id]
	if deadline > 0:
		var days: String = UiFormat.tr_format("FORMAT_DAYS", [ceili(float(deadline) / GameClock.SECONDS_PER_DAY)])
		flow.add_child(_chip("calendar", UiFormat.tr_format("ORDERS_DEADLINE_DAYS", [days])))
	else:
		flow.add_child(_chip("calendar", tr("ORDERS_NO_DEADLINE")))
	if order["multicolor"]:
		flow.add_child(_chip("star", tr("ORDERS_MULTICOLOR")))
	return flow


func _chip(icon_name: String, text: String) -> Control:
	var pill: PanelContainer = UiKit.panel("PillPanel")
	pill.mouse_filter = Control.MOUSE_FILTER_PASS
	var row: HBoxContainer = UiKit.hbox(6)
	pill.add_child(row)
	row.add_child(UiKit.icon(icon_name, CHIP_ICON_SIZE, UiPalette.ACCENT))
	var label: Label = UiKit.label(text, "SmallLabel")
	label.add_theme_color_override("font_color", UiPalette.TEXT)
	row.add_child(label)
	return pill


## Lo que paga, la experiencia y la ganancia estimada (pago menos material).
func _reward(rules: SimRules, order_id: String, order: Dictionary, plan: PrintPlan) -> Control:
	var payment: int = rules.payment_cents[order_id]
	var row: HBoxContainer = UiKit.hbox(8)
	row.add_child(UiKit.icon("coin", CHIP_ICON_SIZE, Color.WHITE))
	var text: String = UiFormat.tr_format("ORDERS_REWARD", [
		UiFormat.money(payment), int(order["xp"]), UiFormat.money(payment - plan.cost_cents),
	])
	var label: Label = UiKit.label(text, "BoldLabel", true)
	label.name = "Reward"
	row.add_child(label)
	return row


func _add_buttons(column: VBoxContainer) -> void:
	var row: HBoxContainer = UiKit.hbox(10)
	column.add_child(row)
	row.add_child(_button("Reject_%d" % _offer.uid, tr("ORDERS_REJECT"), "Button", "reject"))
	var accept: Button = _button("Accept_%d" % _offer.uid, tr("ORDERS_ACCEPT"), "PrimaryButton", "accept")
	row.add_child(accept)
	var check: CommandResult = OrderBoard.check_accept(Game.state, Game.rules, _offer.uid)
	if not check.ok:
		accept.disabled = true
		var note: Label = UiKit.label(UiFormat.reason(check, Game.rules.game_seconds_per_real_second), "MutedLabel", true)
		note.name = "AcceptNote_%d" % _offer.uid
		column.add_child(note)


func _button(node_name: String, text: String, variation: String, verb: String) -> Button:
	var button: Button = Button.new()
	button.name = node_name
	button.text = text
	button.theme_type_variation = variation
	button.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: card_action.emit(verb, _offer.uid))
	return button

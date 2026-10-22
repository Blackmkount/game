class_name OrdersScreen
extends ScreenBase
## Pedidos: por ahora muestra los pedidos disponibles para el nivel actual.
## El tablero con pedidos que llegan y se aceptan es la tarea 4 de la Fase 1.

## Botón de una tarjeta: `verb` es "accept" o "reject" (uid del mensaje), o
## "cancel", "focus", "print", "see_printer", "remove", "pack" o "dispatch"
## (uid del pedido). Hud lo reenvía como order_card_action.
signal card_action(verb: String, uid: int)


func _init() -> void:
	super("chat", "SCREEN_ORDERS")


func _build_header(column: VBoxContainer) -> void:
	add_notice(column, "ORDERS_COMING_SOON")


func _build_content() -> void:
	var clients: Dictionary = DataLookup.by_id(Game.catalog, "clients")
	var materials: Dictionary = DataLookup.by_id(Game.catalog, "materials")
	var locked: int = 0
	for order: Dictionary in Game.catalog.files["orders"]:
		if int(order["min_level"]) > Game.level():
			locked += 1
			continue
		var material_names: Array[String] = []
		for material_id: String in order["materials"]:
			material_names.append(tr(materials[material_id]["name_key"]))
		var pieces: int = int(order["pieces"])
		var details: String = "%s\n%s · %s · %s" % [
			tr(clients[order["client"]]["name_key"]),
			UiFormat.tr_format("ORDERS_PIECES" if pieces > 1 else "ORDERS_PIECE", [pieces]),
			UiFormat.duration(float(order["minutes_per_piece"])),
			", ".join(material_names),
		]
		var card: ItemCard = ItemCard.new(Previews.icon("chat"), tr(order["name_key"]), details)
		content.add_child(card)
		card.add_price(int(round(float(order["payment"]) * 100.0)))
		card.add_right_label(UiFormat.tr_format("FORMAT_XP_REWARD", [int(order["xp"])]), "BoldLabel").add_theme_color_override("font_color", UiPalette.XP_FILL)
	if locked > 0:
		content.add_child(UiKit.label(UiFormat.tr_format("ORDERS_LOCKED_MORE", [locked]), "MutedLabel", true))

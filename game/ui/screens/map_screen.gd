class_name MapScreen
extends ScreenBase
## Mapa: los espacios del juego, cuál es el actual y qué hace falta para
## mudarse a los demás.


func _init() -> void:
	super("map", "SCREEN_MAP")


func _build_content() -> void:
	for space: Dictionary in Game.catalog.files["spaces"]:
		var current: bool = space["id"] == Game.state.space_id
		var details: String = UiFormat.tr_format("MAP_SLOTS", [int(space["floor_slots"])])
		var card: ItemCard = ItemCard.new(Previews.icon("home" if current else "map", UiPalette.ACCENT if current else UiPalette.TEXT_MUTED), tr(space["name_key"]), details)
		content.add_child(card)
		if current:
			card.add_right_label(tr("MAP_YOU_ARE_HERE"), "BoldLabel").add_theme_color_override("font_color", UiPalette.ACCENT)
		else:
			card.add_price(int(round(float(space["price"]) * 100.0)))
			if int(space["unlock_level"]) > Game.level():
				card.right.add_child(UiKit.lock_tag(int(space["unlock_level"])))

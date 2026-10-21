class_name BottomNav
extends PanelContainer
## Barra inferior con las cinco secciones principales. La activa se resalta
## con borde y brillo cian.

signal tab_selected(tab_id: String)

const TABS: Array[Dictionary] = [
	{"id": "home", "icon": "home", "text": "NAV_HOME"},
	{"id": "workshop", "icon": "wrench", "text": "NAV_WORKSHOP"},
	{"id": "inventory", "icon": "box", "text": "NAV_INVENTORY"},
	{"id": "shop", "icon": "cart", "text": "NAV_SHOP"},
	{"id": "profile", "icon": "user", "text": "NAV_PROFILE"},
]

var _buttons: Dictionary[String, Button] = {}


func _ready() -> void:
	var row: HBoxContainer = UiKit.hbox(6)
	add_child(row)
	for tab: Dictionary in TABS:
		var button: Button = Button.new()
		button.name = tab["id"]
		button.icon = UiKit.icon_texture(tab["icon"])
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.add_theme_constant_override("icon_max_width", 44)
		button.custom_minimum_size = Vector2(0, 96)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void: tab_selected.emit(tab["id"]))
		row.add_child(button)
		_buttons[tab["id"]] = button
	_update_texts()
	set_active("home")


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and not _buttons.is_empty():
		_update_texts()


## Resalta la pestaña con ese id; con "" no resalta ninguna.
func set_active(tab_id: String) -> void:
	for id: String in _buttons:
		var active: bool = id == tab_id
		_buttons[id].theme_type_variation = "NavButtonActive" if active else "NavButton"
		_buttons[id].modulate = UiPalette.ACCENT.lerp(Color.WHITE, 0.35) if active else Color.WHITE


func _update_texts() -> void:
	for tab: Dictionary in TABS:
		_buttons[tab["id"]].text = tr(tab["text"])

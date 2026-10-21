class_name SideButton
extends Button
## Botón cuadrado con icono arriba y texto abajo (columna izquierda del HUD),
## con una burbuja roja opcional para avisos.

var _text_key: String
var _badge: PanelContainer
var _badge_label: Label


func _init(icon_name: String, text_key: String) -> void:
	_text_key = text_key
	icon = UiKit.icon_texture(icon_name)
	theme_type_variation = "IconButton"
	custom_minimum_size = Vector2(108, 104)
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	expand_icon = false
	add_theme_constant_override("icon_max_width", 44)
	add_theme_font_size_override("font_size", 19)
	focus_mode = Control.FOCUS_NONE


func _ready() -> void:
	text = tr(_text_key)
	_badge = UiKit.panel("BadgePanel")
	_badge.custom_minimum_size = Vector2(30, 30)
	_badge.position = Vector2(84, -10)
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge_label = UiKit.label("", "BadgeLabel")
	_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge.add_child(_badge_label)
	add_child(_badge)
	_badge.visible = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		text = tr(_text_key)


func set_badge(count: int) -> void:
	_badge.visible = count > 0
	_badge_label.text = str(count)

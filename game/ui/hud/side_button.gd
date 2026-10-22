class_name SideButton
extends Button
## Botón cuadrado con icono arriba y texto abajo (columna izquierda del HUD),
## con una burbuja roja opcional para avisos. Cuando el número sube, la
## burbuja da un saltito.

const POP_SCALE: float = 1.3
const POP_TIME: float = 0.2

var _text_key: String
var _badge: PanelContainer
var _badge_label: Label
var _count: int = 0
var _pop: Tween


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
	var grew: bool = count > _count
	_count = count
	_badge.visible = count > 0
	_badge_label.text = str(count)
	if grew and is_inside_tree():
		_pop_badge()


func _pop_badge() -> void:
	if _pop != null:
		_pop.kill()
	_badge.pivot_offset = _badge.get_combined_minimum_size() / 2.0
	_badge.scale = Vector2.ONE * POP_SCALE
	_pop = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pop.tween_property(_badge, "scale", Vector2.ONE, POP_TIME)

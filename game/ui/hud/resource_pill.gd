class_name ResourcePill
extends PanelContainer
## Píldora con un icono y un valor (dinero, fecha).

const BUMP_SCALE: float = 1.15
const BUMP_TIME: float = 0.2

var _label: Label
var _icon_name: String
var _icon_color: Color
var _bump: Tween


func _init(icon_name: String, icon_color: Color = UiPalette.TEXT) -> void:
	_icon_name = icon_name
	_icon_color = icon_color
	theme_type_variation = "PillPanel"


func _ready() -> void:
	var row: HBoxContainer = UiKit.hbox(8)
	add_child(row)
	row.add_child(UiKit.icon(_icon_name, 30, _icon_color))
	_label = UiKit.label("", "BoldLabel")
	row.add_child(_label)


func set_value(text: String) -> void:
	_label.text = text


## Pequeño salto, por ejemplo cuando llega un cobro.
func bump() -> void:
	if _bump != null:
		_bump.kill()
	pivot_offset = size / 2.0
	scale = Vector2.ONE * BUMP_SCALE
	_bump = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_bump.tween_property(self, "scale", Vector2.ONE, BUMP_TIME)

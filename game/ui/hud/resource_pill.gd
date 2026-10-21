class_name ResourcePill
extends PanelContainer
## Píldora con un icono y un valor (dinero, fecha).

var _label: Label
var _icon_name: String
var _icon_color: Color


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

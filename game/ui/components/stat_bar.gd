class_name StatBar
extends PanelContainer
## Tarjeta con un título, un valor a la derecha y una barra de avance.

var _title: String
var _value_text: String
var _value: float
var _max_value: float


func _init(title: String, value_text: String, value: float, max_value: float) -> void:
	_title = title
	_value_text = value_text
	_value = value
	_max_value = max_value
	theme_type_variation = "CardPanel"


func _ready() -> void:
	var column: VBoxContainer = UiKit.vbox(8)
	add_child(column)
	var row: HBoxContainer = UiKit.hbox(8)
	column.add_child(row)
	var title: Label = UiKit.label(_title, "BoldLabel")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	row.add_child(UiKit.label(_value_text, "MutedLabel"))
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	bar.max_value = maxf(_max_value, 1.0)
	bar.value = _value
	column.add_child(bar)

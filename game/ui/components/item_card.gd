class_name ItemCard
extends PanelContainer
## Tarjeta de un artículo: vista (icono o modelo 3D), título, descripción y
## una columna derecha con precio, estado o botón.

## Columna derecha; existe después de agregar la tarjeta al árbol.
var right: VBoxContainer

var _preview: Control
var _title: String
var _subtitle: String


func _init(preview: Control, title: String, subtitle: String) -> void:
	_preview = preview
	_title = title
	_subtitle = subtitle
	theme_type_variation = "CardPanel"


func _ready() -> void:
	var row: HBoxContainer = UiKit.hbox(12)
	add_child(row)
	row.add_child(_preview)
	var info: VBoxContainer = UiKit.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)
	info.add_child(UiKit.label(_title, "BoldLabel", true))
	if not _subtitle.is_empty():
		info.add_child(UiKit.label(_subtitle, "SmallLabel", true))
	right = UiKit.vbox(6)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(right)


## Precio con moneda.
func add_price(cents: int) -> void:
	var price: HBoxContainer = UiKit.hbox(4)
	price.alignment = BoxContainer.ALIGNMENT_END
	price.add_child(UiKit.icon("coin", 24, Color.WHITE))
	price.add_child(UiKit.label(UiFormat.money(cents), "BoldLabel"))
	right.add_child(price)


func add_right_label(text: String, variation: String = "SmallLabel") -> Label:
	var label: Label = UiKit.label(text, variation)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(label)
	return label

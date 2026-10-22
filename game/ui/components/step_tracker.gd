class_name StepTracker
extends HBoxContainer
## Los 6 pasos de un pedido en fila (mensaje, modelar, imprimir, retirar,
## embalar y despachar) y el nombre del paso actual: "Paso 2 de 6: Modelar".
## Los pasos hechos van en verde, el actual en cian y los que faltan
## apagados. El texto dice lo mismo, así no depende solo del color.

const ICONS: Array[String] = ["chat", "design", "printer", "check", "box", "truck"]
const NAME_KEYS: Array[String] = ["STEP_CONFIRM", "STEP_DESIGN", "STEP_PRINT", "STEP_REMOVE", "STEP_PACK", "STEP_DISPATCH"]
const TILE_SIZE: float = 32.0

## Paso actual, de 1 a 6.
var step: int


func _init(p_step: int) -> void:
	step = clampi(p_step, 1, ICONS.size())
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	for index: int in ICONS.size():
		var tile: PanelContainer = UiKit.icon_tile(ICONS[index], TILE_SIZE, color_for(index + 1, step))
		tile.name = "Step%d" % (index + 1)
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tile)
	var label: Label = UiKit.label(UiFormat.tr_format("STEP_NOW", [step, tr(NAME_KEYS[step - 1])]), "SmallLabel", true)
	label.name = "StepName"
	label.add_theme_color_override("font_color", UiPalette.TEXT)
	add_child(label)


## Icono del paso (1 a 6).
static func icon_for(p_step: int) -> String:
	return ICONS[clampi(p_step, 1, ICONS.size()) - 1]


## Color del paso `index` cuando el pedido va en el paso `current`.
static func color_for(index: int, current: int) -> Color:
	if index < current:
		return UiPalette.XP_FILL
	if index == current:
		return UiPalette.ACCENT
	return UiPalette.TEXT_MUTED

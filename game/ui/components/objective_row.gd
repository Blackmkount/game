class_name ObjectiveRow
extends HBoxContainer
## Una fila de objetivo: casilla, texto y avance "(0/3)". En modo detallado
## también muestra la recompensa.

var _objective: Dictionary
var _progress: int
var _compact: bool


func _init(objective: Dictionary, progress: int, compact: bool) -> void:
	_objective = objective
	_progress = progress
	_compact = compact
	add_theme_constant_override("separation", 10)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	var done: bool = _progress >= int(_objective["count"])
	var box: PanelContainer = UiKit.panel("ActivePanel" if done else "IconTile")
	box.custom_minimum_size = Vector2(28, 28)
	box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if done:
		box.add_child(UiKit.icon("check", 20, UiPalette.XP_FILL))
	add_child(box)
	var text: String = "%s (%d/%d)" % [tr(_objective["name_key"]), _progress, int(_objective["count"])]
	var column: VBoxContainer = UiKit.vbox(2)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(column)
	var label: Label = UiKit.label(text, "" if not _compact else "MutedLabel", true)
	if _compact:
		label.add_theme_color_override("font_color", UiPalette.TEXT)
	column.add_child(label)
	if not _compact:
		column.add_child(UiKit.label(_reward_text(), "SmallLabel"))


func _reward_text() -> String:
	var parts: Array[String] = []
	if float(_objective["reward_money"]) > 0.0:
		parts.append(UiFormat.money(int(float(_objective["reward_money"]) * 100.0)))
	if int(_objective["reward_xp"]) > 0:
		parts.append(UiFormat.tr_format("FORMAT_XP_REWARD", [int(_objective["reward_xp"])]))
	return UiFormat.tr_format("TASKS_REWARD", [" · ".join(parts)])

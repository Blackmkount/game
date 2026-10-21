class_name ProfileCard
extends PanelContainer
## Tarjeta superior izquierda: retrato del personaje, nivel y barra de
## experiencia hacia el siguiente nivel.

var _level_label: Label
var _xp_bar: ProgressBar
var _xp_label: Label


func _ready() -> void:
	var row: HBoxContainer = UiKit.hbox(12)
	add_child(row)
	var frame: PanelContainer = UiKit.panel("IconTile")
	frame.custom_minimum_size = Vector2(84, 84)
	frame.add_child(ModelPreview.new(func(world: Node3D) -> void: CharacterModel.build(world, "Character"), 76.0, 0.62, Vector3(0.0, 0.98, 0.0), 20.0))
	row.add_child(frame)
	var info: VBoxContainer = UiKit.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)
	_level_label = UiKit.label("", "BoldLabel")
	_level_label.add_theme_font_size_override("font_size", 28)
	info.add_child(_level_label)
	_xp_bar = UiKit.xp_bar(0.0, 1.0)
	info.add_child(_xp_bar)
	_xp_label = UiKit.label("", "SmallLabel")
	info.add_child(_xp_label)
	refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _level_label != null:
		refresh()


func refresh() -> void:
	if Game.state == null:
		return
	var xp: int = Game.state.xp
	_level_label.text = UiFormat.tr_format("HUD_LEVEL", [Game.level()])
	var span: int = Game.levels.xp_span_of_level(xp)
	var into: int = Game.levels.xp_into_level(xp)
	_xp_bar.max_value = maxi(span, 1)
	_xp_bar.value = into if span > 0 else 1
	if span > 0:
		_xp_label.text = UiFormat.tr_format("HUD_XP", [UiFormat.number(into), UiFormat.number(span)])
	else:
		_xp_label.text = tr("HUD_XP_MAX")

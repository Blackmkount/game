class_name ObjectivesPanel
extends PanelContainer
## Panel "Objetivos": muestra los próximos objetivos sin completar, con su
## avance. Al tocarlo se abre la lista completa. Hud lo refresca cuando se
## entrega un pedido.

signal pressed

const VISIBLE_OBJECTIVES: int = 2

var _list: VBoxContainer
var _title: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column: VBoxContainer = UiKit.vbox(8)
	add_child(column)
	var header: HBoxContainer = UiKit.hbox(8)
	column.add_child(header)
	header.add_child(UiKit.icon("tasks", 28, UiPalette.GOLD))
	_title = UiKit.label("", "BoldLabel")
	header.add_child(_title)
	column.add_child(HSeparator.new())
	_list = UiKit.vbox(8)
	column.add_child(_list)
	refresh()


func _gui_input(event: InputEvent) -> void:
	# Los toques en pantalla llegan también como clics del ratón.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _list != null:
		refresh()


func refresh() -> void:
	_title.text = tr("HUD_OBJECTIVES")
	for child: Node in _list.get_children():
		child.queue_free()
	if Game.state == null:
		return
	var shown: int = 0
	for objective: Dictionary in Game.catalog.files["objectives"]:
		if shown >= VISIBLE_OBJECTIVES:
			break
		_list.add_child(ObjectiveRow.new(objective, ObjectiveProgress.progress(objective, Game.state), true))
		shown += 1

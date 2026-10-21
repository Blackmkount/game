class_name TasksScreen
extends ScreenBase
## Tareas: la lista completa de objetivos con su avance y recompensa.


func _init() -> void:
	super("tasks", "SCREEN_TASKS")


func _build_header(column: VBoxContainer) -> void:
	column.add_child(UiKit.label(tr("TASKS_INTRO"), "MutedLabel", true))


func _build_content() -> void:
	for objective: Dictionary in Game.catalog.files["objectives"]:
		var card: PanelContainer = UiKit.panel("CardPanel")
		card.add_child(ObjectiveRow.new(objective, 0, false))
		content.add_child(card)

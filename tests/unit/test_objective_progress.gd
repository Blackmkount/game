extends GutTest
## Avance de los objetivos según la partida (ObjectiveProgress) y cómo lo
## muestra cada fila (ObjectiveRow): nunca pasa de la meta y, al llegar, dice
## "premio pronto" sin marcar la casilla.

var _objectives: Dictionary
var _state: GameState
var _previous_locale: String


func before_each() -> void:
	_objectives = DataLookup.by_id(DataCatalog.load_from(), "objectives")
	_state = GameState.new()
	_previous_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("es")


func after_each() -> void:
	TranslationServer.set_locale(_previous_locale)


func test_keychains_objective_counts_only_keychains() -> void:
	var keychains: Dictionary = _objectives["primeros_llaveros"]
	assert_eq(ObjectiveProgress.progress(keychains, _state), 0)
	_state.delivered_by_order["maceta"] = 4
	_state.delivered_total = 4
	assert_eq(ObjectiveProgress.progress(keychains, _state), 0, "Otros pedidos no cuentan")
	_state.delivered_by_order["llavero"] = 2
	_state.delivered_total = 6
	assert_eq(ObjectiveProgress.progress(keychains, _state), 2)


func test_ten_orders_objective_counts_every_delivery() -> void:
	_state.delivered_by_order["maceta"] = 4
	_state.delivered_by_order["llavero"] = 3
	_state.delivered_total = 7
	assert_eq(ObjectiveProgress.progress(_objectives["diez_pedidos"], _state), 7)


func test_other_objective_types_give_zero_for_now() -> void:
	_state.delivered_total = 12
	_state.delivered_by_order["casco_cosplay"] = 2
	_state.xp = 5000
	for objective_id: String in ["impresora_del_suelo", "primera_pei", "primer_petg", "nivel_dos", "segunda_impresora", "garaje"]:
		assert_eq(ObjectiveProgress.progress(_objectives[objective_id], _state), 0, objective_id)
	assert_eq(ObjectiveProgress.progress(_objectives["primer_cosplay"], _state), 2, "Este sí es de entregar")


func test_row_shows_progress_below_the_goal() -> void:
	var row: ObjectiveRow = add_child_autofree(ObjectiveRow.new(_objectives["primeros_llaveros"], 1, true))
	var texts: Array[String] = _texts(row)
	assert_eq(texts.size(), 1, "La fila compacta no muestra la recompensa")
	assert_eq(texts[0], "Entrega 3 llaveros (1/3)")
	assert_eq(_check_marks(row), 0)


func test_row_caps_progress_and_says_reward_soon() -> void:
	var row: ObjectiveRow = add_child_autofree(ObjectiveRow.new(_objectives["primeros_llaveros"], 5, false))
	var texts: Array[String] = _texts(row)
	assert_eq(texts[0], "Entrega 3 llaveros (3/3) · premio pronto", "Nunca más que la meta")
	assert_eq(_check_marks(row), 0, "Cumplir el objetivo y cobrar el premio llega en la tarea 9")


func _texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for node: Node in root.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return texts


func _check_marks(root: Node) -> int:
	return root.find_children("*", "TextureRect", true, false).size()

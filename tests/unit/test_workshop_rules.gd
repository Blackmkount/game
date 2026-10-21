extends GutTest
## Reglas del taller en la partida inicial.

var _catalog: DataCatalog
var _state: GameState


func before_each() -> void:
	_catalog = DataCatalog.load_from()
	_state = GameState.new_game(_catalog, 1)


func test_room_has_six_spots_and_one_is_used() -> void:
	assert_eq(WorkshopRules.floor_slots_total(_state, _catalog), 6)
	assert_eq(WorkshopRules.floor_slots_used(_state, _catalog), 1)


func test_base_storage_is_four_kilos() -> void:
	assert_eq(WorkshopRules.storage_capacity_grams(_state, _catalog), 4000)


func test_shelves_add_storage() -> void:
	_state.furniture.append(OwnedFurniture.new(_state.take_uid(), "repisa_filamento", 1))
	assert_eq(WorkshopRules.storage_capacity_grams(_state, _catalog), 10000)


func test_printer_on_the_floor_until_there_is_a_table() -> void:
	assert_eq(WorkshopRules.printers_on_floor(_state), 1)
	assert_eq(WorkshopRules.floor_printer_limit(_catalog), 1)
	assert_almost_eq(WorkshopRules.floor_reliability_penalty(_catalog), 0.05, 0.0001)
	_state.furniture.append(OwnedFurniture.new(_state.take_uid(), "mesa_auxiliar", 1))
	assert_ne(_state.free_printer_place(_catalog), OwnedPrinter.ON_FLOOR)


func test_printer_on_the_floor_loses_reliability() -> void:
	var printer: OwnedPrinter = _state.printers[0]
	assert_almost_eq(WorkshopRules.printer_reliability(_state, _catalog, printer), 0.80, 0.0001, "Cubo Uno: 85% menos 5% por estar en el suelo")


func test_printer_on_a_table_keeps_its_reliability() -> void:
	var table: OwnedFurniture = OwnedFurniture.new(_state.take_uid(), "mesa_auxiliar", 1)
	_state.furniture.append(table)
	var printer: OwnedPrinter = _state.printers[0]
	printer.furniture_uid = table.uid
	assert_almost_eq(WorkshopRules.printer_reliability(_state, _catalog, printer), 0.85, 0.0001)


func test_tool_panel_bonus_counts_even_with_furniture_bought_after_it() -> void:
	_state.furniture.append(OwnedFurniture.new(_state.take_uid(), "panel_herramientas", 1))
	_state.furniture.append(OwnedFurniture.new(_state.take_uid(), "mesa_auxiliar", 2))
	assert_almost_eq(WorkshopRules.furniture_reliability_bonus(_state, _catalog), 0.02, 0.0001)
	assert_almost_eq(WorkshopRules.printer_reliability(_state, _catalog, _state.printers[0]), 0.82, 0.0001)

extends GutTest
## A qué pedido apunta el botón Imprimir del panel del computador.

var _rules: SimRules
var _sim: Simulation
var _state: GameState


func before_each() -> void:
	_rules = SimRules.from_catalog(DataCatalog.load_from())
	_sim = SimFixtures.new_sim(_rules)
	_state = _sim.state
	SimFixtures.quiet_board(_state)


func test_print_points_to_a_ready_model_that_can_print_now() -> void:
	# La maceta (80 g) tiene el uid menor, pero no alcanza el material; el
	# llavero (8 g) sí se puede imprimir ya.
	var maceta: Order = SimFixtures.accept(_sim, "maceta")
	var llavero: Order = SimFixtures.accept(_sim, "llavero")
	SimFixtures.finish_designs(_sim)
	_state.spools[0].grams = 50
	assert_eq(DeskSheet.first_ready(_state), maceta)
	assert_false(PrintPlanner.recommend(_state, _rules, maceta).ok)
	assert_eq(DeskSheet.print_target(_state, _rules), llavero, "Apunta al que se puede imprimir")


func test_with_nothing_printable_it_points_to_the_first_ready_model() -> void:
	# Así el botón apagado dice el motivo del primero.
	var maceta: Order = SimFixtures.accept(_sim, "maceta")
	SimFixtures.accept(_sim, "soporte_celular")
	SimFixtures.finish_designs(_sim)
	_state.spools[0].grams = 5
	assert_eq(DeskSheet.print_target(_state, _rules), maceta)


func test_with_no_ready_model_there_is_no_target() -> void:
	assert_null(DeskSheet.print_target(_state, _rules))

extends GutTest
## Qué objeto se resalta cuando el personaje está cerca.

var _tuning: ControlsTuning
var _reach: ReachTracker
var _table: WorldInteractable
var _printer: WorldInteractable
var _door: WorldInteractable
var _slot: WorldInteractable
var _items: Array[WorldInteractable] = []


func before_each() -> void:
	_tuning = ControlsTuning.new()
	_reach = ReachTracker.new(_tuning)
	_table = _item(WorldInteractable.Kind.FURNITURE, Vector3(0.0, 0.0, 0.0), Vector3(0.6, 0.5, 0.55))
	# La impresora está sobre la mesa, un poco hacia adentro.
	_printer = _item(WorldInteractable.Kind.PRINTER, Vector3(0.08, 0.5, 0.06), Vector3(0.44, 0.6, 0.42))
	_door = _item(WorldInteractable.Kind.DOOR, Vector3(-3.0, 0.0, 2.0), Vector3(0.1, 2.0, 1.0))
	_slot = _item(WorldInteractable.Kind.SLOT, Vector3(2.0, 0.0, 0.0), Vector3(0.6, 0.2, 0.6))
	_items = [_table, _printer, _door, _slot]


func test_nothing_is_highlighted_far_away() -> void:
	assert_null(_reach.update(Vector2(0.3, 2.5), _items))


func test_a_printer_wins_over_the_table_it_sits_on() -> void:
	assert_eq(_reach.update(Vector2(0.3, 1.0), _items), _printer)


func test_printer_takes_over_from_its_table_when_walking_up_to_it() -> void:
	# La mesa entra primero en la distancia (su borde está 8 cm antes que el de
	# la impresora); al llegar junto a la impresora, la impresora toma el resalte.
	var near_table: Vector2 = Vector2(-(_tuning.reach_enter - 0.04), 0.3)
	assert_eq(_reach.update(near_table, [_table, _printer] as Array[WorldInteractable]), _table)
	assert_eq(_reach.update(Vector2(-0.2, 0.3), [_table, _printer] as Array[WorldInteractable]), _printer)


func test_free_slots_are_never_highlighted() -> void:
	assert_null(_reach.update(Vector2(2.3, 0.9), _items), "Los lugares libres solo se tocan")


func test_highlight_stays_until_walking_past_the_exit_distance() -> void:
	assert_eq(_reach.update(Vector2(0.3, 1.0), _items), _printer)
	var between: float = 0.55 + (_tuning.reach_enter + _tuning.reach_exit) / 2.0
	assert_eq(_reach.update(Vector2(0.3, between), _items), _printer, "Entre las dos distancias se mantiene")
	assert_null(_reach.update(Vector2(0.3, 0.55 + _tuning.reach_exit + 0.1), _items))


func test_switching_needs_a_clearly_closer_object() -> void:
	var left: WorldInteractable = _item(WorldInteractable.Kind.FURNITURE, Vector3(-1.0, 0.0, 0.0), Vector3(0.6, 0.5, 0.6))
	var right: WorldInteractable = _item(WorldInteractable.Kind.FURNITURE, Vector3(0.4, 0.0, 0.0), Vector3(0.6, 0.5, 0.6))
	var pair: Array[WorldInteractable] = [left, right]
	assert_eq(_reach.update(Vector2(-0.15, 0.5), pair), left)
	assert_eq(_reach.update(Vector2(0.02, 0.5), pair), left, "Un poco más cerca del otro no basta")
	assert_eq(_reach.update(Vector2(0.3, 0.5), pair), right, "Claramente más cerca cambia aunque el otro siga en rango")


func _item(kind: WorldInteractable.Kind, position: Vector3, size: Vector3) -> WorldInteractable:
	return WorldInteractable.new(kind, 0, AABB(position, size))

extends GutTest
## Piso caminable: choques, deslizamiento por los bordes y búsqueda de caminos.

const ROOM: Rect2 = Rect2(-3.0, -3.0, 6.0, 6.0)

var _grid: WalkGrid


func before_each() -> void:
	_grid = WalkGrid.new(ROOM, 0.2, 0.2)


func test_character_stays_inside_the_floor() -> void:
	_grid.build()
	assert_true(_grid.is_free(Vector2.ZERO))
	assert_false(_grid.is_free(Vector2(2.9, 0.0)), "El cuerpo saldría del piso")
	assert_false(_grid.is_free(Vector2(0.0, -3.5)))


func test_obstacles_block_their_area_and_a_margin() -> void:
	_grid.add_obstacle(Rect2(0.0, 0.0, 1.0, 1.0))
	_grid.build()
	assert_false(_grid.is_free(Vector2(0.5, 0.5)))
	assert_false(_grid.is_free(Vector2(-0.1, 0.5)), "El radio del personaje cuenta")
	assert_true(_grid.is_free(Vector2(-0.3, 0.5)))


func test_moving_into_a_wall_slides_along_it() -> void:
	_grid.add_obstacle(Rect2(0.0, -2.0, 1.0, 4.0))
	_grid.build()
	var end: Vector2 = _grid.move(Vector2(-0.5, 0.0), Vector2(1.0, 0.5))
	assert_lt(end.x, -0.19, "No entra en el obstáculo")
	assert_almost_eq(end.y, 0.5, 0.001, "Conserva el movimiento paralelo al borde")


func test_a_big_step_does_not_tunnel_through_thin_obstacles() -> void:
	_grid.add_obstacle(Rect2(0.0, -3.0, 0.05, 6.0))
	_grid.build()
	var end: Vector2 = _grid.move(Vector2(-1.0, 0.0), Vector2(2.0, 0.0))
	assert_lt(end.x, 0.0)


func test_path_goes_around_an_obstacle() -> void:
	_grid.add_obstacle(Rect2(-0.5, -2.0, 1.0, 4.0))
	_grid.build()
	var from: Vector2 = Vector2(-2.0, 0.0)
	var to: Vector2 = Vector2(2.0, 0.0)
	var path: PackedVector2Array = _grid.find_path(from, to)
	assert_gt(path.size(), 1, "Tiene que rodear el obstáculo")
	assert_eq(path[path.size() - 1], to, "Termina donde se tocó")
	var previous: Vector2 = from
	for point: Vector2 in path:
		for i: int in 11:
			assert_true(_grid.is_free(previous.lerp(point, i / 10.0)), "El camino no atraviesa el obstáculo")
		previous = point


func test_path_in_open_floor_is_a_straight_line() -> void:
	_grid.build()
	var path: PackedVector2Array = _grid.find_path(Vector2(-2.0, -2.0), Vector2(2.0, 2.0))
	assert_eq(path.size(), 1)


func test_path_to_a_blocked_point_ends_next_to_it() -> void:
	_grid.add_obstacle(Rect2(1.0, 1.0, 1.0, 1.0))
	_grid.build()
	var path: PackedVector2Array = _grid.find_path(Vector2(-2.0, -2.0), Vector2(1.5, 1.5))
	assert_false(path.is_empty())
	var end: Vector2 = path[path.size() - 1]
	assert_true(_grid.is_free(end))
	assert_lt(end.distance_to(Vector2(1.5, 1.5)), 1.0)


func test_unreachable_place_gives_no_path() -> void:
	# Una pared completa divide el piso en dos.
	_grid.add_obstacle(Rect2(-0.1, -3.0, 0.2, 6.0))
	_grid.build()
	assert_true(_grid.find_path(Vector2(-2.0, 0.0), Vector2(2.0, 0.0)).is_empty())


func test_distance_to_rect() -> void:
	var rect: Rect2 = Rect2(0.0, 0.0, 1.0, 1.0)
	assert_almost_eq(WalkGrid.distance_to_rect(Vector2(0.5, 0.5), rect), 0.0, 0.0001)
	assert_almost_eq(WalkGrid.distance_to_rect(Vector2(2.0, 0.5), rect), 1.0, 0.0001)
	assert_almost_eq(WalkGrid.distance_to_rect(Vector2(4.0, 5.0), rect), 5.0, 0.0001)


func test_walking_into_a_corner_glides_around_it() -> void:
	_grid.add_obstacle(Rect2(0.0, 0.0, 1.0, 1.0))
	_grid.build()
	# Va en diagonal hacia la esquina (0, 0), un poco desviado: rodea la caja.
	var end: Vector2 = _grid.move(Vector2(-1.0, -0.9), Vector2(2.5, 2.5))
	assert_true(_grid.is_free(end))
	assert_gt(end.x + end.y, 0.5, "Avanza rodeando la esquina en lugar de quedarse pegado")


func test_a_character_inside_an_obstacle_is_pushed_out() -> void:
	var box: Rect2 = Rect2(0.0, 0.0, 1.0, 1.0)
	_grid.add_obstacle(box)
	_grid.build()
	var point: Vector2 = _grid.resolve(Vector2(0.1, 0.5))
	assert_true(_grid.is_free(point))
	assert_lt(point.x, 0.0, "Sale por el lado más cercano")

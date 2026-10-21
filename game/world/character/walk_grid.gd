class_name WalkGrid
extends RefCounted
## Piso por donde puede caminar el personaje, visto desde arriba (plano XZ).
##
## El personaje es un círculo que no puede salir del piso ni meterse en los
## obstáculos (muebles e impresoras), que son rectángulos. Sirve para dos
## cosas, sin motor de física:
## - Mover al personaje con el joystick: avanza y se desliza por los bordes.
## - Buscar un camino hasta un punto o un objeto tocado (A* con AStarGrid2D).
##
## Todas las posiciones son Vector2(x, z) en metros del mundo.

## Paso máximo de cada movimiento, para no atravesar obstáculos delgados.
const MAX_STEP: float = 0.05
## Margen al empujar fuera de un obstáculo, para quedar justo afuera.
const PUSH_EPSILON: float = 0.001

var bounds: Rect2
var cell_size: float
var radius: float

var _obstacles: Array[Rect2] = []
var _grid: AStarGrid2D = AStarGrid2D.new()


func _init(p_bounds: Rect2, p_cell_size: float = 0.2, p_radius: float = 0.2) -> void:
	bounds = p_bounds
	cell_size = p_cell_size
	radius = p_radius


func add_obstacle(rect: Rect2) -> void:
	_obstacles.append(rect)


## Arma la cuadrícula de caminos. Hay que llamarla después de agregar o quitar
## obstáculos.
func build() -> void:
	var size: Vector2i = Vector2i(ceili(bounds.size.x / cell_size), ceili(bounds.size.y / cell_size))
	_grid = AStarGrid2D.new()
	_grid.region = Rect2i(Vector2i.ZERO, size)
	_grid.cell_size = Vector2(cell_size, cell_size)
	_grid.offset = bounds.position + Vector2(cell_size, cell_size) / 2.0
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.update()
	for x: int in size.x:
		for y: int in size.y:
			var cell: Vector2i = Vector2i(x, y)
			_grid.set_point_solid(cell, not is_free(_grid.get_point_position(cell)))


## ¿Cabe el personaje con su centro en este punto?
func is_free(point: Vector2) -> bool:
	var inner: Rect2 = bounds.grow(-radius)
	if not inner.has_point(point):
		return false
	for obstacle: Rect2 in _obstacles:
		if distance_to_rect(point, obstacle) < radius:
			return false
	return true


## Mueve desde `from` un desplazamiento `delta`, en pasos cortos. Si choca,
## lo empuja hacia afuera por el punto más cercano del obstáculo: así se
## desliza por los bordes y rodea las esquinas como si fueran redondeadas.
func move(from: Vector2, delta: Vector2) -> Vector2:
	var steps: int = maxi(1, ceili(delta.length() / MAX_STEP))
	var step: Vector2 = delta / float(steps)
	var position: Vector2 = from
	for i: int in steps:
		position = resolve(position + step)
	return position


## Saca un punto de los obstáculos y lo deja dentro del piso.
func resolve(point: Vector2) -> Vector2:
	var inner: Rect2 = bounds.grow(-radius)
	var result: Vector2 = point
	for iteration: int in 3:
		var pushed: bool = false
		for obstacle: Rect2 in _obstacles:
			var closest: Vector2 = result.clamp(obstacle.position, obstacle.end)
			var offset: Vector2 = result - closest
			var distance: float = offset.length()
			if distance >= radius:
				continue
			pushed = true
			if distance > 0.0001:
				result = closest + offset / distance * (radius + PUSH_EPSILON)
			else:
				result = _push_out_of(result, obstacle)
		result = result.clamp(inner.position, inner.end)
		if not pushed:
			break
	return result


## Camino desde `from` hasta `to` como lista de puntos, sin incluir `from`.
## Si `to` no está libre, termina en el punto libre más cercano. Vacío si no
## hay camino.
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start: Variant = _nearest_free_cell(from)
	var goal: Variant = _nearest_free_cell(to)
	if start == null or goal == null:
		return PackedVector2Array()
	var cells: PackedVector2Array = _grid.get_point_path(start, goal)
	if cells.is_empty():
		return PackedVector2Array()
	var points: PackedVector2Array = PackedVector2Array([from])
	for i: int in range(1, cells.size()):
		points.append(cells[i])
	var end_point: Vector2 = to if is_free(to) else cells[cells.size() - 1]
	if points.size() > 1:
		points[points.size() - 1] = end_point
	else:
		points.append(end_point)
	return _smooth(points).slice(1)


static func distance_to_rect(point: Vector2, rect: Rect2) -> float:
	var dx: float = maxf(maxf(rect.position.x - point.x, 0.0), point.x - rect.end.x)
	var dy: float = maxf(maxf(rect.position.y - point.y, 0.0), point.y - rect.end.y)
	return Vector2(dx, dy).length()


## Con el centro dentro del obstáculo, sale por el lado más cercano.
func _push_out_of(point: Vector2, obstacle: Rect2) -> Vector2:
	var to_left: float = point.x - obstacle.position.x
	var to_right: float = obstacle.end.x - point.x
	var to_back: float = point.y - obstacle.position.y
	var to_front: float = obstacle.end.y - point.y
	var nearest: float = minf(minf(to_left, to_right), minf(to_back, to_front))
	var margin: float = radius + PUSH_EPSILON
	if nearest == to_left:
		return Vector2(obstacle.position.x - margin, point.y)
	if nearest == to_right:
		return Vector2(obstacle.end.x + margin, point.y)
	if nearest == to_back:
		return Vector2(point.x, obstacle.position.y - margin)
	return Vector2(point.x, obstacle.end.y + margin)


func _cell_of(point: Vector2) -> Vector2i:
	var local: Vector2 = (point - bounds.position) / cell_size
	return Vector2i(clampi(floori(local.x), 0, _grid.region.size.x - 1), clampi(floori(local.y), 0, _grid.region.size.y - 1))


func _nearest_free_cell(point: Vector2) -> Variant:
	var origin: Vector2i = _cell_of(point)
	if not _grid.is_point_solid(origin):
		return origin
	var best: Variant = null
	var best_distance: float = INF
	var region: Rect2i = _grid.region
	for x: int in region.size.x:
		for y: int in region.size.y:
			var cell: Vector2i = Vector2i(x, y)
			if _grid.is_point_solid(cell):
				continue
			var distance: float = _grid.get_point_position(cell).distance_squared_to(point)
			if distance < best_distance:
				best_distance = distance
				best = cell
	return best


## Quita puntos intermedios cuando se puede ir en línea recta sin chocar.
func _smooth(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() <= 2:
		return points
	var result: PackedVector2Array = PackedVector2Array([points[0]])
	var anchor: int = 0
	while anchor < points.size() - 1:
		var next: int = points.size() - 1
		while next > anchor + 1 and not _segment_free(points[anchor], points[next]):
			next -= 1
		result.append(points[next])
		anchor = next
	return result


func _segment_free(a: Vector2, b: Vector2) -> bool:
	var samples: int = maxi(1, ceili(a.distance_to(b) / (cell_size * 0.5)))
	for i: int in range(1, samples + 1):
		if not is_free(a.lerp(b, float(i) / float(samples))):
			return false
	return true

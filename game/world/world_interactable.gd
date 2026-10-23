class_name WorldInteractable
extends RefCounted
## Algo del mundo que se puede tocar y, en algunos casos, resaltar cuando el
## personaje está cerca: una impresora, un mueble, un lugar libre, la puerta,
## el rincón de despacho o el propio personaje.

## DISPATCH va al final para no cambiar el número de los demás.
enum Kind { PRINTER, FURNITURE, SLOT, DOOR, CHARACTER, DISPATCH }

## Prioridad al elegir entre varios objetos a la vez (al tocar o al estar
## cerca): una impresora gana sobre la mesa donde está.
const PRIORITY: Dictionary[Kind, int] = {
	Kind.PRINTER: 4,
	Kind.FURNITURE: 3,
	Kind.DISPATCH: 3,
	Kind.DOOR: 2,
	Kind.CHARACTER: 1,
	Kind.SLOT: 0,
}

var kind: Kind
## uid de la impresora o del mueble en el estado, o índice del lugar libre
## (0 para la puerta, el rincón de despacho y el personaje).
var ref: int
## Caja del modelo en sus propias coordenadas y dónde está el modelo. Para
## saber si un toque le da se usa esta caja, girada con el modelo.
var local_bounds: AABB
var transform: Transform3D
## Caja alineada con el mundo que contiene a la girada: para el piso, la
## cercanía y el marco. En un objeto girado es más grande que el objeto.
var bounds: AABB
## Las partes que se tocan, en el espacio del modelo como local_bounds, si no
## es la caja entera: la estantería metálica es abierta y por sus huecos se
## toca lo que está detrás. Vacío: se toca la caja.
var touch_parts: Array[AABB] = []
## Si se resalta cuando el personaje está cerca. Los lugares libres y el
## personaje no: solo se tocan.
var reachable: bool


func _init(p_kind: Kind, p_ref: int, p_local_bounds: AABB, p_transform: Transform3D = Transform3D.IDENTITY) -> void:
	kind = p_kind
	ref = p_ref
	place(p_local_bounds, p_transform)
	reachable = p_kind in [Kind.PRINTER, Kind.FURNITURE, Kind.DOOR, Kind.DISPATCH]


func place(p_local_bounds: AABB, p_transform: Transform3D) -> void:
	local_bounds = p_local_bounds
	transform = p_transform
	bounds = p_transform * p_local_bounds


func priority() -> int:
	return PRIORITY[kind]


## Distancia desde `origin` hasta donde el rayo toca la caja girada (o la
## parte más cercana de touch_parts), agrandada `margin` metros por lado. INF
## si no la toca.
func ray_distance(origin: Vector3, direction: Vector3, margin: float) -> float:
	var inverse: Transform3D = transform.affine_inverse()
	var local_origin: Vector3 = inverse * origin
	var local_direction: Vector3 = inverse.basis * direction
	if touch_parts.is_empty():
		return _hit_distance(local_bounds.grow(margin), origin, local_origin, local_direction)
	var nearest: float = INF
	for part: AABB in touch_parts:
		nearest = minf(nearest, _hit_distance(part.grow(margin), origin, local_origin, local_direction))
	return nearest


## Rectángulo que ocupa en el piso, en el plano XZ.
func footprint() -> Rect2:
	return Rect2(bounds.position.x, bounds.position.z, bounds.size.x, bounds.size.z)


## Centro de la cara de arriba, para poner burbujas encima.
func top_center() -> Vector3:
	var center: Vector3 = bounds.get_center()
	return Vector3(center.x, bounds.end.y, center.z)


## Distancia desde `origin` hasta donde el rayo (en el espacio del modelo)
## toca `box`; INF si no la toca.
func _hit_distance(box: AABB, origin: Vector3, local_origin: Vector3, local_direction: Vector3) -> float:
	var hit: Variant = box.intersects_ray(local_origin, local_direction)
	if hit == null:
		return INF
	return origin.distance_to(transform * (hit as Vector3))

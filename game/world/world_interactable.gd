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


## Distancia desde `origin` hasta donde el rayo toca la caja girada, agrandada
## `margin` metros por lado. INF si no la toca.
func ray_distance(origin: Vector3, direction: Vector3, margin: float) -> float:
	var inverse: Transform3D = transform.affine_inverse()
	var hit: Variant = local_bounds.grow(margin).intersects_ray(inverse * origin, inverse.basis * direction)
	if hit == null:
		return INF
	return origin.distance_to(transform * (hit as Vector3))


## Rectángulo que ocupa en el piso, en el plano XZ.
func footprint() -> Rect2:
	return Rect2(bounds.position.x, bounds.position.z, bounds.size.x, bounds.size.z)


## Centro de la cara de arriba, para poner burbujas encima.
func top_center() -> Vector3:
	var center: Vector3 = bounds.get_center()
	return Vector3(center.x, bounds.end.y, center.z)

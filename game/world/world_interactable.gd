class_name WorldInteractable
extends RefCounted
## Algo del mundo que se puede tocar y, en algunos casos, resaltar cuando el
## personaje está cerca: una impresora, un mueble, un lugar libre, la puerta o
## el propio personaje.

enum Kind { PRINTER, FURNITURE, SLOT, DOOR, CHARACTER }

## Prioridad al elegir entre varios objetos a la vez (al tocar o al estar
## cerca): una impresora gana sobre la mesa donde está.
const PRIORITY: Dictionary[Kind, int] = {
	Kind.PRINTER: 4,
	Kind.FURNITURE: 3,
	Kind.DOOR: 2,
	Kind.CHARACTER: 1,
	Kind.SLOT: 0,
}

var kind: Kind
## uid de la impresora o del mueble en el estado, o índice del lugar libre.
var ref: int
## Caja en coordenadas del mundo. Se calcula al armar la habitación.
var bounds: AABB
## Si se resalta cuando el personaje está cerca. Los lugares libres y el
## personaje no: solo se tocan.
var reachable: bool


func _init(p_kind: Kind, p_ref: int, p_bounds: AABB) -> void:
	kind = p_kind
	ref = p_ref
	bounds = p_bounds
	reachable = p_kind in [Kind.PRINTER, Kind.FURNITURE, Kind.DOOR]


func priority() -> int:
	return PRIORITY[kind]


## Rectángulo que ocupa en el piso, en el plano XZ.
func footprint() -> Rect2:
	return Rect2(bounds.position.x, bounds.position.z, bounds.size.x, bounds.size.z)


## Centro de la cara de arriba, para poner burbujas encima.
func top_center() -> Vector3:
	var center: Vector3 = bounds.get_center()
	return Vector3(center.x, bounds.end.y, center.z)

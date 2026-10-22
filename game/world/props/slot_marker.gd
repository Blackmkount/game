class_name SlotMarker
extends RefCounted
## Marca en el piso de un lugar libre para un mueble (biblia de arte §8.7):
## cuatro esquinas en L y un "+" al centro, planas. Es una sola malla, la misma
## para todas las marcas (una llamada de dibujo por marca). El material
## (marker.gdshader) lo pone RoomView: late suave o se enciende cuando el
## personaje está cerca o la tienda está abierta.

## Lo que ocupa la marca (y su zona de toque): ancho (x) y fondo (z).
const SIZE: Vector2 = Vector2(1.24, 0.6)
## Brazos de cada esquina, ancho de las líneas y lado del "+".
const ARM: float = 0.18
const LINE: float = 0.03
const PLUS: float = 0.14
## Alto sobre el piso.
const HEIGHT: float = 0.006


static func build(parent: Node3D, node_name: String, material: Material) -> Node3D:
	var marker: Node3D = PropBuilder.group(parent, node_name)
	var mark: MeshInstance3D = PropBuilder.kit(marker, "Mark", mesh(), material)
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return marker


## La malla de todas las marcas.
static func mesh() -> ArrayMesh:
	return KitMesh.cached("slot_marker", _build_mesh)


static func _build_mesh() -> ArrayMesh:
	var kit: KitMesh = KitMesh.new()
	kit.ao_enabled = false
	var half: Vector2 = SIZE / 2.0
	# Ningún rectángulo se encima con otro: el alfa queda parejo.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_flat(kit, Vector2(sx * (half.x - ARM / 2.0), sz * (half.y - LINE / 2.0)), Vector2(ARM, LINE))
			_flat(kit, Vector2(sx * (half.x - LINE / 2.0), sz * (half.y - LINE - (ARM - LINE) / 2.0)), Vector2(LINE, ARM - LINE))
	_flat(kit, Vector2.ZERO, Vector2(PLUS, LINE))
	var stub: float = (PLUS - LINE) / 2.0
	for sz: float in [-1.0, 1.0]:
		_flat(kit, Vector2(0.0, sz * (LINE + stub) / 2.0), Vector2(LINE, stub))
	return kit.commit()


## Rectángulo plano sobre el piso, mirando hacia arriba.
static func _flat(kit: KitMesh, center: Vector2, size: Vector2) -> void:
	kit.quad(size, Vector3(center.x, HEIGHT, center.y), Vector3(-90.0, 0.0, 0.0))

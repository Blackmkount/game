class_name RoomLayout
extends RefCounted
## Dónde va cada cosa dentro de un espacio: los lugares para muebles (en el
## mismo orden que su índice en el estado), los lugares para impresoras en el
## suelo, el rincón de despacho y el lugar del personaje.

var slots: Array[Transform3D] = []
var floor_printer_spots: Array[Transform3D] = []
## Rincón de despacho (mesa de embalar y cajón de salida), junto a la puerta.
## Es fijo: no ocupa ninguno de los lugares para muebles.
var dispatch_spot: Transform3D = Transform3D.IDENTITY
var character_spot: Transform3D = Transform3D.IDENTITY


static func for_space(_space_id: String) -> RoomLayout:
	# Por ahora solo existe la habitación; el garaje llega en la Fase 3.
	var layout: RoomLayout = RoomLayout.new()
	layout.slots = [
		_at(Vector3(-2.55, 0.0, -1.2), 90.0),
		_at(Vector3(-2.55, 0.0, 0.7), 90.0),
		_at(Vector3(-1.45, 0.0, -2.6), 0.0),
		_at(Vector3(0.25, 0.0, -2.6), 0.0),
		_at(Vector3(1.95, 0.0, -2.6), 0.0),
		_at(Vector3(1.0, 0.0, 1.1), 0.0),
	]
	layout.floor_printer_spots = [_at(Vector3(-0.55, 0.0, -1.55), 25.0)]
	# Ocupa en el piso x -1,88..-1,00 y z 2,42..2,82, así que el paso frente a
	# la puerta (x -2,95..-2,0, z 1,6..2,6) queda libre. Ahí, en (-2,50, 0, 2,10),
	# se reserva el lugar donde llegarán las cajas de la tienda (tarea 5): por
	# ahora no se pone nada.
	layout.dispatch_spot = _at(Vector3(-1.45, 0.0, 2.62), 0.0)
	layout.character_spot = _at(Vector3(-1.2, 0.0, -0.95), 60.0)
	return layout


static func _at(position: Vector3, yaw_degrees: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_degrees)), position)

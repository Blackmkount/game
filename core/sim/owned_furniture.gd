class_name OwnedFurniture
extends RefCounted
## Un mueble que el jugador tiene colocado en uno de los lugares del espacio.

var uid: int
var furniture_id: String
## Índice del lugar del piso que ocupa (0, 1, 2...).
var slot: int


func _init(p_uid: int = 0, p_furniture_id: String = "", p_slot: int = 0) -> void:
	uid = p_uid
	furniture_id = p_furniture_id
	slot = p_slot

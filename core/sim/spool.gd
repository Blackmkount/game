class_name Spool
extends RefCounted
## Un carrete (o botella de resina) en el inventario.

## Identifica el carrete aunque haya otros del mismo material y color.
var uid: int
var material_id: String
var color_id: String
var grams: int


func _init(p_uid: int = 0, p_material_id: String = "", p_color_id: String = "", p_grams: int = 0) -> void:
	uid = p_uid
	material_id = p_material_id
	color_id = p_color_id
	grams = p_grams

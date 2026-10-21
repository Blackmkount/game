class_name Spool
extends RefCounted
## Un carrete (o botella de resina) en el inventario.

var material_id: String
var color_id: String
var grams: int


func _init(p_material_id: String = "", p_color_id: String = "", p_grams: int = 0) -> void:
	material_id = p_material_id
	color_id = p_color_id
	grams = p_grams

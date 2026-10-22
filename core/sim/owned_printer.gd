class_name OwnedPrinter
extends RefCounted
## Una impresora del jugador y dónde está.

const ON_FLOOR: int = -1

var uid: int
var printer_id: String
## uid del mueble donde está, u ON_FLOOR si está en el suelo.
var furniture_uid: int = ON_FLOOR
## Accesorios instalados después de comprarla (los de fábrica no se anotan aquí).
var accessories: Array[String] = []
## Trabajo actual; null = libre.
var job: PrintJob = null


func _init(p_uid: int = 0, p_printer_id: String = "", p_furniture_uid: int = ON_FLOOR) -> void:
	uid = p_uid
	printer_id = p_printer_id
	furniture_uid = p_furniture_uid


func is_on_floor() -> bool:
	return furniture_uid == ON_FLOOR

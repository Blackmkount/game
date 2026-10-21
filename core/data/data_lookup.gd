class_name DataLookup
extends RefCounted
## Atajos para buscar elementos de los datos de balance por su id.


## Devuelve {id: elemento} para un archivo con forma de lista ("printers"...).
static func by_id(catalog: DataCatalog, list_name: String) -> Dictionary:
	var result: Dictionary = {}
	for entry: Dictionary in catalog.files[list_name]:
		result[entry["id"]] = entry
	return result


## Devuelve el elemento de config.json con ese id dentro de una lista
## ("filament_colors", "print_modes"), o un diccionario vacío.
static func config_entry(catalog: DataCatalog, list_name: String, id: String) -> Dictionary:
	for entry: Dictionary in catalog.files["config"][list_name]:
		if entry["id"] == id:
			return entry
	return {}

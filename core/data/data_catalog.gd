class_name DataCatalog
extends RefCounted
## Datos de balance leídos de data/*.json, tal como están en los archivos.
##
## Cada archivo queda en `files` con su nombre sin extensión como clave
## ("printers", "orders"...). Si un archivo falta o no es JSON válido, el
## problema se anota en `errors`. Para revisar que el contenido sea coherente
## se usa DataValidator.

const FILE_NAMES: Array[String] = [
	"config",
	"levels",
	"materials",
	"printers",
	"accessories",
	"furniture",
	"spaces",
	"clients",
	"orders",
	"objectives",
]
const DEFAULT_DIR: String = "res://data"

var files: Dictionary[String, Variant] = {}
var errors: Array[String] = []


static func load_from(dir_path: String = DEFAULT_DIR) -> DataCatalog:
	var catalog: DataCatalog = DataCatalog.new()
	for file_name: String in FILE_NAMES:
		var path: String = dir_path.path_join(file_name + ".json")
		if not FileAccess.file_exists(path):
			catalog.errors.append("Falta el archivo %s" % path)
			continue
		var json: JSON = JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) != OK:
			catalog.errors.append("%s, línea %d: %s" % [path, json.get_error_line(), json.get_error_message()])
			continue
		catalog.files[file_name] = json.data
	return catalog

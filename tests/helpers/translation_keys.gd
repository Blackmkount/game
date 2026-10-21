extends RefCounted
## Lee las claves de texto de localization/translations.csv para las pruebas.

const CSV_PATH: String = "res://localization/translations.csv"


static func read() -> Array[String]:
	var keys: Array[String] = []
	var file: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		return keys
	file.get_csv_line()
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if not row.is_empty() and not row[0].is_empty():
			keys.append(row[0])
	return keys

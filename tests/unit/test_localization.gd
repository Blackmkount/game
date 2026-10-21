extends GutTest
## Prueba de ejemplo: revisa que el archivo de traducciones esté completo y
## que Godot lo cargue.

const CSV_PATH: String = "res://localization/translations.csv"
const REQUIRED_LOCALES: Array[String] = ["es", "en"]


func test_csv_has_required_language_columns() -> void:
	var header: PackedStringArray = _read_rows()[0]
	assert_eq(header[0], "keys", "La primera columna debe llamarse 'keys'")
	for locale: String in REQUIRED_LOCALES:
		assert_has(header, locale, "Falta la columna del idioma '%s'" % locale)


func test_every_key_has_text_in_every_language() -> void:
	var rows: Array[PackedStringArray] = _read_rows()
	var header: PackedStringArray = rows[0]
	for row: PackedStringArray in rows.slice(1):
		assert_eq(row.size(), header.size(), "La fila '%s' no tiene todas las columnas" % row[0])
		for column: int in range(1, mini(row.size(), header.size())):
			assert_ne(row[column].strip_edges(), "", "'%s' no tiene texto en '%s'" % [row[0], header[column]])


func test_spanish_translation_is_loaded() -> void:
	var translation: Translation = TranslationServer.get_translation_object("es")
	assert_not_null(translation, "No se cargó la traducción al español")
	if translation != null:
		assert_eq(translation.get_message(&"GAME_TITLE"), &"Capa a Capa")


func _read_rows() -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var file: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	assert_not_null(file, "No se pudo abrir %s" % CSV_PATH)
	while file != null and not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() > 1 or (row.size() == 1 and row[0] != ""):
			rows.append(row)
	return rows

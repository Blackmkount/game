extends GutTest
## Valida los archivos reales de data/*.json: que carguen, que estén completos
## y coherentes, y que el estado inicial coincida con el GDD.

const TranslationKeys: GDScript = preload("res://tests/helpers/translation_keys.gd")

var _catalog: DataCatalog


func before_all() -> void:
	_catalog = DataCatalog.load_from()


func test_all_files_load() -> void:
	assert_true(_catalog.errors.is_empty(), "\n".join(PackedStringArray(_catalog.errors)))
	assert_eq(_catalog.files.size(), DataCatalog.FILE_NAMES.size())


func test_data_is_complete_and_consistent() -> void:
	var errors: Array[String] = DataValidator.validate(_catalog.files, TranslationKeys.read())
	assert_true(errors.is_empty(), "Problemas en data/:\n" + "\n".join(PackedStringArray(errors)))


func test_starting_state_matches_design() -> void:
	var start: Dictionary = _catalog.files["config"]["starting_state"]
	assert_eq(int(start["money"]), 250)
	assert_eq(start["printers"], ["cubo_uno"])
	assert_eq(int(start["materials"]["pla"]), 1000)

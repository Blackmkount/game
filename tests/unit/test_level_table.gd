extends GutTest
## Conversión de experiencia a nivel y avance dentro del nivel.

var _levels: LevelTable


func before_each() -> void:
	var thresholds: Array[int] = [0, 100, 300, 700]
	_levels = LevelTable.new(thresholds)


func test_level_boundaries() -> void:
	assert_eq(_levels.level_for_xp(0), 1)
	assert_eq(_levels.level_for_xp(99), 1)
	assert_eq(_levels.level_for_xp(100), 2)
	assert_eq(_levels.level_for_xp(299), 2)
	assert_eq(_levels.level_for_xp(300), 3)
	assert_eq(_levels.level_for_xp(5000), 4)


func test_progress_inside_level() -> void:
	assert_eq(_levels.xp_into_level(150), 50)
	assert_eq(_levels.xp_span_of_level(150), 200)


func test_max_level_has_no_next_span() -> void:
	assert_eq(_levels.max_level(), 4)
	assert_eq(_levels.xp_span_of_level(800), 0)


func test_reads_levels_from_data() -> void:
	var levels: LevelTable = LevelTable.from_catalog(DataCatalog.load_from())
	assert_eq(levels.max_level(), 10)
	assert_eq(levels.level_for_xp(100), 2)

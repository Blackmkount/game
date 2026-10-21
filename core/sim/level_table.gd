class_name LevelTable
extends RefCounted
## Convierte experiencia (XP) en nivel y en avance hacia el siguiente nivel.

## Experiencia total necesaria para cada nivel; el índice 0 es el nivel 1.
var thresholds: Array[int] = []


func _init(p_thresholds: Array[int] = [0]) -> void:
	thresholds = p_thresholds


static func from_catalog(catalog: DataCatalog) -> LevelTable:
	var values: Array[int] = []
	for value: Variant in catalog.files["levels"]["xp_thresholds"]:
		values.append(int(value))
	return LevelTable.new(values)


func max_level() -> int:
	return thresholds.size()


func level_for_xp(xp: int) -> int:
	var level: int = 1
	for i: int in thresholds.size():
		if xp >= thresholds[i]:
			level = i + 1
	return level


## Experiencia ganada dentro del nivel actual.
func xp_into_level(xp: int) -> int:
	return xp - thresholds[level_for_xp(xp) - 1]


## Experiencia que separa el nivel actual del siguiente; 0 en el nivel máximo.
func xp_span_of_level(xp: int) -> int:
	var level: int = level_for_xp(xp)
	if level >= max_level():
		return 0
	return thresholds[level] - thresholds[level - 1]

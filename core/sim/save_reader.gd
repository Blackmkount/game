class_name SaveReader
extends RefCounted
## Lee valores de una partida guardada (JSON ya interpretado) revisando su
## tipo. Si algo no calza, anota el motivo en errors y devuelve un valor
## neutro: así SaveCodec.decode termina sin caerse y descarta la partida.

## Mayor entero que un float de JSON guarda sin perder precisión (2^53).
const MAX_EXACT_FLOAT: float = 9007199254740992.0
## Dígitos del mayor y del menor entero de 64 bits, para no desbordar to_int().
const INT64_MAX_DIGITS: String = "9223372036854775807"
const INT64_MIN_DIGITS: String = "9223372036854775808"

var errors: Array[String]


func _init(p_errors: Array[String]) -> void:
	errors = p_errors


## Entero. JSON entrega los números como float: se aceptan si no tienen
## decimales y caben exactos.
func integer(doc: Dictionary, key: String) -> int:
	var value: Variant = doc.get(key)
	if value is int:
		return value
	if value is float:
		var number: float = value
		if number == floorf(number) and absf(number) <= MAX_EXACT_FLOAT:
			return int(number)
	_fail(key, "un entero")
	return 0


## Entero de 64 bits guardado como texto (semilla y estado del azar).
func big_integer(doc: Dictionary, key: String) -> int:
	var value: Variant = doc.get(key)
	if value is String and _fits_int64(value):
		return (value as String).to_int()
	_fail(key, "un entero de 64 bits escrito como texto")
	return 0


func text(doc: Dictionary, key: String) -> String:
	var value: Variant = doc.get(key)
	if value is String:
		return value
	_fail(key, "un texto")
	return ""


func flag(doc: Dictionary, key: String) -> bool:
	var value: Variant = doc.get(key)
	if value is bool:
		return value
	_fail(key, "verdadero o falso")
	return false


func dictionary(doc: Dictionary, key: String) -> Dictionary:
	var value: Variant = doc.get(key)
	if value is Dictionary:
		return value
	_fail(key, "un objeto")
	return {}


## Lista de objetos.
func entries(doc: Dictionary, key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var value: Variant = doc.get(key)
	if not value is Array:
		_fail(key, "una lista")
		return result
	for item: Variant in value:
		if not item is Dictionary:
			_fail(key, "una lista de objetos")
			return []
		result.append(item)
	return result


## Lista de textos.
func texts(doc: Dictionary, key: String) -> Array[String]:
	var result: Array[String] = []
	var value: Variant = doc.get(key)
	if not value is Array:
		_fail(key, "una lista")
		return result
	for item: Variant in value:
		if not item is String:
			_fail(key, "una lista de textos")
			return []
		result.append(item)
	return result


## Id que tiene que existir en `known` (los datos por id de SimRules).
func known_id(doc: Dictionary, key: String, known: Dictionary) -> String:
	var id: String = text(doc, key)
	if not known.has(id):
		errors.append("'%s' tiene un id desconocido: '%s'" % [key, id])
	return id


## Valor de un enum guardado como su nombre en minúsculas ("designing").
func enum_value(doc: Dictionary, key: String, names: Dictionary) -> int:
	var name: String = text(doc, key)
	if name == name.to_lower() and names.has(name.to_upper()):
		return names[name.to_upper()]
	_fail(key, "uno de %s" % ", ".join(PackedStringArray(names.keys())).to_lower())
	return 0


func _fail(key: String, expected: String) -> void:
	errors.append("'%s' debe ser %s" % [key, expected])


static func _fits_int64(value: String) -> bool:
	if not value.is_valid_int():
		return false
	var negative: bool = value.begins_with("-")
	var digits: String = value.trim_prefix("-").trim_prefix("+").lstrip("0")
	var limit: String = INT64_MIN_DIGITS if negative else INT64_MAX_DIGITS
	if digits.length() != limit.length():
		return digits.length() < limit.length()
	return digits <= limit

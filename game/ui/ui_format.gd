class_name UiFormat
extends RefCounted
## Formatos de números para la interfaz según el idioma: dinero, gramos,
## duraciones y fechas del juego.


static func is_spanish() -> bool:
	return TranslationServer.get_locale().begins_with("es")


## 25000 centavos -> "$250"; 258050 -> "$2.580,50" en español.
static func money(cents: int) -> String:
	var negative: bool = cents < 0
	var absolute: int = absi(cents)
	var text: String = "$" + _thousands(floori(absolute / 100.0))
	if absolute % 100 != 0:
		text += ("," if is_spanish() else ".") + "%02d" % (absolute % 100)
	return ("-" if negative else "") + text


static func number(value: int) -> String:
	return _thousands(value)


## Número con decimales fijos usando la coma o el punto del idioma.
static func decimal(value: float, decimals: int = 1) -> String:
	var text: String = ("%." + str(decimals) + "f") % value
	return text.replace(".", ",") if is_spanish() else text


static func grams(value: int) -> String:
	return tr_format("FORMAT_GRAMS", [_thousands(value)])


static func kilograms(grams_value: int) -> String:
	return decimal(grams_value / 1000.0)


## Duración en minutos de juego -> "20 min", "1 h 30 min", "5 h".
static func duration(minutes: float) -> String:
	var total: int = int(round(minutes))
	var hours: int = floori(total / 60.0)
	var rest: int = total % 60
	if hours == 0:
		return tr_format("FORMAT_MINUTES", [rest])
	if rest == 0:
		return tr_format("FORMAT_HOURS", [hours])
	return tr_format("FORMAT_HOURS_MINUTES", [hours, rest])


static func day_range(days: Array) -> String:
	if int(days[0]) == int(days[1]):
		return tr_format("FORMAT_DAYS", [int(days[0])])
	return tr_format("FORMAT_DAY_RANGE", [int(days[0]), int(days[1])])


static func date(game_minutes: float) -> String:
	return tr_format("FORMAT_DATE", [GameClock.day(game_minutes), GameClock.hour(game_minutes), GameClock.minute(game_minutes)])


static func tr_format(key: String, values: Array) -> String:
	return String(TranslationServer.translate(key)) % values


static func _thousands(value: int) -> String:
	var digits: String = str(value)
	var separator: String = "." if is_spanish() else ","
	var result: String = ""
	while digits.length() > 3:
		result = separator + digits.substr(digits.length() - 3) + result
		digits = digits.substr(0, digits.length() - 3)
	return digits + result

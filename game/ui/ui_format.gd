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


## Duración real que espera el jugador: `game_seconds` segundos de juego a
## `rate` segundos de juego por segundo real. Se redondea hacia arriba, así
## una cuenta regresiva nunca muestra 0 antes de tiempo: "50 s",
## "1 min 40 s", "5 min" y, desde una hora, "1 h 23 min".
static func real_duration(game_seconds: int, rate: int) -> String:
	var seconds: int = ceili(float(maxi(game_seconds, 0)) / float(maxi(rate, 1)))
	if seconds >= GameClock.SECONDS_PER_HOUR:
		return duration(ceili(seconds / float(GameClock.SECONDS_PER_MINUTE)))
	var minutes: int = floori(seconds / float(GameClock.SECONDS_PER_MINUTE))
	var rest: int = seconds % GameClock.SECONDS_PER_MINUTE
	if minutes == 0:
		return tr_format("FORMAT_SECONDS", [rest])
	if rest == 0:
		return tr_format("FORMAT_MINUTES", [minutes])
	return tr_format("FORMAT_MINUTES_SECONDS", [minutes, rest])


## Duración en segundos de juego, en tiempo de juego: 1200 -> "20 min".
static func game_duration(game_seconds: int) -> String:
	return duration(game_seconds / float(GameClock.SECONDS_PER_MINUTE))


## Fecha de juego de un plazo guardado en segundos de juego.
static func due_date(due_game_seconds: int) -> String:
	return date(due_game_seconds / float(GameClock.SECONDS_PER_MINUTE))


## Motivo de un comando que no se pudo, listo para mostrar ("" si se pudo).
## Los argumentos String son claves de texto y se traducen; los Dictionary
## son una cantidad (ver CommandResult): segundos de juego, que se muestran
## en tiempo real a `rate`, gramos o centavos.
static func reason(result: CommandResult, rate: int) -> String:
	if result == null or result.ok:
		return ""
	if result.args.is_empty():
		return String(TranslationServer.translate(result.reason))
	var values: Array = []
	for arg: Variant in result.args:
		values.append(_reason_value(arg, rate))
	return tr_format(result.reason, values)


static func day_range(days: Array) -> String:
	if int(days[0]) == int(days[1]):
		return tr_format("FORMAT_DAYS", [int(days[0])])
	return tr_format("FORMAT_DAY_RANGE", [int(days[0]), int(days[1])])


static func date(game_minutes: float) -> String:
	return tr_format("FORMAT_DATE", [GameClock.day(game_minutes), GameClock.hour(game_minutes), GameClock.minute(game_minutes)])


static func tr_format(key: String, values: Array) -> String:
	return String(TranslationServer.translate(key)) % values


static func _reason_value(arg: Variant, rate: int) -> Variant:
	if arg is String:
		return String(TranslationServer.translate(arg))
	if arg is Dictionary:
		var amount: Dictionary = arg
		if amount.has("seconds"):
			return real_duration(int(amount["seconds"]), rate)
		if amount.has("grams"):
			return grams(int(amount["grams"]))
		if amount.has("cents"):
			return money(int(amount["cents"]))
	return arg


static func _thousands(value: int) -> String:
	var digits: String = str(value)
	var separator: String = "." if is_spanish() else ","
	var result: String = ""
	while digits.length() > 3:
		result = separator + digits.substr(digits.length() - 3) + result
		digits = digits.substr(0, digits.length() - 3)
	return digits + result

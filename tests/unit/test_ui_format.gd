extends GutTest
## Formatos de números de la interfaz en español y en inglés.

var _previous_locale: String


func before_each() -> void:
	_previous_locale = TranslationServer.get_locale()


func after_each() -> void:
	TranslationServer.set_locale(_previous_locale)


func test_money_in_spanish() -> void:
	TranslationServer.set_locale("es")
	assert_eq(UiFormat.money(25000), "$250")
	assert_eq(UiFormat.money(258000), "$2.580")
	assert_eq(UiFormat.money(750), "$7,50")
	assert_eq(UiFormat.money(-1200), "-$12")


func test_money_in_english() -> void:
	TranslationServer.set_locale("en")
	assert_eq(UiFormat.money(258000), "$2,580")
	assert_eq(UiFormat.money(750), "$7.50")


func test_durations() -> void:
	TranslationServer.set_locale("es")
	assert_eq(UiFormat.duration(20.0), "20 min")
	assert_eq(UiFormat.duration(90.0), "1 h 30 min")
	assert_eq(UiFormat.duration(300.0), "5 h")


func test_date() -> void:
	TranslationServer.set_locale("es")
	assert_eq(UiFormat.date(8 * 60.0), "Día 1 · 08:00")
	TranslationServer.set_locale("en")
	assert_eq(UiFormat.date(1440.0 + 75.0), "Day 2 · 01:15")

class_name UserSettings
extends RefCounted
## Preferencias del jugador que no son parte de la partida: qué pistas ya vio
## y la calidad gráfica (GraphicsQuality). Se guardan aparte de la partida,
## en user://settings.cfg.

const SECTION: String = "hints"
## Sección de la calidad gráfica: el modo elegido y si el automático ya bajó
## a Baja (GraphicsQuality).
const GRAPHICS_SECTION: String = "graphics"

const PLAYER_PATH: String = "user://settings.cfg"
## En las pruebas y herramientas (RunMode) se usa otro archivo, para no tocar
## el del jugador.
const TOOL_PATH: String = "user://tool_settings.cfg"

## Archivo donde se guardan. Algunas pruebas usan uno propio.
static var path: String = TOOL_PATH if RunMode.is_tool_run() else PLAYER_PATH

var _config: ConfigFile = ConfigFile.new()


static func load_settings() -> UserSettings:
	var settings: UserSettings = UserSettings.new()
	# Si el archivo no existe o está dañado, se empieza con todo en blanco.
	settings._config.load(path)
	return settings


func has_seen(hint_id: String) -> bool:
	return bool(_config.get_value(SECTION, hint_id, false))


func mark_seen(hint_id: String) -> void:
	if has_seen(hint_id):
		return
	_config.set_value(SECTION, hint_id, true)
	_config.save(path)


## Un valor de la calidad gráfica (`fallback` si no está).
func graphics_value(key: String, fallback: Variant) -> Variant:
	return _config.get_value(GRAPHICS_SECTION, key, fallback)


## Cambia un valor de la calidad gráfica y lo guarda.
func set_graphics_value(key: String, value: Variant) -> void:
	_config.set_value(GRAPHICS_SECTION, key, value)
	_config.save(path)

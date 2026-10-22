class_name UserSettings
extends RefCounted
## Preferencias del jugador que no son parte de la partida: por ahora, qué
## pistas ya vio. Se guardan aparte de la partida, en user://settings.cfg.

const SECTION: String = "hints"

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

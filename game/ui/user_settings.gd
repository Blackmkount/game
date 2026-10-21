class_name UserSettings
extends RefCounted
## Preferencias del jugador que no son parte de la partida: por ahora, qué
## pistas ya vio. Se guardan aparte de la partida, en user://settings.cfg.

const SECTION: String = "hints"

## Archivo donde se guardan. Las pruebas lo cambian para no tocar el real.
static var path: String = "user://settings.cfg"

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

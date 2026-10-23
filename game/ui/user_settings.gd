class_name UserSettings
extends RefCounted
## Preferencias del jugador que no son parte de la partida: qué pistas ya vio
## y la calidad gráfica (GraphicsQuality). Se guardan aparte de la partida,
## en user://settings.cfg.
##
## Cada parte del juego carga su copia (HintFlow, GraphicsQuality.current) y
## cada una cambia solo sus claves. Para que no se pisen, al guardar se lee
## otra vez el archivo y se cambia ahí solo la clave nueva: lo que otra copia
## guardó después de que esta lo leyó no se pierde.

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
	_store(SECTION, hint_id, true)


## Un valor de la calidad gráfica (`fallback` si no está).
func graphics_value(key: String, fallback: Variant) -> Variant:
	return _config.get_value(GRAPHICS_SECTION, key, fallback)


## Cambia un valor de la calidad gráfica y lo guarda.
func set_graphics_value(key: String, value: Variant) -> void:
	_store(GRAPHICS_SECTION, key, value)


## Cambia una clave y la guarda sobre lo que hay en el archivo ahora (otra
## copia pudo guardar algo después de que esta lo leyó). Esta copia queda con
## todo lo del archivo. Si el archivo no existe o está dañado, se guarda lo
## que tiene esta copia.
func _store(section: String, key: String, value: Variant) -> void:
	_config.set_value(section, key, value)
	var on_disk: ConfigFile = ConfigFile.new()
	if on_disk.load(path) != OK:
		_config.save(path)
		return
	on_disk.set_value(section, key, value)
	on_disk.save(path)
	_config = on_disk

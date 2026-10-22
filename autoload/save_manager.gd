extends Node
## Guardado y carga de la partida (autoload "SaveManager").
##
## - Guarda la partida de Game en `path` (user://save.json; en la web,
##   user:// vive en IndexedDB) como JSON: un sobre con "version",
##   "save_seq" (cuenta los guardados), "saved_unix" (la hora del sistema,
##   para el progreso fuera del juego que llega más adelante) y "state"
##   (SaveCodec.encode).
## - Escribe primero en `path + ".tmp"` y después lo renombra, para no
##   corromper la partida si la app se cierra a mitad de guardado. Al cargar
##   se queda con el archivo válido de mayor save_seq entre los dos: si el
##   renombre no alcanzó a ocurrir, el temporal es el más nuevo.
## - Un archivo principal dañado se aparta como `path + ".bad"` y un temporal
##   dañado se borra. Una partida de una versión más nueva del juego no se
##   carga ni se toca: el guardado se apaga por esta sesión.
## - Guarda después de cada comando y de cada avance con cambios (una vez por
##   cuadro), cada AUTOSAVE_SECONDS y cuando la app pierde el foco, pasa a
##   segundo plano o se cierra.
## - El tiempo con el juego cerrado todavía no se otorga: la partida sigue en
##   el segundo de juego guardado.
## - En las pruebas GUT (con -s o desde el panel del editor), check.sh y las
##   capturas el guardado queda apagado y nunca toca la partida del jugador
##   (RunMode).

## Cada cuánto se guarda solo, en segundos reales. Constante técnica.
const AUTOSAVE_SECONDS: float = 10.0
const DEFAULT_PATH: String = "user://save.json"
const TMP_SUFFIX: String = ".tmp"
const BAD_SUFFIX: String = ".bad"

## Archivo de la partida. Las pruebas usan uno propio.
var path: String = DEFAULT_PATH
## Apagado en las pruebas y herramientas (RunMode), o al encontrar una
## partida más nueva.
var enabled: bool = not RunMode.is_tool_run()

## Número del último guardado; sigue desde el de la partida cargada.
var _save_seq: int = 0
## Ya hay un guardado pedido para el final de este cuadro.
var _save_queued: bool = false


## Lo leído de un archivo de guardado.
class SaveFile extends RefCounted:
	var exists: bool = false
	## De una versión más nueva del juego.
	var newer: bool = false
	var save_seq: int = 0
	## null si no existe o está dañado.
	var state: GameState = null

	func is_broken() -> bool:
		return exists and not newer and state == null


func _ready() -> void:
	var timer: Timer = Timer.new()
	timer.name = "AutosaveTimer"
	timer.wait_time = AUTOSAVE_SECONDS
	timer.autostart = true
	timer.timeout.connect(save_now)
	add_child(timer)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_now()


## Pide guardar al final del cuadro. Varios pedidos en el mismo cuadro guardan
## una sola vez.
func request_save() -> void:
	if not enabled or _save_queued:
		return
	_save_queued = true
	_save_if_queued.call_deferred()


## Guarda la partida de Game ya. Devuelve si quedó guardada en `path`.
func save_now() -> bool:
	_save_queued = false
	if not enabled or Game.state == null:
		return false
	_save_seq += 1
	var envelope: Dictionary = {
		"version": SaveCodec.CURRENT_VERSION,
		"save_seq": _save_seq,
		"saved_unix": int(Time.get_unix_time_from_system()),
		"state": SaveCodec.encode(Game.state),
	}
	var tmp_path: String = path + TMP_SUFFIX
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: no se pudo abrir %s (%s)" % [tmp_path, error_string(FileAccess.get_open_error())])
		return false
	var written: bool = file.store_string(JSON.stringify(envelope))
	file.close()
	if not written:
		push_warning("SaveManager: no se pudo escribir " + tmp_path)
		return false
	var main_global: String = ProjectSettings.globalize_path(path)
	var tmp_global: String = ProjectSettings.globalize_path(tmp_path)
	if DirAccess.rename_absolute(tmp_global, main_global) != OK:
		# Algunos sistemas no renombran encima de un archivo que ya existe.
		DirAccess.remove_absolute(main_global)
		if DirAccess.rename_absolute(tmp_global, main_global) != OK:
			push_warning("SaveManager: no se pudo renombrar %s; queda el temporal para la próxima carga" % tmp_path)
			return false
	return true


## Carga la partida guardada, o devuelve null si no hay ninguna válida o el
## guardado está apagado. Ver las reglas al comienzo del archivo.
func load_state(rules: SimRules) -> GameState:
	if not enabled:
		return null
	var main: SaveFile = _read(path, rules)
	var tmp: SaveFile = _read(path + TMP_SUFFIX, rules)
	if main.newer or tmp.newer:
		enabled = false
		push_warning("SaveManager: la partida guardada es de una versión más nueva del juego; no se carga ni se guarda encima")
		return null
	if main.is_broken():
		_set_aside(path)
	if tmp.is_broken():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + TMP_SUFFIX))
	var best: SaveFile = main
	if tmp.state != null and (main.state == null or tmp.save_seq > main.save_seq):
		best = tmp
	if best.state == null:
		return null
	_save_seq = best.save_seq
	return best.state


func _save_if_queued() -> void:
	if _save_queued:
		save_now()


func _read(file_path: String, rules: SimRules) -> SaveFile:
	var file: SaveFile = SaveFile.new()
	if not FileAccess.file_exists(file_path):
		return file
	file.exists = true
	var json: JSON = JSON.new()
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK or not (json.data is Dictionary):
		push_warning("SaveManager: %s no es un JSON válido" % file_path)
		return file
	var doc: Dictionary = json.data
	var errors: Array[String] = []
	var read: SaveReader = SaveReader.new(errors)
	var version: int = read.integer(doc, "version")
	if errors.is_empty() and version > SaveCodec.CURRENT_VERSION:
		file.newer = true
		return file
	file.save_seq = read.integer(doc, "save_seq")
	var migrated: Dictionary = SaveCodec.migrate(doc)
	if migrated.is_empty():
		errors.append("'version' no es válida")
	elif errors.is_empty():
		var state_doc: Variant = migrated.get("state")
		if state_doc is Dictionary:
			file.state = SaveCodec.decode(state_doc, rules, errors)
		else:
			errors.append("'state' debe ser un objeto")
	if file.state == null:
		push_warning("SaveManager: %s está dañado: %s" % [file_path, "; ".join(PackedStringArray(errors))])
	return file


## Aparta un archivo dañado como `.bad` (reemplaza uno anterior).
func _set_aside(file_path: String) -> void:
	var bad_global: String = ProjectSettings.globalize_path(file_path + BAD_SUFFIX)
	DirAccess.remove_absolute(bad_global)
	DirAccess.rename_absolute(ProjectSettings.globalize_path(file_path), bad_global)

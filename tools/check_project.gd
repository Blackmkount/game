extends SceneTree
## Carga todos los scripts y escenas del proyecto y termina con código 1 si
## alguno tiene errores. Lo usa tools/check.sh; no se ejecuta solo.
##
## Se salta addons/ (código de terceros) y las carpetas con .gdignore.

const SKIPPED_DIRS: Array[String] = ["res://addons", "res://.godot"]
const CHECKED_EXTENSIONS: Array[String] = ["gd", "tscn", "tres"]

var _failures: Array[String] = []
var _checked: int = 0


func _initialize() -> void:
	_scan("res://")
	for failure: String in _failures:
		printerr("FALLO: ", failure)
	print("Archivos revisados: %d. Con errores: %d." % [_checked, _failures.size()])
	quit(1 if _failures.size() > 0 else 0)


func _scan(dir_path: String) -> void:
	if dir_path in SKIPPED_DIRS or FileAccess.file_exists(dir_path.path_join(".gdignore")):
		return
	for sub_dir: String in DirAccess.get_directories_at(dir_path):
		_scan(dir_path.path_join(sub_dir))
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.get_extension() in CHECKED_EXTENSIONS:
			_check_file(dir_path.path_join(file_name))


func _check_file(path: String) -> void:
	_checked += 1
	var resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if resource == null:
		_failures.append("%s no se pudo cargar" % path)
		return
	if resource is Script and not (resource as Script).can_instantiate():
		_failures.append("%s tiene errores de compilación" % path)
	elif resource is PackedScene and not (resource as PackedScene).can_instantiate():
		_failures.append("%s no se puede instanciar" % path)

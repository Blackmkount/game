extends SceneTree
## Saca capturas de la escena principal en varias situaciones. Lo usa
## tools/screenshots.sh; no se ejecuta solo.
##
## Argumentos (después de --): --out=carpeta y, opcional, --locale=en.
##
## Este guion se compila antes de que existan los autoloads (Game, Events),
## así que no usa clases del juego: carga el ejecutor cuando ya está todo.

const RUNNER: String = "res://tools/screenshot_runner.gd"


func _initialize() -> void:
	var out_dir: String = ""
	var locale: String = "es"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			out_dir = argument.trim_prefix("--out=")
		elif argument.begins_with("--locale="):
			locale = argument.trim_prefix("--locale=")
	TranslationServer.set_locale(locale)
	_start.call_deferred(out_dir)


func _start(out_dir: String) -> void:
	var runner: Node = load(RUNNER).new(out_dir)
	root.add_child(runner)

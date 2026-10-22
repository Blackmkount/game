extends SceneTree
## Saca capturas de la escena principal en varias situaciones. Lo usa
## tools/screenshots.sh; no se ejecuta solo.
##
## Argumentos (después de --): --out=carpeta y, opcionales, --locale=en,
## --only=all|art|char (qué capturas) y --quality=auto|high|low (nivel de
## calidad gráfica pedido; queda anotado en budget.csv).
##
## Este guion se compila antes de que existan los autoloads (Game, Events),
## así que no usa clases del juego: carga el ejecutor cuando ya está todo.

const RUNNER: String = "res://tools/screenshot_runner.gd"


func _initialize() -> void:
	var out_dir: String = ""
	var locale: String = "es"
	var only: String = "all"
	var quality: String = "auto"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			out_dir = argument.trim_prefix("--out=")
		elif argument.begins_with("--locale="):
			locale = argument.trim_prefix("--locale=")
		elif argument.begins_with("--only="):
			only = argument.trim_prefix("--only=")
		elif argument.begins_with("--quality="):
			quality = argument.trim_prefix("--quality=")
		else:
			push_error("Capturas: opción desconocida " + argument)
			quit(1)
			return
	TranslationServer.set_locale(locale)
	_start.call_deferred(out_dir, only, quality)


func _start(out_dir: String, only: String, quality: String) -> void:
	var runner: Node = load(RUNNER).new(out_dir, only, quality)
	root.add_child(runner)

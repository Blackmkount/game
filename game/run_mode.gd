class_name RunMode
extends RefCounted
## Si el juego se abrió para una herramienta y no para jugar: las pruebas GUT
## (desde la terminal con -s o desde el panel del editor), check.sh y las
## capturas. En ese caso no se toca nada del jugador: ni su partida ni sus
## preferencias.

## Las escenas con que el panel GUT del editor corre las pruebas viven aquí;
## el editor pasa su ruta al abrir el juego.
const GUT_PREFIX: String = "res://addons/gut/"


static func is_tool_run() -> bool:
	return is_tool_run_for(OS.get_cmdline_args())


static func is_tool_run_for(args: PackedStringArray) -> bool:
	for arg: String in args:
		if arg == "-s" or arg == "--script" or arg.begins_with(GUT_PREFIX):
			return true
	return false

class_name DeskView
extends Node
## La pantalla del computador viejo: muestra un cubo de alambre mientras se
## modela un pedido y su pantalla de siempre el resto del tiempo. Es el hijo
## "View" de la mesa del computador (RoomView lo crea).
##
## Se actualiza con Events.computer_changed, nunca en cada cuadro.

var _screen: MeshInstance3D


func _ready() -> void:
	_screen = get_parent().get_node("Monitor/Screen")
	Events.computer_changed.connect(_sync)
	Events.game_loaded.connect(_sync)
	_sync()


func _sync() -> void:
	var modeling: bool = Game.state.designing_uid >= 0
	_screen.material_override = WorldPalette.glow("ffffff", "crt_modeling" if modeling else "crt_screen")

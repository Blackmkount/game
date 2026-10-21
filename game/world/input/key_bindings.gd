class_name KeyBindings
extends RefCounted
## Teclas para probar el juego en el computador. Se registran en el InputMap
## al empezar, así no hay que editar a mano las acciones en project.godot.

const ACTIONS: Dictionary[String, Array] = {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"interact": [KEY_E, KEY_ENTER, KEY_KP_ENTER],
	"zoom_cycle": [KEY_Z],
}


static func ensure() -> void:
	for action: String in ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: int in ACTIONS[action]:
			var event: InputEventKey = InputEventKey.new()
			event.physical_keycode = key as Key
			InputMap.action_add_event(action, event)


## Dirección de las flechas o WASD en la pantalla (x a la derecha, y hacia
## abajo), con largo de 0 a 1.
static func move_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

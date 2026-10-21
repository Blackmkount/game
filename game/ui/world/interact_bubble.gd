class_name InteractBubble
extends Button
## Burbuja redonda que aparece sobre el objeto que el personaje tiene cerca.
## Al tocarla se abre su panel. Es más grande que el objeto, así que es fácil
## de tocar con el pulgar.

const SIZE: float = 88.0
## Distancia entre el objeto y la punta de abajo de la burbuja.
const LIFT: float = 12.0

var _icon_name: String = ""
var _pop: Tween


func _init() -> void:
	theme_type_variation = "IconButton"
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = Vector2(SIZE, SIZE)
	add_theme_constant_override("icon_max_width", 44)
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	focus_mode = Control.FOCUS_NONE
	pivot_offset = Vector2(SIZE / 2.0, SIZE)
	visible = false


## Muestra la burbuja con ese icono, con su esquina de arriba a la izquierda
## en `top_left` (Hud.place_bubble la ubica sobre el objeto).
func show_over(icon_name: String, top_left: Vector2) -> void:
	position = top_left
	if visible and icon_name == _icon_name:
		return
	_icon_name = icon_name
	icon = UiKit.icon_texture(icon_name)
	visible = true
	if _pop != null:
		_pop.kill()
	scale = Vector2(0.6, 0.6)
	_pop = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pop.tween_property(self, "scale", Vector2.ONE, 0.16)


func hide_bubble() -> void:
	visible = false
	_icon_name = ""


## Icono de cada tipo de objeto.
static func icon_for(item: WorldInteractable) -> String:
	match item.kind:
		WorldInteractable.Kind.PRINTER:
			return "printer"
		WorldInteractable.Kind.DOOR:
			return "map"
		WorldInteractable.Kind.SLOT:
			return "box"
	return "wrench"

class_name StatusBubbles
extends Control
## Capa de las burbujas de estado sobre los objetos del mundo (impresoras,
## computador, rincón de despacho), debajo de las demás burbujas del HUD.
##
## Cada burbuja se crea una vez por objeto (add). Después solo se mueve, se
## muestra u oculta y cambia su contenido: nada se crea en cada cuadro. Qué
## muestra cada una y dónde va lo decide StatusPresenter.

var _bubbles: Array[StatusBubble] = []
var _items: Array[WorldInteractable] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Agrega una burbuja (oculta) para `item` y devuelve su índice.
func add(item: WorldInteractable) -> int:
	var bubble: StatusBubble = StatusBubble.new()
	bubble.name = "Status%d" % _bubbles.size()
	add_child(bubble)
	_bubbles.append(bubble)
	_items.append(item)
	return _bubbles.size() - 1


## La burbuja de ese índice, para cambiar lo que muestra (set_state) o leer
## su tamaño al ubicarla.
func bubble(index: int) -> StatusBubble:
	return _bubbles[index]


## Pone la esquina de arriba a la izquierda de la burbuja en `top_left`.
func place(index: int, top_left: Vector2) -> void:
	_bubbles[index].position = top_left


func set_visible_for(index: int, shown: bool) -> void:
	_bubbles[index].visible = shown


## Objeto de la burbuja visible que está bajo `global_point`, o null. Si dos
## se tapan, gana la de encima (la última agregada).
func hit(global_point: Vector2) -> WorldInteractable:
	if not is_visible_in_tree():
		return null
	for index: int in range(_bubbles.size() - 1, -1, -1):
		if _bubbles[index].visible and _bubbles[index].hit_rect().has_point(global_point):
			return _items[index]
	return null

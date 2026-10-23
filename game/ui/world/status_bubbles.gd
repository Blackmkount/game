class_name StatusBubbles
extends Control
## Capa de las burbujas de estado sobre los objetos del mundo (impresoras,
## computador, rincón de despacho), debajo de las demás burbujas del HUD.
##
## Cada burbuja se crea una vez por objeto (add) y solo se vuelven a crear
## si cambia lo que hay en el cuarto (clear). Después solo se mueve, se
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


## Quita todas las burbujas (cambió lo que hay en el cuarto: StatusPresenter
## las vuelve a agregar).
func clear() -> void:
	for bubble: StatusBubble in _bubbles:
		bubble.free()
	_bubbles.clear()
	_items.clear()


## La burbuja de ese índice, para cambiar lo que muestra (set_state) o leer
## su tamaño al ubicarla.
func bubble(index: int) -> StatusBubble:
	return _bubbles[index]


## Pone la esquina de arriba a la izquierda de la burbuja en `top_left`.
func place(index: int, top_left: Vector2) -> void:
	_bubbles[index].position = top_left


func set_visible_for(index: int, shown: bool) -> void:
	_bubbles[index].visible = shown


## Rectángulo (coordenadas de la capa) de la primera burbuja visible que
## toca `area`, o un rectángulo vacío si ninguna: el globo de diálogo se
## corre para no taparla.
func visible_over(area: Rect2) -> Rect2:
	if not visible:
		return Rect2()
	for status: StatusBubble in _bubbles:
		if status.visible and status.get_rect().intersects(area):
			return status.get_rect()
	return Rect2()


## Objeto de la burbuja visible que está bajo `global_point`, o null. Si dos
## se tapan, gana la de encima (la última agregada).
func hit(global_point: Vector2) -> WorldInteractable:
	if not is_visible_in_tree():
		return null
	for index: int in range(_bubbles.size() - 1, -1, -1):
		if _bubbles[index].visible and _bubbles[index].hit_rect().has_point(global_point):
			return _items[index]
	return null

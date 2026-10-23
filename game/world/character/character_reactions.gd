class_name CharacterReactions
extends Node
## El personaje reacciona a lo que pasa en la partida (biblia de arte §7.8):
## escucha las señales de Events y se las cuenta al animador del personaje
## del cuarto. Cobra (puño o rascarse si llegó tarde), falla una impresión
## (manos a la cabeza de cara al jugador, mirando la impresora), sube de
## nivel (salta), llega un mensaje (mira el celular), una impresora cercana
## termina (pulgar arriba) y se modela en el computador (cara concentrada) o
## avanza el reloj (de noche bosteza). RoomView lo arma con el personaje y lo
## pone al día al cargar una partida (reset).

var _room: RoomView
## Qué impresoras tenían una pieza lista (el pulgar arriba es al terminar).
var _printers_done: Dictionary[int, bool] = {}


func _init(room: RoomView) -> void:
	_room = room
	name = "CharacterReactions"
	Events.order_delivered.connect(_on_order_delivered)
	Events.print_failed.connect(_on_print_failed)
	Events.level_up.connect(_on_level_up.unbind(1))
	Events.offer_arrived.connect(_on_offer_arrived.unbind(1))
	Events.printer_changed.connect(_on_printer_changed)
	Events.computer_changed.connect(_on_computer_changed)
	Events.time_changed.connect(_on_time_changed)


## Lo que el personaje mira de una impresora: su cabezal o, en la de resina
## (que no tiene), la placa.
static func watched_part(printer: Node3D) -> Node3D:
	for part: String in ["PrintHead", "PlateTop"]:
		var node: Node3D = printer.get_node_or_null(part)
		if node != null:
			return node
	return printer


## Partida nueva o cargada: el animador sin reacciones pendientes y al día
## (si se modela, la hora, qué impresoras ya tenían la pieza lista).
func reset() -> void:
	var animator: CharacterAnimator = _room.character.animator
	animator.reset()
	_on_computer_changed()
	animator.game_minutes = Game.state.game_minutes
	_printers_done.clear()
	for printer: OwnedPrinter in Game.state.printers:
		_printers_done[printer.uid] = OrderQueries.printer_status(Game.state, Game.rules, printer) == OrderQueries.PrinterStatus.DONE


func _on_order_delivered(_order_uid: int, _order_id: String, _cents: int, _xp: int, late: bool) -> void:
	_room.character.animator.react(CharacterAnimator.Reaction.DELIVERED_LATE if late else CharacterAnimator.Reaction.DELIVERED)


## Se agarra la cabeza de cara al jugador (se gira hacia la cámara, como al
## saludar: si estaba mirando la impresora, la cara preocupada quedaba de
## espaldas) y mira de reojo la impresora que falló. Con un panel abierto
## sigue de frente al objeto del panel.
func _on_print_failed(printer_uid: int, _failure_type: String) -> void:
	var character: CharacterController = _room.character
	character.animator.react(CharacterAnimator.Reaction.PRINT_FAILED, _print_head_of(printer_uid))
	if character.animator.current_gesture() == CharacterGestures.Gesture.HANDS_ON_HEAD and not character.animator.panel_open:
		character.face_camera()


func _on_level_up() -> void:
	_room.character.animator.react(CharacterAnimator.Reaction.LEVEL_UP)


func _on_offer_arrived() -> void:
	_room.character.animator.react(CharacterAnimator.Reaction.OFFER)


## Una impresora que termina su pieza con el personaje cerca: pulgar arriba
## para el jugador (se gira hacia la cámara, como al saludar, y la mira de
## reojo). Con un panel abierto sigue de frente al objeto del panel.
func _on_printer_changed(printer_uid: int) -> void:
	var printer: OwnedPrinter = Game.state.find_printer(printer_uid)
	if printer == null:
		return
	var done: bool = OrderQueries.printer_status(Game.state, Game.rules, printer) == OrderQueries.PrinterStatus.DONE
	var was_done: bool = _printers_done.get(printer_uid, false)
	_printers_done[printer_uid] = done
	if done and not was_done and _room.character_near(_room.item_for(WorldInteractable.Kind.PRINTER, printer_uid)):
		var character: CharacterController = _room.character
		character.animator.react(CharacterAnimator.Reaction.PRINTER_READY, _print_head_of(printer_uid))
		if character.animator.current_gesture() == CharacterGestures.Gesture.THUMBS_UP and not character.animator.panel_open:
			character.face_camera()


func _on_computer_changed() -> void:
	_room.character.animator.modeling = Game.state.designing_uid >= 0


## Sabe qué hora es (bosteza de noche).
func _on_time_changed(game_minutes: float) -> void:
	_room.character.animator.game_minutes = game_minutes


## Dónde está lo que se mira de una impresora (o el personaje, si ya no está).
func _print_head_of(printer_uid: int) -> Vector3:
	var printer: Node3D = _room.get_node_or_null("Printer%d" % printer_uid)
	return watched_part(printer).global_position if printer != null else _room.character.model.position

class_name DispatchView
extends Node
## Lo que se ve en el rincón de despacho: una caja abierta en la mesa por cada
## pedido con las piezas retiradas (con la pieza de su color asomando) y un
## paquete con cinta en el cajón por cada pedido embalado. Al despachar, el
## paquete se desliza hacia la puerta y se achica. Es el hijo "View" del
## rincón (RoomView lo crea).
##
## Las cajas y los paquetes se arman una sola vez, escondidos, y después solo
## se muestran o se esconden. Se actualiza con las señales de Events, nunca en
## cada cuadro, y no crea nada más que animaciones.

const POP_SCALE: float = 0.6
const POP_TIME: float = 0.2
## El paquete despachado sale hacia la puerta (−X) y se achica casi a nada
## (escala 0 deja la transformación sin inversa).
const SLIDE_DISTANCE: float = 0.4
const SLIDE_TIME: float = 0.35
const GONE_SCALE: float = 0.01
## uid de un lugar libre y de un paquete que va saliendo.
const FREE: int = -1
const LEAVING: int = -2

var _boxes: Array[Node3D] = []
var _box_pieces: Array[MeshInstance3D] = []
var _box_uids: Array[int] = []
var _box_tweens: Array[Tween] = []
var _packages: Array[Node3D] = []
var _package_uids: Array[int] = []
var _package_tweens: Array[Tween] = []
## Los paquetes no tienen pieza a la vista que teñir.
var _no_pieces: Array[MeshInstance3D] = []
var _sync_queued: bool = false
## Lo que aparece salta (0,6 → 1), salvo al armar la habitación o al cargar.
var _animate: bool = false


func _ready() -> void:
	var corner: Node3D = get_parent()
	for i: int in DispatchCornerModel.PACK_SPOTS:
		var box: Node3D = PackageModel.open_box(corner.get_node("PackSpot%d" % i), "OpenBox")
		box.visible = false
		_boxes.append(box)
		_box_pieces.append(box.get_node("Piece"))
		_box_uids.append(FREE)
		_box_tweens.append(null)
	for i: int in DispatchCornerModel.OUT_SPOTS:
		var package: Node3D = PackageModel.package(corner.get_node("OutSpot%d" % i), "Package")
		package.visible = false
		_packages.append(package)
		_package_uids.append(FREE)
		_package_tweens.append(null)
	Events.order_changed.connect(_on_order_event)
	Events.order_removed.connect(_on_order_event)
	Events.order_delivered.connect(_on_order_delivered)
	Events.game_loaded.connect(_on_game_loaded)
	_sync()


## Se espera al final del cuadro: al despachar, order_removed llega antes que
## order_delivered, y el paquete tiene que seguir ahí para salir.
func _queue_sync() -> void:
	if _sync_queued:
		return
	_sync_queued = true
	_sync.call_deferred()


func _sync() -> void:
	_sync_queued = false
	_fill(_boxes, _box_uids, _box_tweens, _box_pieces, Order.Stage.TO_PACK)
	_fill(_packages, _package_uids, _package_tweens, _no_pieces, Order.Stage.PACKED)
	_animate = true


## Esconde lo que muestra un pedido que ya no está en `stage` y muestra en los
## lugares libres, en orden de uid, los pedidos en `stage` que no se ven
## todavía. Si `pieces` no está vacío, tiñe la pieza con el color del pedido.
func _fill(items: Array[Node3D], uids: Array[int], tweens: Array[Tween], pieces: Array[MeshInstance3D], stage: Order.Stage) -> void:
	var state: GameState = Game.state
	for i: int in items.size():
		if uids[i] < 0:
			continue
		var shown: Order = state.find_order(uids[i])
		if shown == null or shown.stage != stage:
			uids[i] = FREE
			items[i].visible = false
	for order: Order in state.orders:
		if order.stage != stage or uids.has(order.uid):
			continue
		var slot: int = uids.find(FREE)
		if slot < 0:
			return
		uids[slot] = order.uid
		if not pieces.is_empty():
			pieces[slot].material_override = WorldPalette.solid(PieceModel.filament_hex(Game.rules, order.color_id))
		_appear(items[slot], tweens, slot)


func _appear(item: Node3D, tweens: Array[Tween], slot: int) -> void:
	item.visible = true
	if tweens[slot] != null:
		tweens[slot].kill()
		tweens[slot] = null
	if not _animate:
		item.scale = Vector3.ONE
		return
	item.scale = Vector3.ONE * POP_SCALE
	tweens[slot] = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tweens[slot].tween_property(item, "scale", Vector3.ONE, POP_TIME)


func _on_order_event(_order_uid: int) -> void:
	_queue_sync()


## El paquete del pedido despachado sale por la puerta; después el lugar
## queda libre.
func _on_order_delivered(order_uid: int, _order_id: String, _cents: int, _xp: int, _late: bool) -> void:
	var slot: int = _package_uids.find(order_uid)
	if slot < 0:
		return
	_package_uids[slot] = LEAVING
	var package: Node3D = _packages[slot]
	if _package_tweens[slot] != null:
		_package_tweens[slot].kill()
	var tween: Tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(package, "position:x", -SLIDE_DISTANCE, SLIDE_TIME)
	tween.tween_property(package, "scale", Vector3.ONE * GONE_SCALE, SLIDE_TIME)
	tween.chain().tween_callback(_on_package_gone.bind(slot))
	_package_tweens[slot] = tween


func _on_package_gone(slot: int) -> void:
	var package: Node3D = _packages[slot]
	package.visible = false
	package.position = Vector3.ZERO
	package.scale = Vector3.ONE
	_package_uids[slot] = FREE
	_package_tweens[slot] = null
	_queue_sync()


## Partida nueva o cargada: todo vuelve a armarse sin animación.
func _on_game_loaded() -> void:
	_clear(_boxes, _box_uids, _box_tweens)
	_clear(_packages, _package_uids, _package_tweens)
	_animate = false
	_sync()


func _clear(items: Array[Node3D], uids: Array[int], tweens: Array[Tween]) -> void:
	for i: int in items.size():
		if tweens[i] != null:
			tweens[i].kill()
			tweens[i] = null
		items[i].visible = false
		items[i].position = Vector3.ZERO
		items[i].scale = Vector3.ONE
		uids[i] = FREE

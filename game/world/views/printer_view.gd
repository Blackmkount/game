class_name PrinterView
extends Node
## Lo que se ve de una impresora según su trabajo. Es el hijo "View" del
## modelo de la impresora (RoomView lo crea).
##
## - La pantallita cambia de color: libre, imprimiendo, lista o con falla.
## - El carrete toma el color del filamento que se usa.
## - En las impresoras abiertas (las que tienen "Bed"), la pieza crece sobre la
##   cama capa a capa, el cabezal va y viene mientras imprime, las piezas
##   terminadas esperan en una bandeja al frente y la pieza lista da un saltito.
##   Si falla, la pieza queda a medias y oscura (torcida si es warping).
##
## Se actualiza con Events.printer_changed y Events.clock_ticked, nunca en
## cada cuadro. Las cerradas y las de resina solo cambian la pantallita.

enum Shown { IDLE, PRINTING, DONE, FAILED }

## Textura de la pantallita en cada caso.
const DISPLAY_TEXTURES: Dictionary[Shown, String] = {
	Shown.IDLE: "printer_display",
	Shown.PRINTING: "printer_display_busy",
	Shown.DONE: "printer_display_done",
	Shown.FAILED: "printer_display_error",
}
## Medidas del modelo con escala 1 (PrinterModel._open_frame), en metros. Se
## multiplican por la escala de la impresora.
const BED_TOP: float = 0.11
const PIECE_Z: float = 0.03
const HEAD_REST_Y: float = 0.25
## Espacio entre la punta de la pieza y el centro del cabezal.
const HEAD_CLEARANCE: float = 0.045
## El cabezal va de -HEAD_SWING a +HEAD_SWING mientras imprime.
const HEAD_SWING: float = 0.06
const HEAD_SWING_TIME: float = 1.2
## Donde se estaciona el cabezal con la pieza lista o fallada: a un lado, para
## que la pieza se vea entera.
const HEAD_PARK_X: float = -0.15
## Bandeja de piezas terminadas, al frente sobre la base.
const TRAY_BLOCKS: int = 6
const TRAY_BLOCK: float = 0.05
const TRAY_START_X: float = -0.15
const TRAY_GAP: float = 0.06
const TRAY_BASE_Y: float = 0.08
const TRAY_Z: float = 0.18
## Saltito de la pieza lista.
const HOP_HEIGHT: float = 0.04
const HOP_TIME: float = 0.25
## Inclinación de una pieza que se despegó (warping).
const WARP_TILT_DEGREES: float = 12.0

var printer_uid: int

var _scale: float
var _display: MeshInstance3D
var _filament: MeshInstance3D
var _idle_filament: Material
var _head: Node3D
var _gantry: Node3D
var _head_rest: Vector3
## Base de la pieza (sobre la cama): gira con el warping y salta al terminar.
var _piece_spot: Node3D
var _piece: MeshInstance3D
var _tray: Array[MeshInstance3D] = []
var _job: PrintJob
## Lo que se mostró la última vez; -1 = todavía nada (no da el saltito).
var _shown: int = -1
var _size_id: String = ""
var _piece_hex: String = ""
## Alto de la pieza dibujado; se cambia la malla solo si el alto cambia.
var _height: float = -1.0
var _swing: Tween
var _hop: Tween


func _init(p_printer_uid: int, model_scale: float) -> void:
	printer_uid = p_printer_uid
	_scale = model_scale


func _ready() -> void:
	var model: Node3D = get_parent()
	_display = model.get_node_or_null("Display")
	_filament = model.get_node_or_null("Spool/Filament")
	if _filament != null:
		_idle_filament = _filament.material_override
	if model.has_node("Bed"):
		_build_piece_parts(model)
	Events.printer_changed.connect(_on_printer_changed)
	Events.clock_ticked.connect(_on_clock_ticked)
	Events.game_loaded.connect(_on_game_loaded)
	_sync()


func _build_piece_parts(model: Node3D) -> void:
	_head = model.get_node("PrintHead")
	_gantry = model.get_node("Gantry")
	_head_rest = _head.position
	_piece_spot = PropBuilder.group(model, "PieceSpot", Vector3(0.0, BED_TOP, PIECE_Z) * _scale)
	_piece = PieceModel.build(_piece_spot, "Piece")
	for i: int in TRAY_BLOCKS:
		var position: Vector3 = Vector3((TRAY_START_X + i * TRAY_GAP) * _scale, TRAY_BASE_Y * _scale + TRAY_BLOCK / 2.0, TRAY_Z * _scale)
		var block: MeshInstance3D = PropBuilder.box(model, "Tray%d" % i, Vector3.ONE * TRAY_BLOCK, position, WorldPalette.solid(WorldPalette.PLASTIC_BEIGE))
		block.visible = false
		_tray.append(block)


## Pone todo como está el trabajo de la impresora ahora.
func _sync() -> void:
	var printer: OwnedPrinter = Game.state.find_printer(printer_uid)
	_job = printer.job if printer != null else null
	var shown: Shown = _shown_for(_job)
	if _display != null:
		_display.material_override = WorldPalette.glow("ffffff", DISPLAY_TEXTURES[shown])
	if _filament != null:
		_filament.material_override = _idle_filament if _job == null else WorldPalette.solid(PieceModel.filament_hex(Game.rules, _job.color_id))
	if _piece != null:
		_sync_piece(shown)
		if shown == Shown.DONE and _shown == Shown.PRINTING:
			_jump()
	_shown = shown


func _sync_piece(shown: Shown) -> void:
	_set_swing(shown == Shown.PRINTING)
	if _job == null:
		if _hop != null:
			_hop.kill()
			_hop = null
		_piece.visible = false
		_piece_spot.position.y = BED_TOP * _scale
		_piece_spot.rotation = Vector3.ZERO
		_show_tray(0)
		_height = -1.0
		_place_head(0.0, false)
		return
	var order: Order = Game.state.find_order(_job.order_uid)
	var definition: Dictionary = Game.rules.orders.get(order.order_id, {}) if order != null else {}
	_size_id = definition.get("size", "")
	var hex: String = PieceModel.filament_hex(Game.rules, _job.color_id)
	_piece_hex = WorldPalette.FAILED_PIECE if shown == Shown.FAILED else hex
	var tilted: bool = shown == Shown.FAILED and _job.failure_type == FailureRules.WARPING
	_piece_spot.rotation_degrees = Vector3(WARP_TILT_DEGREES if tilted else 0.0, 0.0, 0.0)
	# Las piezas terminadas esperan en la bandeja; la última, ya lista, se
	# queda en la cama.
	var finished: int = order.pieces_done if order != null else 0
	if shown == Shown.DONE:
		finished -= 1
	for block: MeshInstance3D in _tray:
		block.material_override = WorldPalette.solid(hex)
	_show_tray(mini(finished, TRAY_BLOCKS))
	_piece.visible = true
	_height = -1.0
	_grow()


## Alto de la pieza según su avance, de a una capa (PieceModel.LAYER_STEP).
## La pieza lista tiene su alto completo.
func _grow() -> void:
	var full: float = PieceModel.full_size(_size_id).y
	var height: float = full
	if _job.status != PrintJob.Status.DONE:
		var step: float = PieceModel.LAYER_STEP
		height = floorf(_job.progress_at(Game.state.game_seconds) * full / step) * step
	if height == _height:
		return
	_height = height
	PieceModel.set_shape(_piece, _size_id, _piece_hex, height, _job.status == PrintJob.Status.PRINTING)
	_place_head(height, _job.status != PrintJob.Status.PRINTING)


## Sube el cabezal y su barra sobre la pieza; estacionado, se corre a un lado.
func _place_head(piece_height: float, parked: bool) -> void:
	var y: float = maxf(HEAD_REST_Y * _scale, (BED_TOP + HEAD_CLEARANCE) * _scale + piece_height)
	_head.position.y = y
	_gantry.position.y = y
	if _swing == null:
		_head.position.x = HEAD_PARK_X * _scale if parked else _head_rest.x


func _set_swing(on: bool) -> void:
	if on == (_swing != null):
		return
	if not on:
		_swing.kill()
		_swing = null
		return
	_head.position.x = -HEAD_SWING * _scale
	_swing = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_swing.tween_property(_head, "position:x", HEAD_SWING * _scale, HEAD_SWING_TIME)
	_swing.tween_property(_head, "position:x", -HEAD_SWING * _scale, HEAD_SWING_TIME)


func _show_tray(count: int) -> void:
	for i: int in _tray.size():
		_tray[i].visible = i < count


## Saltito de la pieza recién terminada.
func _jump() -> void:
	if _hop != null:
		_hop.kill()
	var base: float = BED_TOP * _scale
	_piece_spot.position.y = base
	_hop = create_tween().set_trans(Tween.TRANS_SINE)
	_hop.tween_property(_piece_spot, "position:y", base + HOP_HEIGHT, HOP_TIME / 2.0).set_ease(Tween.EASE_OUT)
	_hop.tween_property(_piece_spot, "position:y", base, HOP_TIME / 2.0).set_ease(Tween.EASE_IN)


static func _shown_for(job: PrintJob) -> Shown:
	if job == null:
		return Shown.IDLE
	match job.status:
		PrintJob.Status.PRINTING:
			return Shown.PRINTING
		PrintJob.Status.DONE:
			return Shown.DONE
	return Shown.FAILED


func _on_printer_changed(uid: int) -> void:
	if uid == printer_uid:
		_sync()


func _on_clock_ticked(_game_seconds: int) -> void:
	if _piece != null and _shown == Shown.PRINTING:
		_grow()


## Partida nueva o cargada: se muestra como está, sin saltito.
func _on_game_loaded() -> void:
	_shown = -1
	_sync()

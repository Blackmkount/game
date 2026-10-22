class_name PrinterView
extends Node
## Lo que se ve de una impresora según su trabajo. Es el hijo "View" del
## modelo de la impresora (RoomView lo crea).
##
## - La pantallita cambia: libre, imprimiendo, lista o con falla.
## - El carrete toma el color del filamento que se usa.
## - En las impresoras abiertas (las que tienen "Bed"), la pieza crece sobre la
##   cama capa a capa con la capa caliente arriba, el cabezal va y viene
##   mientras imprime, las piezas terminadas esperan en una bandeja al frente
##   y la pieza lista da un saltito y suelta unos destellos. Si falla, la
##   pieza queda a medias y oscura: con warping, despegada y torcida; con
##   espagueti, con el nido de hilos encima y el cabezal sobre él.
##
## Dónde va cada cosa lo dicen los marcadores del modelo (PieceAnchor,
## HeadRest, HeadPark, TrayAnchor; ver PrinterModel). Los modelos que todavía
## no los tienen usan las constantes de abajo × su escala.
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
## Medidas de las impresoras abiertas con escala 1, en metros, para los
## modelos sin marcadores (se multiplican por la escala de la impresora). En
## la Cubo Uno sus marcadores valen esto mismo.
const BED_TOP: float = 0.11
const PIECE_Z: float = 0.03
const HEAD_REST_Y: float = 0.25
## Espacio entre la punta de la pieza y el centro del cabezal.
const HEAD_CLEARANCE: float = 0.045
## El cabezal va de -HEAD_SWING a +HEAD_SWING (sobre la pieza) mientras
## imprime.
const HEAD_SWING: float = 0.06
const HEAD_SWING_TIME: float = 1.2
## Donde se estaciona el cabezal con la pieza lista o despegada: a un lado,
## para que la pieza se vea entera.
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
## Una pieza que se despegó (warping) se inclina hacia atrás y se le levanta
## una esquina; su esquina más baja queda apoyada en la cama.
const WARP_TILT_DEGREES: float = 12.0
const WARP_ROLL_DEGREES: float = 7.0

var printer_uid: int

var _scale: float
var _display: MeshInstance3D
var _filament: MeshInstance3D
var _idle_filament: Material
var _head: Node3D
var _gantry: Node3D
## Base de la pieza sobre la cama (PieceAnchor), el cabezal quieto
## (HeadRest) y estacionado (HeadPark, solo su x).
var _anchor: Vector3
var _head_rest: Vector3
var _head_park_x: float
## Base de la pieza: gira con el warping y salta al terminar.
var _piece_spot: Node3D
var _piece: MeshInstance3D
var _spaghetti: MeshInstance3D
var _sparkles: ReadySparkles
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
	_anchor = _marker(model, "PieceAnchor", Vector3(0.0, BED_TOP, PIECE_Z) * _scale)
	# Sin marcador, el cabezal está quieto donde lo dejó el modelo.
	_head_rest = _marker(model, "HeadRest", _head.position)
	_head_park_x = _marker(model, "HeadPark", Vector3(HEAD_PARK_X * _scale, 0.0, 0.0)).x
	var tray: Vector3 = _marker(model, "TrayAnchor", Vector3(TRAY_START_X, TRAY_BASE_Y, TRAY_Z) * _scale)
	_piece_spot = PropBuilder.group(model, "PieceSpot", _anchor)
	_piece = PieceModel.build(_piece_spot, "Piece")
	_spaghetti = PieceModel.build_spaghetti(_piece_spot, "Spaghetti")
	_spaghetti.scale = Vector3.ONE * _scale
	_sparkles = ReadySparkles.new()
	_piece_spot.add_child(_sparkles)
	for i: int in TRAY_BLOCKS:
		var position: Vector3 = tray + Vector3(i * TRAY_GAP * _scale, TRAY_BLOCK / 2.0, 0.0)
		var block: MeshInstance3D = PropBuilder.box(model, "Tray%d" % i, Vector3.ONE * TRAY_BLOCK, position, WorldPalette.solid(WorldPalette.PLASTIC_BEIGE))
		block.visible = false
		_tray.append(block)


## Lugar de un marcador del modelo, o `fallback` si el modelo no lo tiene.
static func _marker(model: Node3D, marker_name: String, fallback: Vector3) -> Vector3:
	var marker: Node3D = model.get_node_or_null(marker_name)
	return marker.position if marker != null else fallback


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
			_celebrate()
	_shown = shown


func _sync_piece(shown: Shown) -> void:
	_set_swing(shown == Shown.PRINTING)
	if _job == null:
		if _hop != null:
			_hop.kill()
			_hop = null
		_sparkles.stop()
		_piece.visible = false
		_spaghetti.visible = false
		_piece_spot.position = _anchor
		_piece_spot.rotation = Vector3.ZERO
		_show_tray(0)
		_height = -1.0
		_place_head(0.0)
		return
	var order: Order = Game.state.find_order(_job.order_uid)
	var definition: Dictionary = Game.rules.orders.get(order.order_id, {}) if order != null else {}
	_size_id = definition.get("size", "")
	var hex: String = PieceModel.filament_hex(Game.rules, _job.color_id)
	_piece_hex = WorldPalette.FAILED_PIECE if shown == Shown.FAILED else hex
	_spaghetti.visible = _is_spaghetti()
	if _spaghetti.visible:
		_spaghetti.material_override = PieceModel.spaghetti_material(hex)
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
	_spaghetti.position.y = maxf(height, PieceModel.MIN_HEIGHT)
	_tilt_if_warped()
	_place_head(height)


## Warping: la pieza se inclina y se le levanta una esquina, con la esquina
## más baja apoyada en la cama. Si no, derecha sobre la cama.
func _tilt_if_warped() -> void:
	var warped: bool = _job.status == PrintJob.Status.FAILED and _job.failure_type == FailureRules.WARPING
	if not warped:
		_piece_spot.rotation = Vector3.ZERO
		_piece_spot.position = _anchor
		return
	_piece_spot.rotation_degrees = Vector3(WARP_TILT_DEGREES, 0.0, WARP_ROLL_DEGREES)
	var half: Vector3 = PieceModel.full_size(_size_id) / 2.0
	var lowest: float = 0.0
	for x: float in [-half.x, half.x]:
		for z: float in [-half.z, half.z]:
			lowest = minf(lowest, (_piece_spot.basis * Vector3(x, 0.0, z)).y)
	_piece_spot.position = _anchor - Vector3(0.0, lowest, 0.0)


## Sube el cabezal y su barra sobre la pieza. Imprimiendo va y viene; quieto,
## en su lugar; con la pieza lista o despegada se estaciona a un lado; con
## espagueti se queda sobre el nido, de donde salen las hebras.
func _place_head(piece_height: float) -> void:
	var y: float = maxf(_head_rest.y, _anchor.y + HEAD_CLEARANCE * _scale + piece_height)
	var x: float = _head_rest.x
	if _is_spaghetti():
		y = maxf(y, _anchor.y + piece_height + (PieceModel.SPAGHETTI_RISE + HEAD_CLEARANCE) * _scale)
		x = _anchor.x
	elif _job != null and _job.status != PrintJob.Status.PRINTING:
		x = _head_park_x
	_head.position.y = y
	_gantry.position.y = y
	if _swing == null:
		_head.position.x = x


func _is_spaghetti() -> bool:
	return _job != null and _job.status == PrintJob.Status.FAILED and _job.failure_type == FailureRules.SPAGHETTI


func _set_swing(on: bool) -> void:
	if on == (_swing != null):
		return
	if not on:
		_swing.kill()
		_swing = null
		return
	var middle: float = _anchor.x
	_head.position.x = middle - HEAD_SWING * _scale
	_swing = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_swing.tween_property(_head, "position:x", middle + HEAD_SWING * _scale, HEAD_SWING_TIME)
	_swing.tween_property(_head, "position:x", middle - HEAD_SWING * _scale, HEAD_SWING_TIME)


func _show_tray(count: int) -> void:
	for i: int in _tray.size():
		_tray[i].visible = i < count


## La pieza recién terminada da un saltito y suelta sus destellos.
func _celebrate() -> void:
	if _hop != null:
		_hop.kill()
	var base: float = _anchor.y
	_piece_spot.position.y = base
	_hop = create_tween().set_trans(Tween.TRANS_SINE)
	_hop.tween_property(_piece_spot, "position:y", base + HOP_HEIGHT, HOP_TIME / 2.0).set_ease(Tween.EASE_OUT)
	_hop.tween_property(_piece_spot, "position:y", base, HOP_TIME / 2.0).set_ease(Tween.EASE_IN)
	_sparkles.play(Vector3(0.0, PieceModel.full_size(_size_id).y, 0.0))


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

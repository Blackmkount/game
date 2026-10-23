class_name PrinterView
extends Node
## Lo que se ve de una impresora según su trabajo. Es el hijo "View" del
## modelo de la impresora (RoomView lo crea).
##
## - La pantallita cambia: libre, imprimiendo, lista o con falla.
## - El carrete (o la resina) toma el color del filamento que se usa.
## - En TODAS las familias la pieza crece capa a capa, con la capa caliente
##   donde crece, y la falla se ve. Cómo, depende del modo del modelo (ver
##   PrinterModel), que la vista reconoce por sus partes:
##   - abiertas ("Bed"): la pieza crece sobre la cama, el cabezal y su barra
##     suben con ella y el cabezal va y viene;
##   - cerradas ("Platform"): el cabezal va y viene arriba y la cama baja; la
##     luz de adentro cambia con el estado (cálida, verde, roja);
##   - de resina ("Plate"): la pieza cuelga de la placa, que sube, y crece
##     hacia abajo (la capa caliente queda abajo, sobre la resina); si falla,
##     cae a la tina.
## - Las piezas terminadas esperan en una bandeja; la pieza lista da un
##   saltito (menos la de resina, que cuelga) y suelta unos destellos. Si
##   falla, queda a medias y oscura: con warping, despegada y torcida; con
##   espagueti, con el nido de hilos encima y el cabezal sobre él.
## - De noche, un halo en el piso del color del estado (HaloField).
## - Con el zoom lejos (set_far, biblia §5.2 y §13), las de los muebles
##   pasan a su versión lejana: "Body" con su malla de menos detalle
##   (PrinterModel.far_body) y escondido lo que va adentro de esa malla o se
##   mueve: barra y cabezal; el carrete y la resina (en la malla, del color
##   del primer carrete); la cama de las cerradas y la placa de la de resina,
##   que van quietas en la malla (la de las cerradas abajo, la placa arriba:
##   la pieza crece sobre la cama o cuelga de la placa y crece hacia abajo);
##   y la pantallita, que se dibuja con las de todas en un solo MultiMesh
##   (DisplayField, attach_display). La pieza que crece con su capa caliente,
##   el espagueti, la tapa ámbar transparente de la de resina, la luz de
##   adentro de las cerradas y el primer bloquecito de la bandeja se siguen
##   viendo. Los nodos siguen existiendo. La del piso (la estrella, una
##   sola) se ve siempre completa.
## - Como dice la biblia §2.6, en las impresoras de los muebles solo "Body"
##   da sombra: la pieza, el espagueti y la bandeja, no.
##
## Dónde va cada cosa lo dicen los marcadores del modelo. Se actualiza con
## Events.printer_changed y Events.clock_ticked, nunca en cada cuadro.

enum Shown { IDLE, PRINTING, DONE, FAILED }
enum Mode { OPEN, CLOSED, RESIN }

## Textura de la pantallita en cada caso.
const DISPLAY_TEXTURES: Dictionary[Shown, String] = {
	Shown.IDLE: "printer_display",
	Shown.PRINTING: "printer_display_busy",
	Shown.DONE: "printer_display_done",
	Shown.FAILED: "printer_display_error",
}
## Color del halo de noche y de la luz de adentro de las cerradas en cada
## caso (biblia §9.2). Sin trabajo, el halo se apaga; imprimiendo, las
## cerradas usan su propia luz (PrinterModel.interior_hex).
const STATE_COLORS: Dictionary[Shown, String] = {
	Shown.PRINTING: LookPalette.STATE_PRINTING,
	Shown.DONE: LookPalette.STATE_DONE,
	Shown.FAILED: LookPalette.STATE_FAILED,
}
## Medidas de la impresora de referencia (la Cubo Uno pone ahí sus
## marcadores: CuboUnoModel), en metros.
const BED_TOP: float = 0.11
const PIECE_Z: float = 0.03
const HEAD_REST_Y: float = 0.25
## Espacio entre la punta de la pieza y el centro del cabezal (× escala).
const HEAD_CLEARANCE: float = 0.045
## El cabezal va de -HEAD_SWING a +HEAD_SWING (sobre la pieza) mientras
## imprime.
const HEAD_SWING: float = 0.06
const HEAD_SWING_TIME: float = 1.2
## Donde se estaciona el cabezal de la Cubo Uno con la pieza lista o
## despegada: a un lado, para que la pieza se vea entera.
const HEAD_PARK_X: float = -0.15
## Bandeja de piezas terminadas: bloquecitos uno al lado del otro desde el
## marcador "TrayAnchor" (en la Cubo Uno, al frente sobre la caja de control).
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
## La pieza de resina que falla cae a la tina, inclinada.
const RESIN_FALL_DEGREES: Vector3 = Vector3(16.0, 20.0, -22.0)

var printer_uid: int

var _scale: float
## La pieza, el espagueti y la bandeja dan sombra (solo en la del piso).
var _casts_shadow: bool
## Si tiene versión lejana (las de los muebles; la del piso, no).
var _goes_far: bool
var _printer_id: String
var _spool_color: String
## "Body" y sus dos mallas (la de siempre y la lejana); lo que se esconde
## con el zoom lejos; si está en la versión lejana.
var _body: MeshInstance3D
var _near_mesh: Mesh
var _far_mesh: Mesh
var _far_hidden: Array[Node3D] = []
var _far: bool = false
var _mode: Mode = Mode.OPEN
var _lit_hex: String
var _display: MeshInstance3D
var _filament: MeshInstance3D
var _idle_filament: Material
var _head: Node3D
var _gantry: Node3D
## Cerradas: la cama que baja, la luz de adentro y su material sin trabajo.
var _platform: Node3D
var _interior: MeshInstance3D
var _idle_interior: Material
## Resina: la placa que sube y el fondo de la tina.
var _plate: Node3D
var _vat_floor: float
## Base de la pieza al empezar (PieceAnchor), el cabezal quieto (HeadRest) y
## estacionado (HeadPark, solo su x), y el lugar de reposo de la cama
## (cerradas, PlatformLow) o de la placa (resina, PlateTop).
var _anchor: Vector3
var _head_rest: Vector3
var _head_park_x: float
var _rest_y: float
## Base de la pieza: gira con el warping y salta al terminar.
var _piece_spot: Node3D
var _piece: MeshInstance3D
var _spaghetti: MeshInstance3D
var _sparkles: ReadySparkles
var _tray: Array[MeshInstance3D] = []
## Cuántos bloquecitos de la bandeja se muestran (sin el zoom lejos).
var _tray_count: int = 0
## Los halos de noche del cuarto y el número del de esta impresora (-1: sin
## halo; lo pone RoomView con attach_halo).
var _halos: HaloField
var _halo: int = -1
## Las pantallitas de la versión lejana y el número de la de esta impresora
## (-1: sin; lo pone RoomView con attach_display).
var _displays: DisplayField
var _display_slot: int = -1
var _job: PrintJob
## Lo que se mostró la última vez; -1 = todavía nada (no da el saltito).
var _shown: int = -1
var _size_id: String = ""
var _piece_hex: String = ""
## Alto de la pieza dibujado; se cambia la malla solo si el alto cambia.
var _height: float = -1.0
var _swing: Tween
var _hop: Tween


## `spool_color` y `detail`: con los que se armó el modelo (PrinterModel.build).
func _init(p_printer_uid: int, printer_id: String, spool_color: String, detail: float) -> void:
	printer_uid = p_printer_uid
	_printer_id = printer_id
	_spool_color = spool_color
	_casts_shadow = detail >= PrinterParts.FLOOR_DETAIL
	_goes_far = detail < PrinterParts.FLOOR_DETAIL
	_scale = PrinterModel.frame_scale(printer_id)
	_lit_hex = PrinterModel.interior_hex(printer_id)


func _ready() -> void:
	var model: Node3D = get_parent()
	_display = model.get_node("Display")
	_body = model.get_node("Body")
	_near_mesh = _body.mesh
	# La malla lejana se arma ahora (en caché), nunca durante un cuadro.
	if _goes_far:
		_far_mesh = PrinterModel.far_body(_printer_id, _spool_color)
	_filament = model.get_node_or_null("Spool/Filament")
	if _filament == null:
		_filament = model.get_node_or_null("Resin")
	if _filament != null:
		_idle_filament = _filament.material_override
	_anchor = _marker(model, "PieceAnchor")
	if model.has_node("Platform"):
		_mode = Mode.CLOSED
		_platform = model.get_node("Platform")
		_interior = model.get_node("Interior")
		_idle_interior = _interior.material_override
		_rest_y = _marker(model, "PlatformLow").y
	elif model.has_node("Plate"):
		_mode = Mode.RESIN
		_plate = model.get_node("Plate")
		_rest_y = _marker(model, "PlateTop").y
		_vat_floor = _marker(model, "VatFloor").y
	if _mode != Mode.RESIN:
		_head = model.get_node("PrintHead")
		_gantry = model.get_node_or_null("Gantry")
		_head_rest = _marker(model, "HeadRest")
		_head_park_x = _marker(model, "HeadPark").x
	_build_piece_parts(model)
	_far_hidden = _far_parts(model)
	Events.printer_changed.connect(_on_printer_changed)
	Events.clock_ticked.connect(_on_clock_ticked)
	Events.game_loaded.connect(_on_game_loaded)
	_sync()


func _build_piece_parts(model: Node3D) -> void:
	var tray: Vector3 = _marker(model, "TrayAnchor")
	_piece_spot = PropBuilder.group(model, "PieceSpot", _anchor)
	_piece = PieceModel.build(_piece_spot, "Piece")
	if _mode == Mode.RESIN:
		# Crece hacia abajo: la capa nueva (la caliente) queda abajo.
		_piece.rotation_degrees = Vector3(180.0, 0.0, 0.0)
	_spaghetti = PieceModel.build_spaghetti(_piece_spot, "Spaghetti")
	_spaghetti.scale = Vector3.ONE * _scale
	_sparkles = ReadySparkles.new()
	_piece_spot.add_child(_sparkles)
	for i: int in TRAY_BLOCKS:
		var position: Vector3 = tray + Vector3(i * TRAY_GAP * _scale, TRAY_BLOCK / 2.0, 0.0)
		var block: MeshInstance3D = PropBuilder.box(model, "Tray%d" % i, Vector3.ONE * TRAY_BLOCK, position, WorldPalette.solid(WorldPalette.PLASTIC_BEIGE))
		block.visible = false
		_tray.append(block)
	if not _casts_shadow:
		for part: MeshInstance3D in [_piece, _spaghetti] + _tray:
			part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Lo que se esconde con el zoom lejos, según el modo: lo que se mueve, lo
## que va en la malla lejana (el carrete, la resina, la cama de las cerradas,
## la placa) y la pantallita (va en DisplayField).
func _far_parts(model: Node3D) -> Array[Node3D]:
	var names: Array[String] = []
	match _mode:
		Mode.OPEN:
			names = ["Gantry", "PrintHead", "Spool", "Display"]
		Mode.CLOSED:
			names = ["PrintHead", "Platform", "Display"]
		Mode.RESIN:
			names = ["Plate", "Resin", "Display"]
	var parts: Array[Node3D] = []
	for part_name: String in names:
		var part: Node3D = model.get_node_or_null(part_name)
		if part != null:
			parts.append(part)
	return parts


## La versión lejana (zoom lejos) o la de siempre. Los nodos no cambian:
## solo la malla de "Body", lo que se ve y dónde va la pieza (sobre la cama o
## bajo la placa quietas de la malla lejana). La del piso no cambia.
func set_far(far: bool) -> void:
	far = far and _goes_far
	if far == _far:
		return
	_far = far
	_body.mesh = _far_mesh if far else _near_mesh
	for part: Node3D in _far_hidden:
		part.visible = not far
	_show_tray(_tray_count)
	_place(_height if _job != null else 0.0)


## Si está en la versión lejana.
func is_far() -> bool:
	return _far


## Pone el halo de noche de la impresora en `field`, bajo la huella de
## "Body" (en el espacio del padre de los halos) y del color de su estado.
## RoomView los vuelve a poner todos, en orden, cada vez que cambia lo que hay
## en el cuarto.
func attach_halo(field: HaloField) -> void:
	_halos = field
	var model: Node3D = get_parent()
	# La malla de siempre: el halo no cambia con el zoom.
	var body: AABB = _near_mesh.get_aabb()
	var center: Vector3 = body.get_center()
	var base: Transform3D = field.get_parent_node_3d().global_transform.affine_inverse() * model.global_transform * Transform3D(Basis.IDENTITY, Vector3(center.x, 0.0, center.z))
	_halo = field.add(base, Vector2(body.size.x, body.size.z))
	_color_halo(_shown_for(_job))


## Pone la pantallita de la versión lejana en `field` (en el espacio del
## padre de las pantallitas), con lo que muestra ahora. La del piso no tiene
## versión lejana. RoomView las vuelve a poner todas cada vez que cambia lo
## que hay en el cuarto.
func attach_display(field: DisplayField) -> void:
	_displays = field
	_display_slot = -1
	if not _goes_far:
		return
	var at: Transform3D = field.get_parent_node_3d().global_transform.affine_inverse() * _display.global_transform
	_display_slot = field.add(at, (_display.mesh as QuadMesh).size, _screen_mode(_shown_for(_job)))


## El modo de screen.gdshader de la pantallita en cada caso.
static func _screen_mode(shown: Shown) -> int:
	return WorldPalette.SCREEN_MODES[DISPLAY_TEXTURES[shown]]


## El halo del color del estado (sin trabajo, apagado).
func _color_halo(shown: Shown) -> void:
	if _halo >= 0:
		_halos.set_color(_halo, Color(STATE_COLORS[shown]) if STATE_COLORS.has(shown) else HaloField.OFF)


## Lugar de un marcador del modelo.
static func _marker(model: Node3D, marker_name: String) -> Vector3:
	return (model.get_node(marker_name) as Node3D).position


## Pone todo como está el trabajo de la impresora ahora.
func _sync() -> void:
	var printer: OwnedPrinter = Game.state.find_printer(printer_uid)
	_job = printer.job if printer != null else null
	var shown: Shown = _shown_for(_job)
	_display.material_override = WorldPalette.glow("ffffff", DISPLAY_TEXTURES[shown])
	if _display_slot >= 0:
		_displays.set_mode(_display_slot, _screen_mode(shown))
	if _filament != null:
		_filament.material_override = _idle_filament if _job == null else WorldPalette.solid(PieceModel.filament_hex(Game.rules, _job.color_id))
	if _interior != null:
		_interior.material_override = _interior_material(shown)
	_color_halo(shown)
	_sync_piece(shown)
	if shown == Shown.DONE and _shown == Shown.PRINTING:
		_celebrate()
	_shown = shown


## La luz de adentro de una cerrada: la tenue de siempre sin trabajo, la
## suya imprimiendo, verde lista y roja con falla.
func _interior_material(shown: Shown) -> Material:
	match shown:
		Shown.IDLE:
			return _idle_interior
		Shown.PRINTING:
			return WorldPalette.glow(_lit_hex)
	return WorldPalette.glow(STATE_COLORS[shown])


func _sync_piece(shown: Shown) -> void:
	_set_swing(shown == Shown.PRINTING)
	if _job == null:
		if _hop != null:
			_hop.kill()
			_hop = null
		_sparkles.stop()
		_piece.visible = false
		_spaghetti.visible = false
		_show_tray(0)
		_height = -1.0
		_place(0.0)
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
	# queda en la impresora.
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
	_place(height)


## Pone la pieza, el cabezal, la cama o la placa para una pieza de este alto
## (0 sin trabajo), según el modo.
func _place(height: float) -> void:
	match _mode:
		Mode.OPEN:
			_rest_piece(_anchor)
			_place_head(height, _anchor.y + HEAD_CLEARANCE * _scale + height)
		Mode.CLOSED:
			# La cama baja para que la pieza (y el nido, si hay espagueti)
			# termine justo bajo la boquilla, que no se mueve de altura. Con
			# el zoom lejos la cama queda abajo (en la malla lejana) y la
			# pieza crece sobre ella.
			var bed: float = _rest_y
			if _job != null and not _far:
				bed = _anchor.y - height
				if _is_spaghetti():
					bed -= PieceModel.SPAGHETTI_RISE * _scale
				bed = maxf(bed, _rest_y)
			_platform.position.y = bed
			_rest_piece(Vector3(_anchor.x, bed, _anchor.z))
			_place_head(height, _head_rest.y)
		Mode.RESIN:
			_place_resin(height)


## La pieza derecha en `base` o, con warping, torcida con su esquina más
## baja apoyada en `base`.
func _rest_piece(base: Vector3) -> void:
	var warped: bool = _job != null and _job.status == PrintJob.Status.FAILED and _job.failure_type == FailureRules.WARPING
	if not warped:
		_piece_spot.rotation = Vector3.ZERO
		_piece_spot.position = base
		return
	_tilt_onto(base, Vector3(WARP_TILT_DEGREES, 0.0, WARP_ROLL_DEGREES))


## Gira la pieza `degrees` y la apoya en `base` por su esquina más baja.
func _tilt_onto(base: Vector3, degrees: Vector3) -> void:
	_piece_spot.rotation_degrees = degrees
	var half: Vector3 = PieceModel.full_size(_size_id) / 2.0
	var lowest: float = 0.0
	for x: float in [-half.x, half.x]:
		for z: float in [-half.z, half.z]:
			lowest = minf(lowest, (_piece_spot.basis * Vector3(x, 0.0, z)).y)
	_piece_spot.position = base - Vector3(0.0, lowest, 0.0)


## Resina: imprimiendo, la placa sube con la pieza colgando (su borde de
## arriba pegado a la placa, su base sobre la resina). Lista o sin trabajo,
## la placa arriba del todo (con la pieza colgando). Si falló, la placa
## arriba y la pieza caída en la tina. Con el zoom lejos la placa queda
## arriba (en la malla lejana) y la pieza cuelga de ella y crece hacia abajo.
func _place_resin(height: float) -> void:
	var plate: float = _rest_y
	if _job != null and _job.status == PrintJob.Status.PRINTING and not _far:
		plate = _anchor.y + height
	_plate.position.y = plate
	if _job != null and _job.status == PrintJob.Status.FAILED:
		_tilt_onto(Vector3(_anchor.x, _vat_floor, _anchor.z), RESIN_FALL_DEGREES)
		return
	_piece_spot.rotation = Vector3.ZERO
	_piece_spot.position = Vector3(_anchor.x, plate - height, _anchor.z)


## El cabezal (y su barra, en las abiertas) a la altura `y`, nunca más abajo
## que su lugar de reposo. Imprimiendo va y viene; quieto, en su lugar; con la
## pieza lista o despegada se estaciona a un lado; con espagueti se queda
## sobre el nido, de donde salen las hebras.
func _place_head(piece_height: float, y: float) -> void:
	y = maxf(_head_rest.y, y)
	var x: float = _head_rest.x
	if _is_spaghetti():
		if _mode == Mode.OPEN:
			y = maxf(y, _anchor.y + piece_height + (PieceModel.SPAGHETTI_RISE + HEAD_CLEARANCE) * _scale)
		x = _anchor.x
	elif _job != null and _job.status != PrintJob.Status.PRINTING:
		x = _head_park_x
	_head.position.y = y
	if _gantry != null:
		_gantry.position.y = y
	if _swing == null:
		_head.position.x = x


func _is_spaghetti() -> bool:
	return _mode != Mode.RESIN and _job != null and _job.status == PrintJob.Status.FAILED and _job.failure_type == FailureRules.SPAGHETTI


func _set_swing(on: bool) -> void:
	on = on and _head != null
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


## Los primeros `count` bloquecitos de la bandeja. Con el zoom lejos, solo
## el primero: avisa que el pedido va por partes con una sola llamada.
func _show_tray(count: int) -> void:
	_tray_count = count
	for i: int in _tray.size():
		_tray[i].visible = i < count and (i == 0 or not _far)


## La pieza recién terminada da un saltito (la de resina no: cuelga) y suelta
## sus destellos.
func _celebrate() -> void:
	if _mode != Mode.RESIN:
		if _hop != null:
			_hop.kill()
		var base: float = _piece_spot.position.y
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
	if _shown == Shown.PRINTING:
		_grow()


## Partida nueva o cargada: se muestra como está, sin saltito.
func _on_game_loaded() -> void:
	_shown = -1
	_sync()

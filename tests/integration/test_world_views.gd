extends GutTest
## Lo que se ve en el mundo durante el ciclo de pedidos: la pantalla del
## computador al modelar, la pieza que crece en la impresora, la bandeja, la
## pieza que falla y las cajas del rincón de despacho (PrinterView, DeskView y
## DispatchView).

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
## Cada prueba empieza con la misma partida nueva.
const SEED: int = 1234

var _main: Control
var _room: RoomView
var _previous_processing: bool


func before_each() -> void:
	_previous_processing = Game.is_processing()
	# La partida solo avanza cuando la prueba lo pide.
	Game.set_process(false)
	Game.reset_game(SEED)
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	await wait_process_frames(2)
	_room = _main.get_node("WorldView/SubViewport/Room")


func after_each() -> void:
	Game.set_process(_previous_processing)


func test_the_computer_screen_shows_the_model_only_while_designing() -> void:
	var screen: MeshInstance3D = _room.get_node("Furniture%d/Monitor/Screen" % Game.state.furniture[0].uid)
	assert_eq(screen.material_override, WorldPalette.glow("ffffff", "crt_screen"))
	Game.advance(3.0)
	Game.accept_offer(Game.state.offers[0].uid)
	assert_eq(screen.material_override, WorldPalette.glow("ffffff", "crt_modeling"), "Modela apenas se acepta")
	Game.advance(10.0)
	assert_eq(Game.state.orders[0].stage, Order.Stage.READY_TO_PRINT)
	assert_eq(screen.material_override, WorldPalette.glow("ffffff", "crt_screen"), "Vuelve a la pantalla de siempre")


func test_the_piece_grows_one_layer_at_a_time_and_never_shrinks() -> void:
	var printer: Node3D = _printer_node()
	var piece: MeshInstance3D = printer.get_node("PieceSpot/Piece")
	assert_false(piece.visible, "Sin trabajo no hay pieza")
	_start_keychain()
	assert_eq(_display().material_override, WorldPalette.glow("ffffff", "printer_display_busy"))
	var step: float = PieceModel.LAYER_STEP
	var previous: float = 0.0
	var shrank: Array[String] = []
	var off_layer: Array[String] = []
	# Un segundo por vez hasta la mitad. A mitad de camino cambia el zoom: el
	# alto de la capa ya no depende de la cámara.
	for second: int in range(1, 26):
		if second == 12:
			_room.camera.set_zoom_index(0)
			_room.camera.snap_to_goal()
		Game.advance(1.0)
		var shown: float = _height(piece)
		if shown < previous:
			shrank.append("%d s: %.4f → %.4f" % [second, previous, shown])
		# Antes de la primera capa la caja mide lo mínimo.
		if not is_equal_approx(shown, PieceModel.MIN_HEIGHT) and absf(shown - roundf(shown / step) * step) > 0.0001:
			off_layer.append("%d s: %.4f" % [second, shown])
		previous = shown
	assert_eq(shrank, [] as Array[String], "La pieza nunca baja")
	assert_eq(off_layer, [] as Array[String], "Crece de a una capa entera")
	var height: float = _height(piece)
	assert_true(piece.visible)
	assert_between(height, step, PieceModel.SIZES["S"].y - step, "Va por la mitad")
	Game.advance(10.0)
	assert_gt(_height(piece), height, "Siguió creciendo con el reloj")
	var head: Node3D = printer.get_node("PrintHead")
	var head_x: float = head.position.x
	await wait_seconds(0.2)
	assert_ne(head.position.x, head_x, "El cabezal va y viene")


func test_a_finished_piece_hops_and_waits_at_full_height() -> void:
	var printer: Node3D = _printer_node()
	var piece: MeshInstance3D = printer.get_node("PieceSpot/Piece")
	var spot: Node3D = printer.get_node("PieceSpot")
	_start_keychain()
	Game.advance(51.0)
	assert_eq(Game.state.printers[0].job.status, PrintJob.Status.DONE)
	assert_almost_eq(_height(piece), PieceModel.SIZES["S"].y, 0.0001, "Alto completo")
	assert_eq(_display().material_override, WorldPalette.glow("ffffff", "printer_display_done"))
	assert_false(printer.get_node("Tray0").visible, "La única pieza se queda en la cama")
	assert_almost_eq(printer.get_node("PrintHead").position.x, PrinterView.HEAD_PARK_X, 0.0001, "Cabezal estacionado a un lado")
	await wait_process_frames(2)
	assert_gt(spot.position.y, PrinterView.BED_TOP, "Da un saltito")
	await wait_seconds(PrinterView.HOP_TIME + 0.1)
	assert_almost_eq(spot.position.y, PrinterView.BED_TOP, 0.0001, "Y vuelve a la cama")
	assert_true(Game.remove_pieces(Game.state.printers[0].uid).ok)
	assert_false(piece.visible, "Retirada, la cama queda vacía")
	assert_eq(_display().material_override, WorldPalette.glow("ffffff", "printer_display"))


func test_finished_pieces_of_a_longer_order_wait_on_the_tray() -> void:
	var printer: Node3D = _printer_node()
	var state: GameState = Game.state
	var spool: Spool = Spool.new(state.take_uid(), "petg", "rojo", 1000)
	state.spools.append(spool)
	var offer: OrderOffer = OrderOffer.new(state.take_uid(), "perilla", state.game_seconds)
	state.offers.append(offer)
	assert_true(Game.accept_offer(offer.uid).ok)
	Game.advance(76.0)
	var printer_uid: int = state.printers[0].uid
	assert_true(Game.start_print(offer.uid, printer_uid, spool.uid, "normal").ok)
	var red: Material = WorldPalette.solid(Game.rules.colors["rojo"]["hex"])
	assert_eq(printer.get_node("Spool/Filament").material_override, red, "El carrete toma el color del filamento")
	# Cada pieza tarda 50 min de juego (125 s reales).
	Game.advance(130.0)
	assert_eq(state.find_order(offer.uid).pieces_done, 1)
	assert_true(printer.get_node("Tray0").visible, "La primera pieza espera en la bandeja")
	assert_eq((printer.get_node("Tray0") as MeshInstance3D).material_override, red)
	assert_false(printer.get_node("Tray1").visible)
	assert_true(printer.get_node("PieceSpot/Piece").visible, "La segunda crece en la cama")
	Game.advance(125.0)
	assert_eq(state.printers[0].job.status, PrintJob.Status.DONE)
	assert_true(printer.get_node("Tray0").visible)
	assert_false(printer.get_node("Tray1").visible, "La última se queda en la cama")


func test_a_failed_piece_stays_dark_and_a_warped_one_tilts() -> void:
	var printer: Node3D = _printer_node()
	var piece: MeshInstance3D = printer.get_node("PieceSpot/Piece")
	var spot: Node3D = printer.get_node("PieceSpot")
	var printer_uid: int = Game.state.printers[0].uid
	_start_keychain()
	assert_true(DebugTools.force_fail(Game.sim, printer_uid, FailureRules.WARPING))
	# Falla al 35% de 1.200 gs: 420 gs, 17,5 s reales.
	Game.advance(20.0)
	assert_eq(Game.state.printers[0].job.status, PrintJob.Status.FAILED)
	assert_true(piece.visible)
	assert_eq(piece.material_override, WorldPalette.solid(WorldPalette.FAILED_PIECE))
	assert_almost_eq(spot.rotation_degrees.x, PrinterView.WARP_TILT_DEGREES, 0.001, "El warping la despega torcida")
	assert_eq(_display().material_override, WorldPalette.glow("ffffff", "printer_display_error"))
	var height: float = _height(piece)
	assert_between(height, 0.001, PieceModel.SIZES["S"].y * 0.5, "Quedó a medias")
	Game.advance(10.0)
	assert_eq(_height(piece), height, "No sigue creciendo")
	assert_true(Game.clean_printer(printer_uid).ok)
	assert_false(piece.visible)
	assert_eq(spot.rotation_degrees.x, 0.0)


func test_the_hot_layer_rides_on_top_of_the_growing_piece() -> void:
	var piece: MeshInstance3D = _printer_node().get_node("PieceSpot/Piece")
	_start_keychain()
	var hex: String = PieceModel.filament_hex(Game.rules, Game.state.printers[0].job.color_id)
	var checked: int = 0
	for second: int in range(1, 30):
		Game.advance(1.0)
		var height: float = _height(piece)
		if height < PieceModel.LAYER_STEP:
			continue
		assert_eq(piece.material_override, WorldPalette.printing(hex), "Mientras se imprime, con la capa caliente")
		var hot: float = piece.get_instance_shader_parameter(&"hot_top")
		assert_almost_eq(hot, height / 2.0, 0.0001, "En el borde de arriba (la malla va centrada)")
		var spot: Node3D = piece.get_parent()
		var hot_world: float = (piece.global_transform * Vector3(0.0, hot, 0.0)).y
		assert_almost_eq(hot_world, spot.global_position.y + height, 0.0001, "En el mundo, el borde de arriba de la pieza")
		checked += 1
	assert_gt(checked, 10, "Se revisó capa por capa")
	Game.advance(30.0)
	assert_eq(Game.state.printers[0].job.status, PrintJob.Status.DONE)
	assert_eq(piece.material_override, WorldPalette.solid(hex), "Terminada, sin capa caliente")


func test_a_spaghetti_failure_shows_the_nest_in_the_filament_color() -> void:
	var printer: Node3D = _printer_node()
	var nest: MeshInstance3D = printer.get_node("PieceSpot/Spaghetti")
	var piece: MeshInstance3D = printer.get_node("PieceSpot/Piece")
	var spot: Node3D = printer.get_node("PieceSpot")
	var head: Node3D = printer.get_node("PrintHead")
	var printer_uid: int = Game.state.printers[0].uid
	assert_false(nest.visible, "Sin falla no hay espagueti")
	_start_keychain()
	var hex: String = PieceModel.filament_hex(Game.rules, Game.state.printers[0].job.color_id)
	assert_true(DebugTools.force_fail(Game.sim, printer_uid, FailureRules.SPAGHETTI))
	Game.advance(20.0)
	assert_eq(Game.state.printers[0].job.status, PrintJob.Status.FAILED)
	assert_true(nest.visible, "El nido se ve sin abrir el panel")
	assert_eq(nest.material_override, PieceModel.spaghetti_material(hex), "Del color del filamento")
	assert_eq(piece.material_override, WorldPalette.solid(WorldPalette.FAILED_PIECE), "Sobre la pieza fallida")
	var height: float = _height(piece)
	assert_almost_eq(nest.position.y, height, 0.0001, "El nido arriba de la pieza")
	assert_almost_eq(head.position.x, spot.position.x, 0.0001, "El cabezal se quedó sobre el nido")
	assert_almost_eq(head.position.y - PrinterView.HEAD_CLEARANCE, spot.position.y + height + PieceModel.SPAGHETTI_RISE, 0.0001, "Las hebras llegan a la boquilla")
	assert_true(Game.clean_printer(printer_uid).ok)
	assert_false(nest.visible, "Limpia, sin espagueti")
	assert_eq(head.position, (printer.get_node("HeadRest") as Node3D).position, "El cabezal vuelve a su lugar")


func test_a_warped_piece_lifts_a_corner_and_makes_no_spaghetti() -> void:
	var printer: Node3D = _printer_node()
	var spot: Node3D = printer.get_node("PieceSpot")
	_start_keychain()
	assert_true(DebugTools.force_fail(Game.sim, Game.state.printers[0].uid, FailureRules.WARPING))
	Game.advance(20.0)
	assert_eq(Game.state.printers[0].job.status, PrintJob.Status.FAILED)
	assert_false(printer.get_node("PieceSpot/Spaghetti").visible, "El warping no hace espagueti")
	var half: Vector3 = PieceModel.full_size("S") / 2.0
	var corners: Array[float] = []
	for x: float in [-half.x, half.x]:
		for z: float in [-half.z, half.z]:
			corners.append((spot.transform * Vector3(x, 0.0, z)).y)
	assert_almost_eq(corners.min(), PrinterView.BED_TOP, 0.0005, "La esquina más baja sigue en la cama")
	assert_gt(corners.max(), PrinterView.BED_TOP + 0.02, "Una esquina se levantó")
	assert_almost_eq(printer.get_node("PrintHead").position.x, PrinterView.HEAD_PARK_X, 0.0001, "El cabezal se apartó")


func test_a_finished_piece_sparkles_once_and_a_loaded_one_does_not() -> void:
	var sparkles: ReadySparkles = _printer_node().get_node("PieceSpot/Sparkles")
	_start_keychain()
	Game.advance(25.0)
	var almost: GameState = _copy(Game.state)
	assert_false(sparkles.visible)
	Game.advance(26.0)
	assert_eq(Game.state.printers[0].job.status, PrintJob.Status.DONE)
	assert_true(sparkles.visible, "La pieza lista suelta sus destellos")
	await wait_seconds(ReadySparkles.DURATION + 0.15)
	assert_false(sparkles.visible, "Y se apagan solos")
	Simulation.new(almost, Game.rules).advance(30.0)
	Game._start(almost)
	await wait_process_frames(2)
	assert_false(sparkles.visible, "Al cargar una partida con la pieza ya lista, sin destellos")


func test_the_floor_printer_is_placed_by_its_markers() -> void:
	var printer: Node3D = _printer_node()
	var anchor: Node3D = printer.get_node("PieceAnchor")
	assert_eq(printer.get_node("PieceSpot").position, anchor.position, "La pieza donde dice el modelo")
	var tray: Vector3 = (printer.get_node("TrayAnchor") as Node3D).position
	for i: int in PrinterView.TRAY_BLOCKS:
		var expected: Vector3 = tray + Vector3(i * PrinterView.TRAY_GAP, PrinterView.TRAY_BLOCK / 2.0, 0.0)
		assert_almost_eq((printer.get_node("Tray%d" % i) as Node3D).position, expected, Vector3.ONE * 0.0001, "Tray%d" % i)
	var led: Vector3 = _room.day_cycle._light_positions.get("printer_led", Vector3.ZERO)
	assert_almost_eq(led, (printer.get_node("BedLight") as Node3D).global_position, Vector3.ONE * 0.0001, "La luz de la cama sale de su barra LED")


func test_the_dispatch_corner_shows_a_box_then_a_package_that_leaves() -> void:
	var corner: Node3D = _room.get_node("DispatchCorner")
	var box: Node3D = corner.get_node("PackSpot0/OpenBox")
	var package: Node3D = corner.get_node("OutSpot0/Package")
	assert_false(box.visible)
	assert_false(package.visible)
	var order: Order = _start_keychain()
	Game.advance(51.0)
	assert_true(Game.remove_pieces(Game.state.printers[0].uid).ok)
	await wait_process_frames(1)
	assert_true(box.visible, "Caja abierta en la mesa")
	var white: Material = WorldPalette.solid(Game.rules.colors["blanco"]["hex"])
	assert_eq((box.get_node("Piece") as MeshInstance3D).material_override, white, "Con la pieza de su color")
	assert_false(corner.get_node("PackSpot1/OpenBox").visible)
	assert_true(Game.pack_order(order.uid).ok)
	await wait_process_frames(1)
	assert_false(box.visible)
	assert_true(package.visible, "Paquete en el cajón")
	await wait_seconds(DispatchView.POP_TIME + 0.1)
	assert_eq(package.scale, Vector3.ONE)
	assert_true(Game.dispatch_order(order.uid).ok)
	await wait_seconds(DispatchView.SLIDE_TIME / 2.0)
	assert_true(package.visible, "Sale hacia la puerta")
	assert_lt(package.position.x, 0.0)
	assert_lt(package.scale.x, 1.0)
	await wait_seconds(DispatchView.SLIDE_TIME)
	assert_false(package.visible)
	assert_eq(package.position, Vector3.ZERO, "Listo para el próximo paquete")
	assert_eq(package.scale, Vector3.ONE)


func test_a_new_game_clears_what_the_world_shows() -> void:
	var piece: MeshInstance3D = _printer_node().get_node("PieceSpot/Piece")
	_start_keychain()
	Game.advance(51.0)
	assert_true(piece.visible)
	Game.reset_game(SEED)
	assert_false(piece.visible, "La partida nueva no tiene la pieza")
	assert_eq(_display().material_override, WorldPalette.glow("ffffff", "printer_display"))
	var box: Node3D = _room.get_node("DispatchCorner/PackSpot0/OpenBox")
	_start_keychain()
	Game.advance(51.0)
	assert_true(Game.remove_pieces(Game.state.printers[0].uid).ok)
	await wait_process_frames(1)
	assert_true(box.visible)
	Game.reset_game(SEED)
	assert_false(box.visible, "Ni la caja abierta")


func test_a_loaded_game_is_drawn_as_it_is_without_animations() -> void:
	var spot: Node3D = _printer_node().get_node("PieceSpot")
	var order: Order = _start_keychain()
	Game.advance(25.0)
	# La partida que se carga ya tiene la pieza lista: no salta.
	var done: GameState = _copy(Game.state)
	Simulation.new(done, Game.rules).advance(30.0)
	Game._start(done)
	assert_eq(Game.state.printers[0].job.status, PrintJob.Status.DONE)
	await wait_process_frames(2)
	assert_almost_eq(spot.position.y, PrinterView.BED_TOP, 0.0001, "Sin saltito al cargar")
	assert_true(Game.remove_pieces(Game.state.printers[0].uid).ok)
	await wait_process_frames(1)
	# La misma caja, pero la partida cargada dice otro color.
	var red: GameState = _copy(Game.state)
	red.find_order(order.uid).color_id = "rojo"
	Game._start(red)
	var piece: MeshInstance3D = _room.get_node("DispatchCorner/PackSpot0/OpenBox/Piece")
	assert_eq(piece.material_override, WorldPalette.solid(Game.rules.colors["rojo"]["hex"]))


## Lleva el primer mensaje (el llavero) hasta la impresora con el plan
## recomendado y devuelve el pedido. El modelo tarda 240 gs (10 s reales) y la
## pieza, 1.200 gs (50 s reales).
func _start_keychain() -> Order:
	Game.advance(3.0)
	var offer_uid: int = Game.state.offers[0].uid
	assert_true(Game.accept_offer(offer_uid).ok)
	var order: Order = Game.state.find_order(offer_uid)
	Game.advance(10.0)
	var plan: PrintPlan = PrintPlanner.recommend(Game.state, Game.rules, order)
	assert_true(Game.start_print(order.uid, plan.printer_uid, plan.spool_uid, plan.mode_id).ok)
	return order


## Copia de la partida pasando por el guardado, como al cargar.
func _copy(state: GameState) -> GameState:
	var errors: Array[String] = []
	var copy: GameState = SaveCodec.decode(SaveCodec.encode(state), Game.rules, errors)
	assert_true(errors.is_empty(), str(errors))
	return copy


func _printer_node() -> Node3D:
	return _room.get_node("Printer%d" % Game.state.printers[0].uid)


func _display() -> MeshInstance3D:
	return _printer_node().get_node("Display")


func _height(piece: MeshInstance3D) -> float:
	return PieceModel.shown_height(piece)

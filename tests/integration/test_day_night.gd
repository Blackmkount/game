extends GutTest
## El día y la noche en el cuarto (Arte 2.0, paso 13; biblia de arte §6):
## una partida cargada de noche se ve de noche de una vez; el reloj del juego
## mueve la luz mezclándose; de noche se encienden la lámpara y el monitor
## del escritorio (con sus halos), la guirnalda parpadea y el borde de la
## base apenas brilla.

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
const SEED: int = 1234
## Uid del escritorio en una partida nueva.
const DESK_UID: int = 1
const NIGHT_HOUR: float = 22.0
## Una hora en medio del paso de la mañana al mediodía (10:30–12:30).
const MIDDAY_SHIFT_HOUR: float = 11.0

var _main: Control
var _room: RoomView
var _previous_processing: bool


func before_each() -> void:
	_previous_processing = Game.is_processing()
	Game.set_process(false)


func after_each() -> void:
	Game.set_process(_previous_processing)


func test_a_game_saved_at_night_loads_at_night_without_blending() -> void:
	var state: GameState = GameState.new_game(Game.rules, SEED)
	state.game_seconds = roundi(NIGHT_HOUR * GameClock.SECONDS_PER_HOUR)
	await _load(state)
	var cycle: DayCycle = _room.day_cycle
	assert_false(cycle.is_blending(), "Al cargar, la hora de una vez")
	assert_almost_eq(cycle.shown_hour(), NIGHT_HOUR, 0.001)
	assert_true(_room.halos.visible, "De noche se ven los halos")
	assert_false(_room.decor.dust.visible, "Y no hay polvo en el haz")
	assert_eq(WorldPalette.glow("ffffff", WorldPalette.WINDOW_VIEW).get_shader_parameter("mood"), Vector3(0.0, 0.0, 1.0), "Por la ventana, la noche")
	var sun: DirectionalLight3D = _room.get_node("Sun")
	assert_eq(sun.light_color, Color("9ab0ff"), "El sol es la luna")
	# Una partida nueva (la mañana) también va de una vez.
	Game.reset_game(SEED)
	assert_false(cycle.is_blending())
	assert_almost_eq(cycle.shown_hour(), Game.state.game_minutes / GameClock.MINUTES_PER_HOUR, 0.001)
	assert_false(_room.halos.visible, "De día no")


func test_the_game_clock_moves_the_light_without_jumps() -> void:
	await _load(GameState.new_game(Game.rules, SEED))
	var cycle: DayCycle = _room.day_cycle
	var start: float = cycle.shown_hour()
	var minutes: float = MIDDAY_SHIFT_HOUR * GameClock.MINUTES_PER_HOUR - Game.state.game_minutes
	Game.advance(minutes * GameClock.SECONDS_PER_MINUTE / Game.rules.game_seconds_per_real_second)
	var hour: float = Game.state.game_minutes / GameClock.MINUTES_PER_HOUR
	assert_true(cycle.is_blending(), "El reloj llegó a otra luz: se mezcla")
	assert_almost_eq(cycle.shown_hour(), start, 0.001, "Nada saltó todavía")
	cycle.step(DayCycle.BLEND_SECONDS)
	assert_false(cycle.is_blending())
	assert_almost_eq(cycle.shown_hour(), hour, 0.001, "Llegó a la hora del reloj")


func test_the_desk_lamp_and_the_monitor_leave_a_halo_at_night() -> void:
	await _load(GameState.new_game(Game.rules, SEED))
	var halos: HaloField = _room.halos
	var desk: Node3D = _room.get_node("Furniture%d" % DESK_UID)
	# Los de las impresoras van primero (una en una partida nueva); después,
	# los del escritorio.
	var printers: int = Game.state.printers.size()
	var pool: Transform3D = halos.transform_of(printers)
	var bulb: Vector3 = (desk.get_node("LampBulb") as Node3D).global_position
	assert_lt(Vector2(pool.origin.x, pool.origin.z).distance_to(Vector2(bulb.x, bulb.z)), 0.15, "La mancha de la lámpara, bajo la ampolleta")
	assert_almost_eq(pool.origin.y, ComputerDeskModel.TABLE_SIZE.y + HaloField.LIFT, 0.001, "Sobre la mesa")
	assert_eq(halos.color_of(printers), Color(LookPalette.LAMP_HALO) * ComputerDeskModel.LAMP_POOL_STRENGTH)
	var glow: Transform3D = halos.transform_of(printers + 1)
	var screen: Node3D = desk.get_node("Monitor/Screen")
	var facing: Vector3 = screen.global_basis.z.normalized()
	assert_gt(glow.basis.y.normalized().dot(facing), 0.99, "El resplandor del monitor mira hacia donde mira la pantalla")
	var ahead: float = (glow.origin - screen.global_position).dot(facing)
	assert_between(ahead, 0.0, 0.03, "Justo delante de la pantalla")
	assert_eq(halos.color_of(printers + 1), Color(LookPalette.MONITOR_HALO) * ComputerDeskModel.SCREEN_HALO_STRENGTH)
	for i: int in printers + 2:
		assert_false(halos.twinkles(i), "Las impresoras y el escritorio no parpadean")


## Biblia §8.9: la guirnalda parpadea suave de noche, cada foco con su halo.
func test_only_the_string_lights_twinkle() -> void:
	await _load(GameState.new_game(Game.rules, SEED))
	var halos: HaloField = _room.halos
	var bulbs: PackedVector3Array = DecorWall.garland_bulbs()
	var twinkling: int = 0
	for i: int in halos.count():
		if halos.twinkles(i):
			twinkling += 1
			var at: Vector3 = halos.transform_of(i).origin
			assert_lt(_nearest(bulbs, at), 0.02, "Un halo que parpadea es el de un foco")
	assert_eq(twinkling, bulbs.size(), "Un halo que parpadea por foco")
	# En la malla de la pared, solo los focos tienen la marca de parpadeo, y
	# son luz de noche.
	var wall: ArrayMesh = (_room.get_node("Decor/Wall0") as MeshInstance3D).mesh
	var arrays: Array = wall.surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var uv2s: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
	var marked: int = 0
	for v: int in positions.size():
		if uvs[v].y < 0.0:
			marked += 1
			assert_eq(uvs[v].y, KitMesh.TWINKLE)
			assert_lt(uv2s[v].y, 0.0, "Lo que parpadea es luz de noche")
			assert_lt(_nearest(bulbs, positions[v]), 0.04, "Y está en un foco")
	assert_gt(marked, 0, "Los focos parpadean")


## Biblia §4.1: el borde de primera capa de la base apenas brilla de noche.
func test_the_brim_of_the_base_glows_a_little_at_night() -> void:
	await _load(GameState.new_game(Game.rules, SEED))
	var shell: ArrayMesh = (_room.get_node("RoomShell/Shell") as MeshInstance3D).mesh
	var arrays: Array = shell.surface_get_arrays(0)
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var uv2s: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
	var brim: Color = Color(LookPalette.BASE_BRIM)
	var found: int = 0
	for v: int in colors.size():
		if Color(colors[v].r, colors[v].g, colors[v].b).is_equal_approx(brim):
			found += 1
			assert_almost_eq(uv2s[v].y, -RoomShell.BRIM_NIGHT_GLOW, 0.0001, "Luz propia solo de noche")
	assert_gt(found, 0, "El brim está en la malla del cuarto")


func _load(state: GameState) -> void:
	Game._start(state)
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	await wait_process_frames(2)
	_room = _main.get_node("WorldView/SubViewport/Room")


static func _nearest(points: PackedVector3Array, at: Vector3) -> float:
	var best: float = INF
	for point: Vector3 in points:
		best = minf(best, point.distance_to(at))
	return best

extends GutTest
## Presupuesto de dibujo del mundo (CLAUDE.md, "Rendimiento móvil"; biblia de
## arte §13), medido sin pantalla con tests/helpers/scene_budget.gd sobre
## Main/WorldView/SubViewport/Room (y las luces y lo que no se sabe medir,
## sobre todo el SubViewport).
##
## Dos cuartos: el de la partida nueva y el más cargado de hoy
## (DebugTools.fill_workshop: escritorio, impresora del piso y 5 estanterías
## metálicas con 3 impresoras cada una, de todas las familias), también con
## trabajos en cada estado (DebugTools.give_jobs, la captura 43). Con la
## calidad gráfica Alta (la de siempre) y también en Baja; el cuarto lleno
## también con el zoom lejos (las impresoras en su versión lejana).
##
## Topes: los de triángulos ya son los finales de la biblia (y el lleno queda
## bajo los 100.000 de CLAUDE.md). Los demás parten de lo medido el
## 2026-10-22 más un margen chico, y cada paso de Arte 2.0 los baja a lo que
## mide más un 10 %, nunca por encima del tope anterior, hasta los finales de
## la biblia (inicio: 70 llamadas, 16 materiales, 15 mallas con sombra y 12
## transparentes; lleno: 200 llamadas y 18 materiales). Si una prueba falla,
## lo correcto es bajar el costo (unir mallas, MultiMesh, menos materiales),
## no subir el tope sin anotar el motivo en docs/DECISIONES.md.

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
const SceneBudget: GDScript = preload("res://tests/helpers/scene_budget.gd")
const SEED: int = 1234
const SETTINGS_PATH: String = "user://test_scene_budget_settings.cfg"

## Cuarto inicial. Medido el 2026-10-22 en el paso 12 de Arte 2.0 (la
## decoración del dormitorio: 6 llamadas, ver DECOR_*): 38 llamadas, 14
## materiales, 9 mallas con sombra y 9 superficies transparentes (5 marcas,
## el marco de resalte, el haz de la ventana, la sombra bajo la base y el
## polvo del haz). El tope de llamadas sube de 37 a 41 (medido + 10 %): la
## decoración que pide la biblia no cabía en el anterior (anotado en
## docs/DECISIONES.md; la meta final sigue en 70). Antes: 33 llamadas, 13
## materiales y 8 mallas con sombra (pasos 10 y 11, el personaje nuevo); 75
## (pasos 7 a 9); 120 (paso 6); 136 (paso 5); 177 (paso 3); 334 (paso 1).
const START_MAX_DRAW_CALLS: int = 41
const START_MAX_VISIBLE_TRIANGLES: int = 45000
const START_MAX_TOTAL_TRIANGLES: int = 80000
const START_MAX_MATERIALS: int = 15
const START_MAX_SHADOW_MESHES: int = 9
const START_MAX_TRANSPARENT: int = 9
## En la tarde dorada y al alba (paso 13) se ven a la vez los halos (las
## luces de noche a medias) y el polvo del haz: una superficie transparente
## y un material más que de mañana o de noche (medido: 39 llamadas, 15
## materiales y 10 transparentes). Tope propio de esas horas, el medido, bajo
## el final de la biblia (12); el de la mañana y la noche no cambia.
const START_MAX_TRANSPARENT_HALOS_AND_DUST: int = 10
## El personaje (biblia §5.2): cuerpo y cabeza con su sombra y su contorno, y
## los triángulos de sus mallas (el contorno comparte la malla).
const CHARACTER_MAX_DRAW_CALLS: int = 6
const CHARACTER_MAX_TRIANGLES: int = 8000
## Toda la decoración (Room/Decor, biblia §5.2): lo sólido del piso con su
## sombra, lo de las paredes, lo plano, la baldosa de la impresora y el
## polvo. Medido en el paso 12: 6 llamadas.
const DECOR_MAX_DRAW_CALLS: int = 7
const DECOR_MAX_TRIANGLES: int = 9000

## Cuarto lleno. Medido el 2026-10-22 en el paso 12 (con la decoración):
## 133 llamadas, 14 materiales, 29 mallas con sombra y 6 superficies
## transparentes (las 2 tapas ámbar de las Gota R1, el polvo y 3 más; sin
## lugares libres no hay marcas: el tope de transparentes es el final del
## cuarto inicial). Los topes no cambian (medido + 10 % pasaría el anterior).
## Antes: 128 llamadas, 13 materiales y 28 mallas con sombra (pasos 10 y
## 11); 170 (paso 9); 230 (paso 8); 395 (paso 7); 440 (paso 6); 519 (paso
## 5); 535 (paso 3); 1.042 (paso 1).
const FULL_MAX_DRAW_CALLS: int = 141
const FULL_MAX_VISIBLE_TRIANGLES: int = 60000
const FULL_MAX_TOTAL_TRIANGLES: int = 99999
const FULL_MAX_MATERIALS: int = 15
const FULL_MAX_SHADOW_MESHES: int = 31
const FULL_MAX_TRANSPARENT: int = 12

## El cuarto lleno con trabajos (DebugTools.give_jobs: 12 de 16 impresoras
## imprimiendo, listas o con una falla, cada una de otro color; la captura
## 43). Medido el 2026-10-23 en el paso 15: 148 llamadas, 92.851 triángulos
## con la sombra, 33 materiales y 30 mallas con sombra (antes del paso 15 la
## captura 43 contaba 161 llamadas: las piezas, bandejas y nidos de las
## impresoras de los muebles daban sombra; biblia §2.6, ya no). Topes =
## medido + 10 %, bajo el final de la biblia (200 llamadas). Los materiales
## tienen tope propio: cada pieza, bandeja y carrete lleva el color de su
## filamento y aquí hay 12 trabajos de colores distintos (el peor caso); los
## 18 de la biblia son del cuarto lleno quieto (FULL_MAX_MATERIALS).
const JOBS_MAX_DRAW_CALLS: int = 162
const JOBS_MAX_MATERIALS: int = 36
const JOBS_MAX_SHADOW_MESHES: int = 33

## Con el zoom lejos (las impresoras en su versión lejana, biblia §13) el
## cuarto lleno usa al menos esta fracción menos de llamadas.
const FAR_MIN_SAVING: float = 0.3

## Los topes finales de la biblia §13 (los de arriba nunca los pasan).
const BIBLE_START_DRAW_CALLS: int = 70
const BIBLE_FULL_DRAW_CALLS: int = 200
const BIBLE_START_VISIBLE_TRIANGLES: int = 45000
const BIBLE_FULL_VISIBLE_TRIANGLES: int = 60000
const BIBLE_START_TOTAL_TRIANGLES: int = 80000
const BIBLE_FULL_TOTAL_TRIANGLES: int = 100000
const BIBLE_START_MATERIALS: int = 16
const BIBLE_FULL_MATERIALS: int = 18
const BIBLE_START_SHADOW_MESHES: int = 15
const BIBLE_START_TRANSPARENT: int = 12

## Armar la escena principal con las mallas y los materiales ya en caché
## (biblia §13): la mediana de BUILD_RUNS armados (sin pantalla). El tope es
## duro, contra regresiones grandes; la meta se imprime en el registro.
const BUILD_RUNS: int = 5
const BUILD_MAX_MSEC: float = 120.0
const BUILD_GOAL_MSEC: float = 40.0
## Las horas de las medidas con luz de noche (en horas de juego): la noche
## (22:00) y las dos horas que tienen a la vez halos (cc_night 0,2–0,3) y
## polvo del haz, las de más llamadas del día: la tarde dorada (17:00) y el
## alba (5:45).
const NIGHT_HOUR: float = 22.0
const GOLDEN_HOUR: float = 17.0
const DAWN_HOUR: float = 5.75

var _main: Control
var _previous_processing: bool
var _previous_quality: GraphicsQuality
var _previous_settings_path: String


func before_each() -> void:
	_previous_processing = Game.is_processing()
	# La partida solo avanza cuando la prueba lo pide.
	Game.set_process(false)
	Game.reset_game(SEED)
	# Calidad Alta (la de siempre), en un archivo de esta prueba.
	_previous_quality = GraphicsQuality.current
	_previous_settings_path = UserSettings.path
	UserSettings.path = SETTINGS_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	GraphicsQuality.current = GraphicsQuality.new(UserSettings.load_settings())
	GraphicsQuality.current.set_mode(GraphicsQuality.Mode.HIGH)


func after_each() -> void:
	Game.set_process(_previous_processing)
	GraphicsQuality.current = _previous_quality
	UserSettings.path = _previous_settings_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))


## Los topes de esta prueba nunca pasan los finales de la biblia §13.
func test_the_caps_never_go_above_the_art_bible() -> void:
	assert_lte(START_MAX_DRAW_CALLS, BIBLE_START_DRAW_CALLS)
	assert_lte(FULL_MAX_DRAW_CALLS, BIBLE_FULL_DRAW_CALLS)
	assert_lte(JOBS_MAX_DRAW_CALLS, BIBLE_FULL_DRAW_CALLS)
	assert_lte(START_MAX_VISIBLE_TRIANGLES, BIBLE_START_VISIBLE_TRIANGLES)
	assert_lte(FULL_MAX_VISIBLE_TRIANGLES, BIBLE_FULL_VISIBLE_TRIANGLES)
	assert_lte(START_MAX_TOTAL_TRIANGLES, BIBLE_START_TOTAL_TRIANGLES)
	assert_lt(FULL_MAX_TOTAL_TRIANGLES, BIBLE_FULL_TOTAL_TRIANGLES, "Bajo los 100.000 de CLAUDE.md")
	assert_lte(START_MAX_MATERIALS, BIBLE_START_MATERIALS)
	assert_lte(FULL_MAX_MATERIALS, BIBLE_FULL_MATERIALS)
	assert_lte(START_MAX_SHADOW_MESHES, BIBLE_START_SHADOW_MESHES)
	assert_lte(START_MAX_TRANSPARENT, BIBLE_START_TRANSPARENT)
	assert_lte(START_MAX_TRANSPARENT_HALOS_AND_DUST, BIBLE_START_TRANSPARENT)


func test_the_starting_room_fits_the_mobile_budget() -> void:
	var budget: RefCounted = await _measure()
	gut.p("Cuarto inicial: " + String(budget.call("report")))
	assert_lte(budget.get("draw_calls"), START_MAX_DRAW_CALLS, "Llamadas de dibujo")
	assert_lte(budget.get("visible_triangles"), START_MAX_VISIBLE_TRIANGLES, "Triángulos en la pasada de color")
	assert_lte(budget.call("total_triangles"), START_MAX_TOTAL_TRIANGLES, "Triángulos con la pasada de sombra")
	assert_lte((budget.get("materials") as Dictionary).size(), START_MAX_MATERIALS, "Materiales distintos")
	assert_lte(budget.get("shadow_meshes"), START_MAX_SHADOW_MESHES, "Mallas que dan sombra")
	assert_lte(budget.get("transparent_surfaces"), START_MAX_TRANSPARENT, "Superficies transparentes")
	assert_lte(budget.call("child_draw_calls", "Character"), CHARACTER_MAX_DRAW_CALLS, "Llamadas del personaje")
	assert_lte(budget.call("child_geometry", "Character"), CHARACTER_MAX_TRIANGLES, "Triángulos del personaje")
	assert_lte(budget.call("child_draw_calls", "Decor"), DECOR_MAX_DRAW_CALLS, "Llamadas de la decoración")
	assert_lte(budget.call("child_geometry", "Decor"), DECOR_MAX_TRIANGLES, "Triángulos de la decoración")
	_assert_one_sun_and_everything_measured(budget)


func test_the_decor_fits_its_budget_at_every_level() -> void:
	await _measure()
	var decor: RoomDecor = _main.get_node("WorldView/SubViewport/Room/Decor")
	for level: int in RoomDecor.TIER_LEVELS:
		decor.set_level(level)
		var budget: RefCounted = SceneBudget.measure(_main.get_node("WorldView/SubViewport/Room"))
		gut.p("Decoración del nivel %d: %d llamadas, %d triángulos" % [level, budget.call("child_draw_calls", "Decor"), budget.call("child_geometry", "Decor")])
		assert_lte(budget.call("child_draw_calls", "Decor"), DECOR_MAX_DRAW_CALLS, "Llamadas de la decoración (nivel %d)" % level)
		assert_lte(budget.call("child_geometry", "Decor"), DECOR_MAX_TRIANGLES, "Triángulos de la decoración (nivel %d)" % level)


func test_a_full_room_fits_the_mobile_budget() -> void:
	DebugTools.fill_workshop(Game.state, Game.rules)
	var budget: RefCounted = await _measure()
	gut.p("Cuarto lleno (%d impresoras): %s" % [Game.state.printers.size(), budget.call("report")])
	assert_eq(Game.state.printers.size(), 16, "El escritorio, la del piso y 5 estanterías de 3")
	assert_lte(budget.get("draw_calls"), FULL_MAX_DRAW_CALLS, "Llamadas de dibujo")
	assert_lte(budget.get("visible_triangles"), FULL_MAX_VISIBLE_TRIANGLES, "Triángulos en la pasada de color")
	assert_lte(budget.call("total_triangles"), FULL_MAX_TOTAL_TRIANGLES, "Triángulos con la pasada de sombra")
	assert_lte((budget.get("materials") as Dictionary).size(), FULL_MAX_MATERIALS, "Materiales distintos")
	assert_lte(budget.get("shadow_meshes"), FULL_MAX_SHADOW_MESHES, "Mallas que dan sombra")
	assert_lte(budget.get("transparent_surfaces"), FULL_MAX_TRANSPARENT, "Superficies transparentes")
	_assert_one_sun_and_everything_measured(budget)


## El cuarto lleno con trabajos en cada estado (la captura 43): las piezas,
## las bandejas y los nidos de espagueti (solo la impresora del piso les da
## sombra, biblia §2.6) caben en el tope final de la biblia.
func test_a_full_room_with_jobs_fits_the_mobile_budget() -> void:
	DebugTools.fill_workshop(Game.state, Game.rules)
	DebugTools.give_jobs(Game.state, Game.rules)
	var budget: RefCounted = await _measure()
	gut.p("Cuarto lleno con trabajos: " + String(budget.call("report")))
	assert_lte(budget.get("draw_calls"), JOBS_MAX_DRAW_CALLS, "Llamadas de dibujo")
	assert_lte(budget.get("visible_triangles"), FULL_MAX_VISIBLE_TRIANGLES, "Triángulos en la pasada de color")
	assert_lte(budget.call("total_triangles"), FULL_MAX_TOTAL_TRIANGLES, "Triángulos con la pasada de sombra")
	assert_lte((budget.get("materials") as Dictionary).size(), JOBS_MAX_MATERIALS, "Materiales distintos")
	assert_lte(budget.get("shadow_meshes"), JOBS_MAX_SHADOW_MESHES, "Mallas que dan sombra")
	assert_lte(budget.get("transparent_surfaces"), FULL_MAX_TRANSPARENT, "Superficies transparentes")
	_assert_one_sun_and_everything_measured(budget)


## Con el zoom lejos las impresoras pasan a su versión lejana (biblia §13):
## el cuarto lleno, quieto y con trabajos, usa al menos un 30 % menos de
## llamadas que con el zoom normal, y menos triángulos. Al volver al zoom
## normal vuelve a costar lo mismo.
func test_at_far_zoom_the_full_room_is_much_cheaper() -> void:
	for jobs: bool in [false, true]:
		Game.reset_game(SEED)
		DebugTools.fill_workshop(Game.state, Game.rules)
		if jobs:
			DebugTools.give_jobs(Game.state, Game.rules)
		var what: String = "Cuarto lleno%s" % (" con trabajos" if jobs else "")
		var near: RefCounted = await _measure()
		var room: RoomView = _main.get_node("WorldView/SubViewport/Room")
		assert_false(room.far_printers, what + ": con el zoom normal, las de siempre")
		await _set_zoom(room, 0)
		assert_true(room.far_printers, what + ": con el zoom lejos, las lejanas")
		var far: RefCounted = SceneBudget.measure(room)
		gut.p("%s con el zoom lejos: %s" % [what, far.call("report")])
		var saving: float = 1.0 - float(far.get("draw_calls")) / float(near.get("draw_calls"))
		gut.p("%s: %d llamadas con el zoom normal, %d con el lejos (%.0f %% menos)" % [what, near.get("draw_calls"), far.get("draw_calls"), saving * 100.0])
		assert_gte(saving, FAR_MIN_SAVING, what + ": al menos un 30 % menos de llamadas")
		assert_lt(far.call("total_triangles"), near.call("total_triangles"), what + ": menos triángulos")
		_assert_one_sun_and_everything_measured(far)
		await _set_zoom(room, CameraRig.DEFAULT_ZOOM_INDEX)
		assert_false(room.far_printers, what + ": de vuelta las de siempre")
		var back: RefCounted = SceneBudget.measure(room)
		assert_eq(back.get("draw_calls"), near.get("draw_calls"), what + ": de vuelta, las mismas llamadas")
		assert_eq(back.call("total_triangles"), near.call("total_triangles"), what + ": de vuelta, los mismos triángulos")
		_main.queue_free()
		await wait_process_frames(1)


## La calidad Baja (biblia §2.2): el sol sin sombra (ni una llamada de
## sombra), sin polvo, y los dos cuartos en los mismos topes con menos
## llamadas que en Alta.
func test_low_quality_drops_the_shadow_pass_and_fits_the_same_budget() -> void:
	for full: bool in [false, true]:
		Game.reset_game(SEED)
		if full:
			DebugTools.fill_workshop(Game.state, Game.rules)
		GraphicsQuality.current.set_mode(GraphicsQuality.Mode.HIGH)
		var high: RefCounted = await _measure()
		_main.queue_free()
		await wait_process_frames(1)
		GraphicsQuality.current.set_mode(GraphicsQuality.Mode.LOW)
		var budget: RefCounted = await _measure()
		var what: String = "Cuarto %s en Baja" % ("lleno" if full else "inicial")
		gut.p(what + ": " + String(budget.call("report")))
		var room: RoomView = _main.get_node("WorldView/SubViewport/Room")
		assert_false(room.get_node("Sun").shadow_enabled, what + ": el sol sin sombra")
		assert_false(room.decor.dust.enabled, what + ": sin polvo")
		assert_eq(budget.get("shadow_passes"), 0, what + ": ninguna pasada de sombra")
		assert_eq(budget.get("shadow_triangles"), 0, what + ": ningún triángulo de sombra")
		assert_lt(budget.get("draw_calls"), high.get("draw_calls"), what + ": menos llamadas que en Alta")
		assert_lte(budget.get("draw_calls"), FULL_MAX_DRAW_CALLS if full else START_MAX_DRAW_CALLS, what + ": llamadas de dibujo")
		assert_lte(budget.call("total_triangles"), FULL_MAX_TOTAL_TRIANGLES if full else START_MAX_TOTAL_TRIANGLES, what + ": triángulos")
		assert_lte((budget.get("materials") as Dictionary).size(), FULL_MAX_MATERIALS if full else START_MAX_MATERIALS, what + ": materiales")
		assert_lte(budget.get("transparent_surfaces"), FULL_MAX_TRANSPARENT if full else START_MAX_TRANSPARENT, what + ": transparentes")
		_assert_one_sun_and_everything_measured(budget, false)
		_main.queue_free()
		await wait_process_frames(1)


## De noche (biblia §6) se encienden los halos (un MultiMesh: una llamada,
## sumada) y se apaga el polvo del haz: los dos cuartos caben en los mismos
## topes, con la misma luz única.
func test_the_night_fits_the_same_budget() -> void:
	await _assert_both_rooms_fit_at(NIGHT_HOUR, "de noche", false)


## En la tarde dorada y al alba se ven a la vez los halos (las luces de noche
## a medias) y el polvo del haz: las horas de más llamadas del día, en los
## mismos topes.
func test_the_golden_hour_and_the_dawn_fit_the_same_budget() -> void:
	await _assert_both_rooms_fit_at(GOLDEN_HOUR, "en la tarde dorada", true)
	await _assert_both_rooms_fit_at(DAWN_HOUR, "al alba", true)


func test_the_main_scene_builds_fast_with_cached_meshes() -> void:
	# El primer armado llena las cachés (mallas del kit y materiales).
	await _build_once()
	var times: Array[float] = []
	for i: int in BUILD_RUNS:
		times.append(await _build_once())
	times.sort()
	var median: float = times[BUILD_RUNS / 2]
	gut.p("Armar la escena principal con caché: mediana %.1f ms (meta ≤ %.0f ms, tope %.0f ms); %s" % [median, BUILD_GOAL_MSEC, BUILD_MAX_MSEC, times])
	assert_lte(median, BUILD_MAX_MSEC, "Armar la escena principal con caché")


## Biblia §13: un solo sol con sombra (sin ella en la calidad Baja,
## `shadowed` falso) y ninguna luz extra del motor (las lámparas se calculan
## en el sombreador). Y nada que dibuje sin contarse. Se mira todo el
## SubViewport, no solo Room: una luz o una malla puesta al lado de Room
## también cuenta, y lo dibujado tiene que ser lo mismo que lo medido en Room
## (si no, los topes de arriba no lo ven).
func _assert_one_sun_and_everything_measured(budget: RefCounted, shadowed: bool = true) -> void:
	var world: RefCounted = SceneBudget.measure(_main.get_node("WorldView/SubViewport"))
	var lights: Dictionary = world.get("lights")
	assert_eq(lights.get("DirectionalLight3D", 0), 1, "Una sola luz direccional")
	assert_eq(lights.get("OmniLight3D", 0), 0, "Sin OmniLight3D")
	assert_eq(lights.get("SpotLight3D", 0), 0, "Sin SpotLight3D")
	assert_eq(lights.size(), 1, "Ninguna otra luz: %s" % lights)
	assert_eq(world.get("shadowed_lights"), 1 if shadowed else 0, "Solo el sol da sombra" if shadowed else "Nada da sombra")
	assert_eq(world.get("unmeasured"), [] as Array[String], "Todo lo que se dibuja se mide")
	assert_eq(world.get("draw_calls"), budget.get("draw_calls"), "Todo lo que dibuja el mundo está dentro de Room")
	assert_eq(world.call("total_triangles"), budget.call("total_triangles"), "Todos los triángulos están dentro de Room")


## Mide el cuarto inicial y el lleno a la hora `hour` (horas de juego)
## contra sus topes de siempre, con los halos encendidos; `dust`: si a esa
## hora se ve también el polvo del haz (el inicial tiene entonces una
## transparente más, START_MAX_TRANSPARENT_HALOS_AND_DUST).
func _assert_both_rooms_fit_at(hour: float, label: String, dust: bool) -> void:
	for full: bool in [false, true]:
		Game.reset_game(SEED)
		if full:
			DebugTools.fill_workshop(Game.state, Game.rules)
		Game.state.game_seconds = roundi(hour * GameClock.SECONDS_PER_HOUR)
		var budget: RefCounted = await _measure()
		var what: String = "Cuarto %s %s" % ["lleno" if full else "inicial", label]
		gut.p(what + ": " + String(budget.call("report")))
		var room: RoomView = _main.get_node("WorldView/SubViewport/Room")
		assert_true(room.halos.visible, what + ": los halos se ven")
		assert_eq(room.decor.dust.visible, dust, what + ": el polvo del haz")
		assert_lte(budget.get("draw_calls"), FULL_MAX_DRAW_CALLS if full else START_MAX_DRAW_CALLS, what + ": llamadas de dibujo")
		assert_lte(budget.get("visible_triangles"), FULL_MAX_VISIBLE_TRIANGLES if full else START_MAX_VISIBLE_TRIANGLES, what + ": triángulos en la pasada de color")
		assert_lte(budget.call("total_triangles"), FULL_MAX_TOTAL_TRIANGLES if full else START_MAX_TOTAL_TRIANGLES, what + ": triángulos con la pasada de sombra")
		assert_lte((budget.get("materials") as Dictionary).size(), FULL_MAX_MATERIALS if full else START_MAX_MATERIALS, what + ": materiales")
		assert_lte(budget.get("shadow_meshes"), FULL_MAX_SHADOW_MESHES if full else START_MAX_SHADOW_MESHES, what + ": mallas que dan sombra")
		var transparent: int = START_MAX_TRANSPARENT_HALOS_AND_DUST if dust else START_MAX_TRANSPARENT
		assert_lte(budget.get("transparent_surfaces"), FULL_MAX_TRANSPARENT if full else transparent, what + ": superficies transparentes")
		_assert_one_sun_and_everything_measured(budget)
		_main.queue_free()
		await wait_process_frames(1)


## Lleva la cámara al escalón de zoom `index` de una vez y deja pasar dos
## cuadros (RoomView.step decide la versión de las impresoras).
func _set_zoom(room: RoomView, index: int) -> void:
	room.camera.set_zoom_index(index)
	room.camera.snap_to_goal()
	await wait_process_frames(2)


func _measure() -> RefCounted:
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	await wait_process_frames(2)
	return SceneBudget.measure(_main.get_node("WorldView/SubViewport/Room"))


## Arma la escena principal (instanciarla y ponerla en el árbol, con todos
## sus _ready) y devuelve cuánto tardó, en milisegundos. Después la saca.
func _build_once() -> float:
	var start: int = Time.get_ticks_usec()
	var main: Control = MAIN_SCENE.instantiate()
	add_child(main)
	var elapsed: float = (Time.get_ticks_usec() - start) / 1000.0
	await wait_process_frames(1)
	main.queue_free()
	await wait_process_frames(1)
	return elapsed

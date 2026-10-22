extends GutTest
## Presupuesto de dibujo del mundo (CLAUDE.md, "Rendimiento móvil"; biblia de
## arte §13), medido sin pantalla con tests/helpers/scene_budget.gd sobre
## Main/WorldView/SubViewport/Room (y las luces y lo que no se sabe medir,
## sobre todo el SubViewport).
##
## Dos cuartos: el de la partida nueva y el más cargado de hoy
## (tests/helpers/full_room.gd: escritorio, impresora del piso y 5
## estanterías metálicas con 3 impresoras cada una, de todas las familias).
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
const FullRoom: GDScript = preload("res://tests/helpers/full_room.gd")
const SEED: int = 1234

## Cuarto inicial. Medido el 2026-10-22 en el paso 6 de Arte 2.0 (la Cubo
## Uno del kit: 4 mallas que dan sombra y la pantallita; la baldosa y su cable
## en una malla sin sombra): 120 llamadas, 27 materiales, 53 mallas con sombra
## y 8 superficies transparentes (5 marcas, el marco de resalte, el haz de la
## ventana y la sombra bajo la base). Antes: 136 llamadas, 32 materiales y 62
## mallas con sombra (paso 5); 177 llamadas (paso 3); 334 (paso 1).
const START_MAX_DRAW_CALLS: int = 132
const START_MAX_VISIBLE_TRIANGLES: int = 45000
const START_MAX_TOTAL_TRIANGLES: int = 80000
const START_MAX_MATERIALS: int = 29
const START_MAX_SHADOW_MESHES: int = 58
const START_MAX_TRANSPARENT: int = 9

## Cuarto lleno. Medido el 2026-10-22 en el paso 6: 440 llamadas, 37
## materiales, 214 mallas con sombra y 3 superficies transparentes (sin
## lugares libres no hay marcas: el tope de transparentes es el final del
## cuarto inicial). Antes: 519 llamadas y 39 materiales (paso 5); 535 (paso
## 3); 1.042 (paso 1).
const FULL_MAX_DRAW_CALLS: int = 484
const FULL_MAX_VISIBLE_TRIANGLES: int = 60000
const FULL_MAX_TOTAL_TRIANGLES: int = 99999
const FULL_MAX_MATERIALS: int = 40
const FULL_MAX_SHADOW_MESHES: int = 235
const FULL_MAX_TRANSPARENT: int = 12

## Armar la escena principal con las mallas y los materiales ya en caché
## (biblia §13): la mediana de BUILD_RUNS armados (sin pantalla). El tope es
## duro, contra regresiones grandes; la meta se imprime en el registro.
const BUILD_RUNS: int = 5
const BUILD_MAX_MSEC: float = 120.0
const BUILD_GOAL_MSEC: float = 40.0

var _main: Control
var _previous_processing: bool


func before_each() -> void:
	_previous_processing = Game.is_processing()
	# La partida solo avanza cuando la prueba lo pide.
	Game.set_process(false)
	Game.reset_game(SEED)


func after_each() -> void:
	Game.set_process(_previous_processing)


func test_the_starting_room_fits_the_mobile_budget() -> void:
	var budget: RefCounted = await _measure()
	gut.p("Cuarto inicial: " + String(budget.call("report")))
	assert_lte(budget.get("draw_calls"), START_MAX_DRAW_CALLS, "Llamadas de dibujo")
	assert_lte(budget.get("visible_triangles"), START_MAX_VISIBLE_TRIANGLES, "Triángulos en la pasada de color")
	assert_lte(budget.call("total_triangles"), START_MAX_TOTAL_TRIANGLES, "Triángulos con la pasada de sombra")
	assert_lte((budget.get("materials") as Dictionary).size(), START_MAX_MATERIALS, "Materiales distintos")
	assert_lte(budget.get("shadow_meshes"), START_MAX_SHADOW_MESHES, "Mallas que dan sombra")
	assert_lte(budget.get("transparent_surfaces"), START_MAX_TRANSPARENT, "Superficies transparentes")
	_assert_one_sun_and_everything_measured(budget)


func test_a_full_room_fits_the_mobile_budget() -> void:
	FullRoom.fill(Game.state, Game.rules)
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


## Biblia §13: un solo sol con sombra y ninguna luz extra del motor (las
## lámparas se calculan en el sombreador). Y nada que dibuje sin contarse.
## Se mira todo el SubViewport, no solo Room: una luz o una malla puesta al
## lado de Room también cuenta, y lo dibujado tiene que ser lo mismo que lo
## medido en Room (si no, los topes de arriba no lo ven).
func _assert_one_sun_and_everything_measured(budget: RefCounted) -> void:
	var world: RefCounted = SceneBudget.measure(_main.get_node("WorldView/SubViewport"))
	var lights: Dictionary = world.get("lights")
	assert_eq(lights.get("DirectionalLight3D", 0), 1, "Una sola luz direccional")
	assert_eq(lights.get("OmniLight3D", 0), 0, "Sin OmniLight3D")
	assert_eq(lights.get("SpotLight3D", 0), 0, "Sin SpotLight3D")
	assert_eq(lights.size(), 1, "Ninguna otra luz: %s" % lights)
	assert_eq(world.get("shadowed_lights"), 1, "Solo el sol da sombra")
	assert_eq(world.get("unmeasured"), [] as Array[String], "Todo lo que se dibuja se mide")
	assert_eq(world.get("draw_calls"), budget.get("draw_calls"), "Todo lo que dibuja el mundo está dentro de Room")
	assert_eq(world.call("total_triangles"), budget.call("total_triangles"), "Todos los triángulos están dentro de Room")


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

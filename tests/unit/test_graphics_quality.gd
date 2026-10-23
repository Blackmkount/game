extends GutTest
## Niveles de calidad gráfica (GraphicsQuality, biblia de arte §2.2): lo de
## cada nivel, lo que elige el jugador y el modo automático, que mide los
## primeros cuadros después de un calentamiento, baja a Baja si el teléfono
## es lento, lo recuerda y nunca vuelve solo.

const SETTINGS_PATH: String = "user://test_graphics_quality_settings.cfg"
## Cuadros de prueba (segundos): uno lento, uno rápido (60 fps) y el límite.
const SLOW_FRAME: float = 0.030
const FAST_FRAME: float = 1.0 / 60.0

var _previous_path: String


func before_each() -> void:
	_previous_path = UserSettings.path
	UserSettings.path = SETTINGS_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	UserSettings.path = _previous_path


func test_each_level_has_the_values_of_the_art_bible() -> void:
	var high: GraphicsQuality.Level = GraphicsQuality.Level.HIGH
	var low: GraphicsQuality.Level = GraphicsQuality.Level.LOW
	assert_eq(GraphicsQuality.MAX_WIDTH[high], 1080.0, "Alta: hasta 1080 px")
	assert_eq(GraphicsQuality.MAX_WIDTH[low], 720.0, "Baja: hasta 720 px")
	assert_eq(GraphicsQuality.MSAA[high], Viewport.MSAA_4X)
	assert_eq(GraphicsQuality.MSAA[low], Viewport.MSAA_2X)
	assert_true(GraphicsQuality.SUN_SHADOW[high], "Alta: el sol da sombra")
	assert_false(GraphicsQuality.SUN_SHADOW[low], "Baja: sin sombra")
	assert_true(GraphicsQuality.DUST[high])
	assert_false(GraphicsQuality.DUST[low])
	assert_eq(GraphicsQuality.FLOOR_AO[high], 1.0)
	assert_eq(GraphicsQuality.FLOOR_AO[low], 1.2, "En Baja el piso se oscurece más bajo las cosas")
	var quality: GraphicsQuality = _new_quality()
	quality.set_mode(GraphicsQuality.Mode.LOW)
	assert_eq([quality.max_width(), quality.msaa(), quality.sun_shadow(), quality.dust(), quality.floor_ao()], [720.0, Viewport.MSAA_2X, false, false, 1.2])
	quality.set_mode(GraphicsQuality.Mode.HIGH)
	assert_eq([quality.max_width(), quality.msaa(), quality.sun_shadow(), quality.dust(), quality.floor_ao()], [1080.0, Viewport.MSAA_4X, true, true, 1.0])


func test_a_new_player_starts_automatic_on_high_and_measuring() -> void:
	var quality: GraphicsQuality = _new_quality()
	assert_eq(quality.mode, GraphicsQuality.Mode.AUTO)
	assert_eq(quality.level, GraphicsQuality.Level.HIGH)
	assert_true(quality.is_measuring())


## Las pruebas, check.sh y las capturas (RunMode) arrancan siempre en Alta,
## sin leer lo guardado: una corrida con ventana lenta guardaba que el
## automático bajó a Baja y la siguiente fallaba (empezaba en Baja).
func test_tools_start_on_high_whatever_was_saved() -> void:
	var saved: UserSettings = UserSettings.load_settings()
	saved.set_graphics_value(GraphicsQuality.MODE_KEY, GraphicsQuality.MODE_NAMES[GraphicsQuality.Mode.AUTO])
	saved.set_graphics_value(GraphicsQuality.AUTO_LOW_KEY, true)
	assert_eq(_new_quality().level, GraphicsQuality.Level.LOW, "Lo guardado dice Baja")
	assert_true(RunMode.is_tool_run(), "Las pruebas son una herramienta")
	var quality: GraphicsQuality = GraphicsQuality.initial()
	assert_eq(quality.mode, GraphicsQuality.Mode.HIGH)
	assert_eq(quality.level, GraphicsQuality.Level.HIGH)
	assert_false(quality.is_measuring(), "Y no mide: los cuadros de una ventana no deciden nada")


func test_automatic_drops_to_low_with_slow_frames_and_remembers_it() -> void:
	var quality: GraphicsQuality = _new_quality()
	watch_signals(quality)
	_feed(quality, SLOW_FRAME, GraphicsQuality.AUTO_WARMUP_SECONDS + GraphicsQuality.AUTO_WINDOW_SECONDS - 0.1)
	assert_eq(quality.level, GraphicsQuality.Level.HIGH, "Antes de terminar de medir no decide")
	assert_true(quality.is_measuring())
	_feed(quality, SLOW_FRAME, 0.2)
	assert_eq(quality.level, GraphicsQuality.Level.LOW, "Lento: baja a Baja")
	assert_false(quality.is_measuring(), "Mide una sola vez")
	assert_signal_emit_count(quality, "changed", 1, "Avisa una vez")
	assert_eq(quality.mode, GraphicsQuality.Mode.AUTO, "Sigue en automática")
	var next_time: GraphicsQuality = _new_quality()
	assert_eq(next_time.level, GraphicsQuality.Level.LOW, "Lo recuerda la próxima vez")
	assert_false(next_time.is_measuring(), "Y no vuelve a medir")


func test_automatic_never_goes_back_up_by_itself() -> void:
	var quality: GraphicsQuality = _new_quality()
	_feed(quality, SLOW_FRAME, GraphicsQuality.AUTO_WARMUP_SECONDS + GraphicsQuality.AUTO_WINDOW_SECONDS + 0.1)
	_feed(quality, FAST_FRAME, 30.0)
	assert_eq(quality.level, GraphicsQuality.Level.LOW, "Aunque después vaya rápido")
	var next_time: GraphicsQuality = _new_quality()
	_feed(next_time, FAST_FRAME, 30.0)
	assert_eq(next_time.level, GraphicsQuality.Level.LOW, "Tampoco en la próxima vez")


func test_a_fast_phone_stays_on_high_and_is_measured_again_next_time() -> void:
	var quality: GraphicsQuality = _new_quality()
	watch_signals(quality)
	_feed(quality, FAST_FRAME, GraphicsQuality.AUTO_WARMUP_SECONDS + GraphicsQuality.AUTO_WINDOW_SECONDS + 0.1)
	assert_eq(quality.level, GraphicsQuality.Level.HIGH)
	assert_false(quality.is_measuring(), "Terminó de medir")
	assert_signal_not_emitted(quality, "changed", "No cambió nada")
	assert_true(_new_quality().is_measuring(), "La próxima vez vuelve a medir")


func test_the_warmup_and_a_hitch_do_not_decide_alone() -> void:
	var quality: GraphicsQuality = _new_quality()
	# El armado de la escena y el calentamiento, lentos: no cuentan.
	quality.add_frame(0.5)
	_feed(quality, 0.2, GraphicsQuality.AUTO_WARMUP_SECONDS)
	_feed(quality, FAST_FRAME, 1.0)
	assert_true(quality.is_measuring(), "Después del calentamiento mide")
	# Una pausa larga en medio (la app vuelve de segundo plano) cuenta como
	# AUTO_MAX_FRAME_SECONDS: ni la hace lenta ni termina la medida.
	quality.add_frame(5.0)
	assert_true(quality.is_measuring(), "La pausa no termina la medida")
	_feed(quality, FAST_FRAME, GraphicsQuality.AUTO_WINDOW_SECONDS)
	assert_false(quality.is_measuring())
	assert_eq(quality.level, GraphicsQuality.Level.HIGH, "Rápido salvo el comienzo y una pausa: sigue en Alta")


func test_the_slow_threshold_is_24_ms_per_frame() -> void:
	assert_eq(GraphicsQuality.AUTO_SLOW_FRAME_MSEC, 24.0)
	assert_false(GraphicsQuality.is_slow(0.0239))
	assert_false(GraphicsQuality.is_slow(0.024))
	assert_true(GraphicsQuality.is_slow(0.0241))


func test_the_chosen_mode_is_saved_and_automatic_measures_again() -> void:
	var quality: GraphicsQuality = _new_quality()
	_feed(quality, SLOW_FRAME, GraphicsQuality.AUTO_WARMUP_SECONDS + GraphicsQuality.AUTO_WINDOW_SECONDS + 0.1)
	assert_eq(quality.level, GraphicsQuality.Level.LOW)
	watch_signals(quality)
	quality.set_mode(GraphicsQuality.Mode.HIGH)
	assert_eq(quality.level, GraphicsQuality.Level.HIGH, "Alta elegida a mano")
	assert_false(quality.is_measuring(), "A mano no se mide")
	assert_signal_emitted(quality, "changed")
	assert_eq(_new_quality().mode, GraphicsQuality.Mode.HIGH, "Se guarda")
	quality.set_mode(GraphicsQuality.Mode.AUTO)
	assert_eq(quality.level, GraphicsQuality.Level.HIGH, "Automática otra vez: olvida lo recordado")
	assert_true(quality.is_measuring(), "Y vuelve a medir")
	_feed(quality, FAST_FRAME, GraphicsQuality.AUTO_WARMUP_SECONDS + GraphicsQuality.AUTO_WINDOW_SECONDS + 0.1)
	assert_eq(quality.level, GraphicsQuality.Level.HIGH, "Esta vez va rápido")
	quality.set_mode(GraphicsQuality.Mode.LOW)
	var next_time: GraphicsQuality = _new_quality()
	assert_eq([next_time.mode, next_time.level], [GraphicsQuality.Mode.LOW, GraphicsQuality.Level.LOW], "Baja elegida a mano, guardada")
	assert_false(next_time.is_measuring())


func test_mode_names_are_those_of_the_screenshots_option() -> void:
	assert_eq(GraphicsQuality.mode_from_name("auto"), GraphicsQuality.Mode.AUTO)
	assert_eq(GraphicsQuality.mode_from_name("high"), GraphicsQuality.Mode.HIGH)
	assert_eq(GraphicsQuality.mode_from_name("low"), GraphicsQuality.Mode.LOW)
	assert_eq(GraphicsQuality.mode_from_name("ultra"), GraphicsQuality.Mode.AUTO, "Lo desconocido es automática")


func test_measuring_a_frame_does_not_allocate() -> void:
	var quality: GraphicsQuality = _new_quality()
	quality.add_frame(FAST_FRAME)
	var before: int = OS.get_static_memory_usage()
	for i: int in 200:
		quality.add_frame(FAST_FRAME)
	assert_eq(OS.get_static_memory_usage(), before, "Contar cuadros no pide memoria")


func _new_quality() -> GraphicsQuality:
	return GraphicsQuality.new(UserSettings.load_settings())


## Pasa cuadros de `frame` segundos durante `seconds` segundos.
func _feed(quality: GraphicsQuality, frame: float, seconds: float) -> void:
	for i: int in ceili(seconds / frame):
		quality.add_frame(frame)

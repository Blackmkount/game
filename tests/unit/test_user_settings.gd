extends GutTest
## Preferencias del jugador (UserSettings): cada parte del juego carga su
## copia del archivo al empezar (HintFlow y GraphicsQuality.current) y guarda
## cuando cambia algo. Lo que guarda una copia no puede borrar lo que guardó
## la otra (biblia de arte §2.2: la calidad elegida "lo recuerda").

const SETTINGS_PATH: String = "user://test_user_settings.cfg"
## Un cuadro lento para el modo automático (segundos).
const SLOW_FRAME: float = 0.030

var _previous_path: String


func before_each() -> void:
	_previous_path = UserSettings.path
	UserSettings.path = SETTINGS_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	UserSettings.path = _previous_path


func test_two_copies_saving_in_turn_keep_both_changes() -> void:
	var first: UserSettings = UserSettings.load_settings()
	var second: UserSettings = UserSettings.load_settings()
	first.mark_seen(HintFlow.MOVE)
	second.set_graphics_value(GraphicsQuality.MODE_KEY, "low")
	first.mark_seen(HintFlow.TAP)
	second.set_graphics_value(GraphicsQuality.AUTO_LOW_KEY, true)
	var next_time: UserSettings = UserSettings.load_settings()
	assert_true(next_time.has_seen(HintFlow.MOVE), "La primera pista guardada por la primera copia")
	assert_true(next_time.has_seen(HintFlow.TAP), "La segunda también")
	assert_eq(next_time.graphics_value(GraphicsQuality.MODE_KEY, ""), "low", "El modo guardado por la segunda copia")
	assert_eq(next_time.graphics_value(GraphicsQuality.AUTO_LOW_KEY, false), true)
	assert_eq(first.graphics_value(GraphicsQuality.MODE_KEY, ""), "low", "Al guardar, cada copia queda con lo del archivo")


func test_choosing_low_then_opening_a_first_panel_keeps_low() -> void:
	var quality: GraphicsQuality = GraphicsQuality.new(UserSettings.load_settings())
	var hints: HintFlow = HintFlow.new(UserSettings.load_settings())
	quality.set_mode(GraphicsQuality.Mode.LOW)
	hints.sheet_opened()
	var next_time: GraphicsQuality = GraphicsQuality.new(UserSettings.load_settings())
	assert_eq(next_time.mode, GraphicsQuality.Mode.LOW, "Baja elegida en Ajustes sigue al volver a abrir el juego")
	assert_true(UserSettings.load_settings().has_seen(HintFlow.TAP))


func test_walking_then_changing_the_quality_keeps_the_hint_learned() -> void:
	var quality: GraphicsQuality = GraphicsQuality.new(UserSettings.load_settings())
	var hints: HintFlow = HintFlow.new(UserSettings.load_settings())
	hints.walked_by_tap()
	quality.set_mode(GraphicsQuality.Mode.HIGH)
	var next_time: HintFlow = HintFlow.new(UserSettings.load_settings())
	assert_eq(next_time.mode(), MoveHint.Mode.TAP, "La pista de caminar no vuelve")
	assert_eq(GraphicsQuality.new(UserSettings.load_settings()).mode, GraphicsQuality.Mode.HIGH)


func test_the_automatic_drop_and_a_hint_saved_later_both_stay() -> void:
	var quality: GraphicsQuality = GraphicsQuality.new(UserSettings.load_settings())
	var hints: HintFlow = HintFlow.new(UserSettings.load_settings())
	hints.walked_by_tap()
	var frames: int = ceili((GraphicsQuality.AUTO_WARMUP_SECONDS + GraphicsQuality.AUTO_WINDOW_SECONDS + 0.1) / SLOW_FRAME)
	for i: int in frames:
		quality.add_frame(SLOW_FRAME)
	assert_eq(quality.level, GraphicsQuality.Level.LOW, "Un teléfono lento baja a Baja")
	hints.sheet_opened()
	var next_time: GraphicsQuality = GraphicsQuality.new(UserSettings.load_settings())
	assert_eq(next_time.level, GraphicsQuality.Level.LOW, "Lo recuerda aunque después se guardó una pista")
	assert_false(next_time.is_measuring())
	assert_eq(HintFlow.new(UserSettings.load_settings()).mode(), MoveHint.Mode.NONE, "Y las dos pistas siguen aprendidas")

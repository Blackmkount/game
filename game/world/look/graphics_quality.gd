class_name GraphicsQuality
extends RefCounted
## Niveles de calidad gráfica del mundo (biblia de arte §2.2): Alta (la de
## siempre) y Baja (para teléfonos que no llegan): menos píxeles, menos
## suavizado de bordes, el sol sin sombra y sin motas de polvo. Con el modelo
## de color de §2.4 los dos se ven iguales salvo las sombras.
##
## El jugador elige en Ajustes (D7): Automática, Alta o Baja. Automática
## empieza en Alta y mide los primeros cuadros después de cargar (después de
## un rato de calentamiento, cuando el motor todavía arma sus sombreadores):
## si el promedio pasa de AUTO_SLOW_FRAME_MSEC por cuadro, baja a Baja una
## sola vez, lo recuerda y nunca vuelve sola. Elegir otra vez Automática
## borra lo recordado y vuelve a medir.
##
## Lo guarda en UserSettings (sección "graphics"). Lo aplican WorldViewport
## (tope del ancho y suavizado), RoomView (sombra, polvo, oclusión del piso y
## ColorProbe) y ModelPreview (la sombra del sol de las vistas de la
## interfaz), que escuchan `changed`.

## Cambió el nivel que se aplica o el modo que eligió el jugador.
signal changed

## Lo que elige el jugador.
enum Mode { AUTO, HIGH, LOW }
## Lo que se aplica.
enum Level { HIGH, LOW }

## Lo de cada nivel (biblia §2.2): tope del ancho interno del dibujo del
## mundo (px), suavizado de bordes, si el sol da sombra (si no, va en la
## pasada base, sin llamadas extra), si se ven las motas de polvo y cuánto
## oscurece el mapa de oclusión del piso (en Baja un poco más: compensa que
## no hay sombras).
const MAX_WIDTH: Dictionary[Level, float] = {Level.HIGH: 1080.0, Level.LOW: 720.0}
const MSAA: Dictionary[Level, Viewport.MSAA] = {Level.HIGH: Viewport.MSAA_4X, Level.LOW: Viewport.MSAA_2X}
const SUN_SHADOW: Dictionary[Level, bool] = {Level.HIGH: true, Level.LOW: false}
const DUST: Dictionary[Level, bool] = {Level.HIGH: true, Level.LOW: false}
const FLOOR_AO: Dictionary[Level, float] = {Level.HIGH: 1.0, Level.LOW: 1.2}

## Automático (segundos reales): lo que no se cuenta al empezar (el armado
## de la escena y el motor que arma los sombreadores la primera vez que
## dibuja algo), lo que se mide después y el promedio por cuadro (ms) desde
## el que el teléfono es lento. Un cuadro de más de AUTO_MAX_FRAME_SECONDS
## (una pausa, la app que vuelve de segundo plano) cuenta como ese máximo: no
## decide solo ni termina la medida antes de tiempo.
const AUTO_WARMUP_SECONDS: float = 1.0
const AUTO_WINDOW_SECONDS: float = 3.0
const AUTO_SLOW_FRAME_MSEC: float = 24.0
const AUTO_MAX_FRAME_SECONDS: float = 0.1

## Claves en UserSettings y cómo se escribe cada modo (también en la opción
## --quality de tools/screenshots.sh).
const MODE_KEY: String = "mode"
const AUTO_LOW_KEY: String = "auto_low"
const MODE_NAMES: Dictionary[Mode, String] = {Mode.AUTO: "auto", Mode.HIGH: "high", Mode.LOW: "low"}

## La calidad del juego. Las pruebas y las capturas ponen una propia.
static var current: GraphicsQuality = GraphicsQuality.new(UserSettings.load_settings())

var mode: Mode = Mode.AUTO
var level: Level = Level.HIGH

var _settings: UserSettings
## El automático ya bajó a Baja (recordado).
var _auto_low: bool = false
## La medida del automático: si sigue, cuánto lleva el calentamiento (s),
## lo sumado de los cuadros que cuentan (s) y cuántos son.
var _measuring: bool = false
var _warmup: float = 0.0
var _sum: float = 0.0
var _frames: int = 0


func _init(settings: UserSettings) -> void:
	_settings = settings
	mode = mode_from_name(str(settings.graphics_value(MODE_KEY, MODE_NAMES[Mode.AUTO])))
	_auto_low = bool(settings.graphics_value(AUTO_LOW_KEY, false))
	level = _level_for_mode()
	_measuring = mode == Mode.AUTO and not _auto_low


## El modo escrito así ("auto", "high" o "low"); uno desconocido es AUTO.
static func mode_from_name(mode_name: String) -> Mode:
	for each: Mode in MODE_NAMES:
		if MODE_NAMES[each] == mode_name:
			return each
	return Mode.AUTO


## Si un promedio de `average_seconds` por cuadro es de un teléfono lento.
static func is_slow(average_seconds: float) -> bool:
	return average_seconds * 1000.0 > AUTO_SLOW_FRAME_MSEC


## Lo que elige el jugador (Ajustes o el panel de depuración). Se guarda.
## Automática borra lo recordado y vuelve a medir desde el próximo cuadro.
func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_settings.set_graphics_value(MODE_KEY, MODE_NAMES[mode])
	if mode == Mode.AUTO and _auto_low:
		_auto_low = false
		_settings.set_graphics_value(AUTO_LOW_KEY, false)
	_measuring = mode == Mode.AUTO
	_warmup = 0.0
	_sum = 0.0
	_frames = 0
	level = _level_for_mode()
	changed.emit()


## Si el automático todavía está midiendo (WorldViewport le pasa los
## cuadros mientras tanto).
func is_measuring() -> bool:
	return _measuring


## Cuenta un cuadro que duró `delta` segundos reales. Al terminar la medida,
## si el promedio es lento, baja a Baja y lo recuerda. Sin memoria nueva.
func add_frame(delta: float) -> void:
	if not _measuring:
		return
	if _warmup < AUTO_WARMUP_SECONDS:
		_warmup += delta
		return
	_sum += minf(delta, AUTO_MAX_FRAME_SECONDS)
	_frames += 1
	if _sum < AUTO_WINDOW_SECONDS:
		return
	_measuring = false
	if is_slow(_sum / _frames):
		_auto_low = true
		_settings.set_graphics_value(AUTO_LOW_KEY, true)
		level = Level.LOW
		changed.emit()


func max_width() -> float:
	return MAX_WIDTH[level]


func msaa() -> Viewport.MSAA:
	return MSAA[level]


func sun_shadow() -> bool:
	return SUN_SHADOW[level]


func dust() -> bool:
	return DUST[level]


func floor_ao() -> float:
	return FLOOR_AO[level]


func _level_for_mode() -> Level:
	match mode:
		Mode.HIGH:
			return Level.HIGH
		Mode.LOW:
			return Level.LOW
	return Level.LOW if _auto_low else Level.HIGH

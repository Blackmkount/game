class_name DayCycle
extends Node
## La luz del cuarto según la hora (biblia de arte §6): el sol del motor (el
## único DirectionalLight3D, que de noche es la luna), el ambiente, el
## relleno, la luz de la ventana (con el haz, el polvo y lo que se ve por
## ella), las luces del sombreador (lámparas, monitor, tira LED), las luces
## de noche (halos, focos) y el fondo. Lo que no es el sol lo calcula el
## sombreador del mundo con globales que pone este nodo (hijo de Room): cero
## luces extra y cero llamadas de dibujo extra.
##
## Seis momentos (MOMENTS) en sus horas (KEYS): entre dos se mezcla con
## smoothstep, así la luz es una función continua de la hora (sample(), puro).
## RoomView le pasa el reloj del juego (Events.time_changed, un minuto de
## juego a la vez) con go_to_hour(): la luz no salta al minuto nuevo sino que
## llega mezclándose en BLEND_SECONDS reales, cuadro a cuadro (step(), sin
## memoria nueva). Al cargar una partida, y en las herramientas, set_hour()
## pone la hora de una vez, sin mezcla.
##
## Son números de presentación (no de balance): no cambian nada del juego.

## Los momentos del día (§6.2). "Dirección" es hacia dónde VIAJA la luz.
## Colores en hex; las energías multiplican al color. `fill_character` es el
## refuerzo del relleno para el personaje. `lights`: factor de cada luz del
## sombreador (multiplica su valor base, LIGHTS); la guirnalda
## ("string_lights") es además cuánta noche es (cc_night): las luces de noche
## (focos, halos, ampolletas, pantallas de noche) se encienden con ella.
## `view_mood`: pesos (día, tarde, noche) de lo que se ve por la ventana.
## Fondo y resplandor: §4.1.
const MOMENTS: Dictionary[String, Dictionary] = {
	"dawn": {
		"sun_direction": Vector3(0.6, -0.4, -0.7), "sun_color": "ffc4a6", "sun_energy": 0.28,
		"sky": "9490cc", "sky_energy": 0.52, "ground": "b08a80", "ground_energy": 0.4,
		"window_direction": Vector3(0.74, -0.45, -0.5), "window_color": "ffc4a0", "window_energy": 0.35,
		"fill_color": "ffe8e0", "fill_energy": 0.16, "fill_character": 0.25,
		"background_center": "202750", "background_edge": "11152b", "background_glow": "5a3d6a",
		"view_mood": Vector3(0.35, 0.35, 0.3),
		"lights": {
			"desk_lamp": 0.4, "monitor": 0.3, "bed_lamp": 0.3, "led_strip": 0.0,
			"printer_led": 1.0, "string_lights": 0.3, "window_shaft": 0.3,
		},
	},
	# La luz de la ventana tiene la altura del sol y gira 10° hacia la pared
	# de la ventana: así el parche de sol cruza la impresora del piso (Arte
	# 2.0, paso 5, docs/DECISIONES.md).
	"morning": {
		"sun_direction": Vector3(0.707, -0.566, -0.424), "sun_color": "fff0dc", "sun_energy": 0.48,
		"sky": "bfcdf0", "sky_energy": 0.62, "ground": "e6bb92", "ground_energy": 0.5,
		"window_direction": Vector3(0.774, -0.559, -0.297), "window_color": "ffe2b0", "window_energy": 0.85,
		"fill_color": "fff4ea", "fill_energy": 0.22, "fill_character": 0.25,
		"background_center": "26335c", "background_edge": "141b2d", "background_glow": "3a4a7a",
		"view_mood": Vector3(1.0, 0.0, 0.0),
		"lights": {
			"desk_lamp": 0.0, "monitor": 0.12, "bed_lamp": 0.0, "led_strip": 0.0,
			"printer_led": 1.0, "string_lights": 0.0, "window_shaft": 1.0,
		},
	},
	"noon": {
		"sun_direction": Vector3(0.22, -0.88, -0.42), "sun_color": "fff8ee", "sun_energy": 0.52,
		"sky": "bccaea", "sky_energy": 0.68, "ground": "dcb594", "ground_energy": 0.52,
		"window_direction": Vector3(0.55, -0.8, -0.24), "window_color": "fff6e6", "window_energy": 0.45,
		"fill_color": "fff4ea", "fill_energy": 0.18, "fill_character": 0.25,
		"background_center": "28365f", "background_edge": "151c30", "background_glow": "3a4a7a",
		"view_mood": Vector3(1.0, 0.0, 0.0),
		"lights": {
			"desk_lamp": 0.0, "monitor": 0.12, "bed_lamp": 0.0, "led_strip": 0.0,
			"printer_led": 1.0, "string_lights": 0.0, "window_shaft": 0.6,
		},
	},
	# La tarde dorada del prototipo ganador, a propósito (§6.2): el sol tira
	# las sombras de la planta en la pared del fondo y la ventana manda los
	# rayos hacia la cámara.
	"golden": {
		"sun_direction": Vector3(0.6, -0.44, -0.66), "sun_color": "ffb874", "sun_energy": 0.56,
		"sky": "a597d0", "sky_energy": 0.58, "ground": "e8a070", "ground_energy": 0.52,
		"window_direction": Vector3(0.86, -0.34, 0.38), "window_color": "ffad5c", "window_energy": 0.75,
		"fill_color": "ffe0c8", "fill_energy": 0.16, "fill_character": 0.25,
		"background_center": "2c2450", "background_edge": "17142e", "background_glow": "5a3d6a",
		"view_mood": Vector3(0.0, 1.0, 0.0),
		"lights": {
			"desk_lamp": 0.25, "monitor": 0.3, "bed_lamp": 0.2, "led_strip": 0.0,
			"printer_led": 1.0, "string_lights": 0.2, "window_shaft": 1.0,
		},
	},
	"dusk": {
		"sun_direction": Vector3(0.66, -0.3, -0.69), "sun_color": "ff9078", "sun_energy": 0.22,
		"sky": "7c74b8", "sky_energy": 0.52, "ground": "a2706a", "ground_energy": 0.4,
		"window_direction": Vector3(0.8, -0.3, 0.52), "window_color": "ff8a7a", "window_energy": 0.25,
		"fill_color": "e0d0ff", "fill_energy": 0.18, "fill_character": 0.35,
		"background_center": "231f4a", "background_edge": "121230", "background_glow": "5a3d6a",
		"view_mood": Vector3(0.0, 0.45, 0.55),
		"lights": {
			"desk_lamp": 0.75, "monitor": 0.4, "bed_lamp": 0.6, "led_strip": 0.6,
			"printer_led": 1.0, "string_lights": 0.6, "window_shaft": 0.2,
		},
	},
	# De noche el sol del motor es la luna.
	"night": {
		"sun_direction": Vector3(0.5, -0.7, -0.5), "sun_color": "9ab0ff", "sun_energy": 0.18,
		"sky": "6a7ad0", "sky_energy": 0.74, "ground": "5e4c78", "ground_energy": 0.46,
		"window_direction": Vector3(0.7, -0.62, -0.35), "window_color": LookPalette.MOON, "window_energy": 0.3,
		"fill_color": "b8c4ff", "fill_energy": 0.2, "fill_character": 0.45,
		"background_center": "121a33", "background_edge": "070a16", "background_glow": "1c2a55",
		"view_mood": Vector3(0.0, 0.0, 1.0),
		"lights": {
			"desk_lamp": 1.0, "monitor": 0.5, "bed_lamp": 1.0, "led_strip": 1.0,
			"printer_led": 1.0, "string_lights": 1.0, "window_shaft": 0.0,
		},
	},
}

## Cuándo es cada momento (§6.1): la hora y el momento que se ve justo
## entonces. Entre dos claves la luz se mezcla con smoothstep; dos claves
## seguidas del mismo momento lo mantienen (la mañana de 07:00 a 10:30, la
## tarde dorada de 16:30 a 18:00 y la noche de 20:15 a 05:00).
const KEYS: Array[Array] = [
	[0.0, "night"], [5.0, "night"], [5.75, "dawn"], [7.0, "morning"], [10.5, "morning"],
	[12.5, "noon"], [16.5, "golden"], [18.0, "golden"], [19.25, "dusk"], [20.25, "night"],
	[24.0, "night"],
]
## Las luces del sombreador y los efectos que cambian con la hora, en el
## orden en que se guardan sus factores (Light.factors).
const FACTORS: Array[String] = ["desk_lamp", "monitor", "bed_lamp", "led_strip", "printer_led", "string_lights", "window_shaft"]
## La guirnalda: su factor es también cuánta noche es.
const NIGHT_FACTOR: String = "string_lights"

## Las luces del sombreador con factor 1 (§6.2): índice del global cc_plN,
## color, intensidad y alcance (m). La tira LED es un segmento aparte.
const LIGHTS: Dictionary[String, Dictionary] = {
	"desk_lamp": {"slot": 0, "color": LookPalette.LAMP, "intensity": 1.4, "range": 3.3},
	"monitor": {"slot": 1, "color": LookPalette.MONITOR, "intensity": 0.6, "range": 1.8},
	"bed_lamp": {"slot": 2, "color": LookPalette.BED_LAMP, "intensity": 1.0, "range": 2.6},
	"printer_led": {"slot": 3, "color": LookPalette.BED_LED, "intensity": 0.55, "range": 0.75},
}
const LED_STRIP_COLOR: String = LookPalette.LED_STRIP
const LED_STRIP_INTENSITY: float = 0.85
const LED_STRIP_RANGE: float = 2.1
const LED_STRIP_FROM: Vector3 = Vector3(-2.1, 2.72, -2.96)
const LED_STRIP_TO: Vector3 = Vector3(2.6, 2.72, -2.96)
## Dirección del relleno: del lado de la cámara.
const FILL_DIRECTION: Vector3 = Vector3(0.61, 0.5, 0.61)
## Fuerza del resplandor detrás del diorama (§4.1).
const BACKGROUND_GLOW_STRENGTH: float = 0.55
## Fuerza del haz de luz de la ventana con factor 1 (window_shaft.gdshader).
const WINDOW_SHAFT_STRENGTH: float = 0.22
## Lo que tarda la luz en llegar a la hora nueva cuando avanza el reloj
## (segundos reales). Un minuto de juego dura hoy 2,5 s (data/config.json):
## cada paso termina antes de que llegue el siguiente y la luz avanza pareja.
## Un salto grande del reloj se ve como un lapso acelerado del mismo largo.
const BLEND_SECONDS: float = 2.0
## Los globales de cada luz del sombreador.
const LIGHT_GLOBALS: Array[StringName] = [&"cc_pl0", &"cc_pl1", &"cc_pl2", &"cc_pl3"]
const LIGHT_COLOR_GLOBALS: Array[StringName] = [&"cc_pl0_col", &"cc_pl1_col", &"cc_pl2_col", &"cc_pl3_col"]


## Los valores de luz de un momento, o de la mezcla de dos, listos para
## usar: colores ya multiplicados por su energía (espacio de la pantalla) y
## direcciones normalizadas. mix() escribe sobre el mismo objeto: mezclar en
## cada cuadro no pide memoria.
class Light:
	var sun_direction: Vector3
	var sun_color: Color
	var sun_energy: float
	var ambient_sky: Vector3
	var ambient_ground: Vector3
	var window_direction: Vector3
	var window_color: Vector3
	var fill: Vector3
	var fill_character: float
	var background_center: Color
	var background_edge: Color
	var background_glow: Color
	var view_mood: Vector3
	## Factor de cada luz, en el orden de DayCycle.FACTORS.
	var factors: PackedFloat32Array = PackedFloat32Array()

	func _init() -> void:
		factors.resize(DayCycle.FACTORS.size())

	## Este objeto con los valores de un momento de MOMENTS.
	func set_moment(moment: Dictionary) -> void:
		sun_direction = (moment["sun_direction"] as Vector3).normalized()
		sun_color = Color(moment["sun_color"] as String)
		sun_energy = moment["sun_energy"]
		ambient_sky = DayCycle._scaled(moment["sky"], moment["sky_energy"])
		ambient_ground = DayCycle._scaled(moment["ground"], moment["ground_energy"])
		window_direction = (moment["window_direction"] as Vector3).normalized()
		window_color = DayCycle._scaled(moment["window_color"], moment["window_energy"])
		fill = DayCycle._scaled(moment["fill_color"], moment["fill_energy"])
		fill_character = moment["fill_character"]
		background_center = Color(moment["background_center"] as String)
		background_edge = Color(moment["background_edge"] as String)
		background_glow = Color(moment["background_glow"] as String) * DayCycle.BACKGROUND_GLOW_STRENGTH
		view_mood = moment["view_mood"]
		var lights: Dictionary = moment["lights"]
		for i: int in DayCycle.FACTORS.size():
			factors[i] = lights[DayCycle.FACTORS[i]]

	## Este objeto con la mezcla de `a` y `b` (0 = a, 1 = b).
	func mix(a: Light, b: Light, t: float) -> void:
		sun_direction = a.sun_direction.lerp(b.sun_direction, t).normalized()
		sun_color = a.sun_color.lerp(b.sun_color, t)
		sun_energy = lerpf(a.sun_energy, b.sun_energy, t)
		ambient_sky = a.ambient_sky.lerp(b.ambient_sky, t)
		ambient_ground = a.ambient_ground.lerp(b.ambient_ground, t)
		window_direction = a.window_direction.lerp(b.window_direction, t).normalized()
		window_color = a.window_color.lerp(b.window_color, t)
		fill = a.fill.lerp(b.fill, t)
		fill_character = lerpf(a.fill_character, b.fill_character, t)
		background_center = a.background_center.lerp(b.background_center, t)
		background_edge = a.background_edge.lerp(b.background_edge, t)
		background_glow = a.background_glow.lerp(b.background_glow, t)
		view_mood = a.view_mood.lerp(b.view_mood, t)
		for i: int in factors.size():
			factors[i] = lerpf(a.factors[i], b.factors[i], t)

	## Si se ve igual que `other`.
	func looks_like(other: Light) -> bool:
		for i: int in factors.size():
			if not is_equal_approx(factors[i], other.factors[i]):
				return false
		return sun_direction.is_equal_approx(other.sun_direction) and sun_color.is_equal_approx(other.sun_color) \
			and is_equal_approx(sun_energy, other.sun_energy) and ambient_sky.is_equal_approx(other.ambient_sky) \
			and ambient_ground.is_equal_approx(other.ambient_ground) and window_direction.is_equal_approx(other.window_direction) \
			and window_color.is_equal_approx(other.window_color) and fill.is_equal_approx(other.fill) \
			and is_equal_approx(fill_character, other.fill_character) and background_center.is_equal_approx(other.background_center) \
			and background_edge.is_equal_approx(other.background_edge) and background_glow.is_equal_approx(other.background_glow) \
			and view_mood.is_equal_approx(other.view_mood)

	func factor(light_name: String) -> float:
		return factors[DayCycle.FACTORS.find(light_name)]


## Los momentos ya convertidos (Light) y la hora de cada clave de KEYS, en
## el mismo orden. Se arman una vez.
static var _key_hours: PackedFloat32Array = PackedFloat32Array()
static var _key_lights: Array[Light] = []

## El sol del cuarto, el material del fondo, los halos de noche y el polvo
## del haz de la ventana (los arma RoomView).
var sun: DirectionalLight3D
var backdrop: ShaderMaterial
var halos: HaloField
var dust: DustField
## La tira LED de la pared del fondo solo existe en el taller (la decoración
## de nivel 5+, RoomDecor): sin ella no alumbra aunque sea de noche. Después
## de cambiarla, refresh().
var led_strip_on: bool = false

## La luz que se ve ahora y la de la hora adonde va (para saber si cambia).
var _light: Light = Light.new()
var _target: Light = Light.new()
## La mezcla en curso: de qué hora a qué hora (horas desde el inicio de la
## partida: crecen siempre) y cuánto va (1 = llegó).
var _from_hour: float = 0.0
var _to_hour: float = 0.0
var _progress: float = 1.0
## Las luces del sombreador, listas para cada cuadro, en el orden de LIGHTS:
## el índice de su factor en FACTORS, su global, su color × intensidad y lo
## que se publica en su global cc_plN: su lugar (x, y, z) y su alcance (w; 0
## mientras no tiene lugar: no alumbra).
var _lamp_factor: PackedInt32Array = PackedInt32Array()
var _lamp_slot: PackedInt32Array = PackedInt32Array()
var _lamp_color: PackedVector3Array = PackedVector3Array()
var _lamp_place: PackedVector4Array = PackedVector4Array()
var _strip_color: Vector3 = _scaled(LED_STRIP_COLOR, LED_STRIP_INTENSITY)
var _night_index: int = FACTORS.find(NIGHT_FACTOR)
var _shaft_index: int = FACTORS.find("window_shaft")
var _strip_index: int = FACTORS.find("led_strip")
## Lo que se ve por la ventana y el haz de luz (materiales de la caché).
var _view: ShaderMaterial = WorldPalette.glow("ffffff", WorldPalette.WINDOW_VIEW)
var _shaft: ShaderMaterial = WorldPalette.window_shaft()


func _init() -> void:
	_prepare_keys()
	for light_name: String in LIGHTS:
		var light: Dictionary = LIGHTS[light_name]
		_lamp_factor.append(FACTORS.find(light_name))
		_lamp_slot.append(light["slot"])
		_lamp_color.append(_scaled(light["color"], light["intensity"]))
		_lamp_place.append(Vector4.ZERO)


## Los valores de luz de la hora `hour` (horas; se cuentan desde la
## medianoche, más de 24 es otro día), listos para usar: colores ya
## multiplicados por su energía y direcciones normalizadas. Puro.
static func sample(hour: float) -> Dictionary:
	var light: Light = Light.new()
	mix_at(hour, light)
	var lights: Dictionary = {}
	for i: int in FACTORS.size():
		lights[FACTORS[i]] = light.factors[i]
	return {
		"sun_direction": light.sun_direction,
		"sun_color": light.sun_color,
		"sun_energy": light.sun_energy,
		"ambient_sky": light.ambient_sky,
		"ambient_ground": light.ambient_ground,
		"window_direction": light.window_direction,
		"window_color": light.window_color,
		"fill": light.fill,
		"fill_character": light.fill_character,
		"background_center": light.background_center,
		"background_edge": light.background_edge,
		"background_glow": light.background_glow,
		"night": light.factor(NIGHT_FACTOR),
		"view_mood": light.view_mood,
		"window_shaft": WINDOW_SHAFT_STRENGTH * light.factor("window_shaft"),
		"lights": lights,
	}


## Escribe en `out` la luz de la hora `hour`: la mezcla con smoothstep de
## las dos claves de KEYS que la rodean. Sin memoria nueva.
static func mix_at(hour: float, out: Light) -> void:
	_prepare_keys()
	var h: float = fposmod(hour, 24.0)
	var last: int = _key_hours.size() - 1
	for i: int in last:
		if h <= _key_hours[i + 1] or i == last - 1:
			var span: float = maxf(_key_hours[i + 1] - _key_hours[i], 0.001)
			var t: float = smoothstep(0.0, 1.0, (h - _key_hours[i]) / span)
			out.mix(_key_lights[i], _key_lights[i + 1], t)
			return


## Pone una luz del sombreador (nombre de LIGHTS) en su lugar del cuarto.
## Después, refresh().
func place_light(light_name: String, position: Vector3) -> void:
	var reach: float = LIGHTS[light_name]["range"]
	_lamp_place[LIGHTS.keys().find(light_name)] = Vector4(position.x, position.y, position.z, reach)


## Lo que la luz `light_name` (nombre de LIGHTS) publica en su global cc_plN:
## su lugar (x, y, z) y su alcance (w; 0 = sin lugar o no es una luz: no
## alumbra).
func light_place(light_name: String) -> Vector4:
	var index: int = LIGHTS.keys().find(light_name)
	return _lamp_place[index] if index >= 0 else Vector4.ZERO


## Pone la luz de la hora `hour` de una vez, sin mezcla: al armar el cuarto,
## al cargar una partida y en las herramientas (capturas).
func set_hour(hour: float) -> void:
	_from_hour = hour
	_to_hour = hour
	_progress = 1.0
	_show(hour)


## El reloj del juego llegó a `hour` (horas desde el inicio de la partida):
## la luz va hacia ahí mezclándose (step()). Si el reloj volvió atrás, como
## al cargar otra partida, va de una vez.
func go_to_hour(hour: float) -> void:
	var shown: float = shown_hour()
	if hour < shown:
		set_hour(hour)
		return
	mix_at(hour, _target)
	if _target.looks_like(_light):
		# En la mitad de un momento la luz no cambia: nada que mezclar.
		_from_hour = hour
		_to_hour = hour
		_progress = 1.0
		return
	_from_hour = shown
	_to_hour = hour
	_progress = 0.0


## Avanza la mezcla en curso `delta` segundos reales (lo llama RoomView en
## cada cuadro). Sin mezcla no hace nada; con ella, no pide memoria.
func step(delta: float) -> void:
	if _progress >= 1.0:
		return
	_progress = minf(_progress + delta / BLEND_SECONDS, 1.0)
	_show(shown_hour())


## La hora cuya luz se ve ahora (horas desde el inicio de la partida).
func shown_hour() -> float:
	return lerpf(_from_hour, _to_hour, _progress)


## Si la luz todavía va llegando a la hora del reloj.
func is_blending() -> bool:
	return _progress < 1.0


## Vuelve a poner la luz que se ve (cambió algo de lo que alumbra: una luz
## de lugar, la tira LED).
func refresh() -> void:
	_show(shown_hour())


## Aplica la luz de la hora `hour` a todo el mundo.
func _show(hour: float) -> void:
	mix_at(hour, _light)
	var light: Light = _light
	if sun != null:
		sun.basis = Basis.looking_at(light.sun_direction, Vector3.UP)
		sun.light_color = light.sun_color
		sun.light_energy = light.sun_energy
	if backdrop != null:
		backdrop.set_shader_parameter(&"center_color", light.background_center)
		backdrop.set_shader_parameter(&"edge_color", light.background_edge)
		backdrop.set_shader_parameter(&"glow_color", light.background_glow)
	_publish(&"cc_amb_sky", light.ambient_sky)
	_publish(&"cc_amb_ground", light.ambient_ground)
	_publish(&"cc_window_dir", light.window_direction)
	_publish(&"cc_window_color", light.window_color)
	_publish(&"cc_fill_dir", FILL_DIRECTION.normalized())
	_publish(&"cc_fill", Vector4(light.fill.x, light.fill.y, light.fill.z, light.fill_character))
	var night: float = light.factors[_night_index]
	_publish(&"cc_night", night)
	if halos != null:
		halos.set_night(night)
	_view.set_shader_parameter(&"mood", light.view_mood)
	var shaft: float = light.factors[_shaft_index]
	_shaft.set_shader_parameter(&"strength", WINDOW_SHAFT_STRENGTH * shaft)
	if dust != null:
		dust.set_strength(shaft)
	for i: int in _lamp_slot.size():
		var color: Vector3 = _lamp_color[i] * light.factors[_lamp_factor[i]]
		_publish(LIGHT_GLOBALS[_lamp_slot[i]], _lamp_place[i])
		_publish(LIGHT_COLOR_GLOBALS[_lamp_slot[i]], Vector4(color.x, color.y, color.z, 1.0))
	var strip: Vector3 = _strip_color * (light.factors[_strip_index] if led_strip_on else 0.0)
	_publish(&"cc_strip_a", LED_STRIP_FROM)
	_publish(&"cc_strip_b", LED_STRIP_TO)
	_publish(&"cc_strip_col", Vector4(strip.x, strip.y, strip.z, LED_STRIP_RANGE))


## Convierte MOMENTS y KEYS una vez.
static func _prepare_keys() -> void:
	if not _key_lights.is_empty():
		return
	var moments: Dictionary[String, Light] = {}
	for moment_name: String in MOMENTS:
		var light: Light = Light.new()
		light.set_moment(MOMENTS[moment_name])
		moments[moment_name] = light
	for key: Array in KEYS:
		_key_hours.append(key[0])
		_key_lights.append(moments[key[1]])


## Un color hex por una energía, como lo usa el sombreador (espacio de la
## pantalla, sin convertir).
static func _scaled(hex: String, energy: float) -> Vector3:
	var color: Color = Color(hex)
	return Vector3(color.r, color.g, color.b) * energy


static func _publish(parameter: StringName, value: Variant) -> void:
	RenderingServer.global_shader_parameter_set(parameter, value)

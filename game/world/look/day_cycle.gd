class_name DayCycle
extends Node
## La luz del cuarto según la hora (biblia de arte §6): el sol del motor (el
## único DirectionalLight3D), el ambiente, el relleno, la luz de la ventana
## (con el haz y lo que se ve por ella), las luces del sombreador y el fondo. Lo que no es el sol lo calcula el
## sombreador del mundo con globales que pone este nodo (hijo de Room):
## cero luces extra y cero llamadas de dibujo extra.
##
## Por ahora solo existe la mañana (el inicio del juego). El paso 13 de Arte
## 2.0 agrega los demás momentos, la mezcla entre ellos y la conexión con el
## reloj del juego (Events.time_changed). sample() ya recibe la hora.
##
## Son números de presentación (no de balance), por eso viven aquí.

## Los momentos del día (§6.2). "Dirección" es hacia dónde VIAJA la luz.
## Colores en hex; las energías multiplican al color. `fill_character` es el
## refuerzo del relleno para el personaje. `lights`: factor de cada luz del
## sombreador (multiplica su valor base, LIGHTS).
const MOMENTS: Dictionary[String, Dictionary] = {
	"morning": {
		"sun_direction": Vector3(0.707, -0.566, -0.424), "sun_color": "fff0dc", "sun_energy": 0.48,
		"sky": "bfcdf0", "sky_energy": 0.62, "ground": "e6bb92", "ground_energy": 0.5,
		"window_direction": Vector3(0.774, -0.559, -0.297), "window_color": "ffe2b0", "window_energy": 0.85,
		"fill_color": "fff4ea", "fill_energy": 0.22, "fill_character": 0.25,
		"background_center": "26335c", "background_edge": "141b2d", "background_glow": "3a4a7a",
		"night": 0.0, "view_mood": Vector3(1.0, 0.0, 0.0),
		"lights": {
			"desk_lamp": 0.0, "monitor": 0.12, "bed_lamp": 0.0, "led_strip": 0.0,
			"printer_led": 1.0, "string_lights": 0.0, "window_shaft": 1.0,
		},
	},
}

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
## Los globales de cada luz del sombreador.
const LIGHT_GLOBALS: Array[StringName] = [&"cc_pl0", &"cc_pl1", &"cc_pl2", &"cc_pl3"]
const LIGHT_COLOR_GLOBALS: Array[StringName] = [&"cc_pl0_col", &"cc_pl1_col", &"cc_pl2_col", &"cc_pl3_col"]

## El sol del cuarto y el material del fondo (los arma RoomView).
var sun: DirectionalLight3D
var backdrop: ShaderMaterial

## Dónde está cada luz del sombreador (nombre de LIGHTS → posición). Las que
## no tienen lugar no alumbran.
var _light_positions: Dictionary[String, Vector3] = {}


## Los valores de luz de la hora `hour` (0–24), listos para usar: colores
## ya multiplicados por su energía y direcciones normalizadas. Puro.
static func sample(_hour: float) -> Dictionary:
	var moment: Dictionary = MOMENTS["morning"]
	var lights: Dictionary = moment["lights"]
	return {
		"sun_direction": (moment["sun_direction"] as Vector3).normalized(),
		"sun_color": Color(moment["sun_color"] as String),
		"sun_energy": moment["sun_energy"],
		"ambient_sky": _scaled(moment["sky"], moment["sky_energy"]),
		"ambient_ground": _scaled(moment["ground"], moment["ground_energy"]),
		"window_direction": (moment["window_direction"] as Vector3).normalized(),
		"window_color": _scaled(moment["window_color"], moment["window_energy"]),
		"fill": _scaled(moment["fill_color"], moment["fill_energy"]),
		"fill_character": moment["fill_character"],
		"background_center": Color(moment["background_center"] as String),
		"background_edge": Color(moment["background_edge"] as String),
		"background_glow": Color(moment["background_glow"] as String) * BACKGROUND_GLOW_STRENGTH,
		"night": moment["night"],
		"view_mood": moment["view_mood"],
		"window_shaft": WINDOW_SHAFT_STRENGTH * float(lights["window_shaft"]),
		"lights": lights.duplicate(),
	}


## Pone una luz del sombreador (nombre de LIGHTS) en su lugar del cuarto.
func place_light(light_name: String, position: Vector3) -> void:
	_light_positions[light_name] = position


## Aplica la luz de la hora `hour` a todo el mundo.
func apply_hour(hour: float) -> void:
	var values: Dictionary = sample(hour)
	var direction: Vector3 = values["sun_direction"]
	if sun != null:
		sun.basis = Basis.looking_at(direction, Vector3.UP)
		sun.light_color = values["sun_color"]
		sun.light_energy = values["sun_energy"]
	if backdrop != null:
		backdrop.set_shader_parameter("center_color", values["background_center"])
		backdrop.set_shader_parameter("edge_color", values["background_edge"])
		backdrop.set_shader_parameter("glow_color", values["background_glow"])
	_publish(&"cc_amb_sky", values["ambient_sky"])
	_publish(&"cc_amb_ground", values["ambient_ground"])
	_publish(&"cc_window_dir", values["window_direction"])
	_publish(&"cc_window_color", values["window_color"])
	var fill: Vector3 = values["fill"]
	_publish(&"cc_fill_dir", FILL_DIRECTION.normalized())
	_publish(&"cc_fill", Vector4(fill.x, fill.y, fill.z, values["fill_character"]))
	_publish(&"cc_night", values["night"])
	WorldPalette.glow("ffffff", WorldPalette.WINDOW_VIEW).set_shader_parameter("mood", values["view_mood"])
	WorldPalette.window_shaft().set_shader_parameter("strength", values["window_shaft"])
	var factors: Dictionary = values["lights"]
	for light_name: String in LIGHTS:
		var light: Dictionary = LIGHTS[light_name]
		var slot: int = light["slot"]
		var place: Vector3 = _light_positions.get(light_name, Vector3.ZERO)
		var reach: float = light["range"] if _light_positions.has(light_name) else 0.0
		var color: Vector3 = _scaled(light["color"], float(light["intensity"]) * float(factors[light_name]))
		_publish(LIGHT_GLOBALS[slot], Vector4(place.x, place.y, place.z, reach))
		_publish(LIGHT_COLOR_GLOBALS[slot], Vector4(color.x, color.y, color.z, 1.0))
	var strip: Vector3 = _scaled(LED_STRIP_COLOR, LED_STRIP_INTENSITY * float(factors["led_strip"]))
	_publish(&"cc_strip_a", LED_STRIP_FROM)
	_publish(&"cc_strip_b", LED_STRIP_TO)
	_publish(&"cc_strip_col", Vector4(strip.x, strip.y, strip.z, LED_STRIP_RANGE))


## Un color hex por una energía, como lo usa el sombreador (espacio de la
## pantalla, sin convertir).
static func _scaled(hex: String, energy: float) -> Vector3:
	var color: Color = Color(hex)
	return Vector3(color.r, color.g, color.b) * energy


static func _publish(parameter: StringName, value: Variant) -> void:
	RenderingServer.global_shader_parameter_set(parameter, value)

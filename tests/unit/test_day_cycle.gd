extends GutTest
## La luz del día y de la noche (DayCycle, biblia de arte §6): cada momento
## coincide con la tabla de la biblia, la luz se mezcla sin saltos de un
## momento al otro y minuto a minuto, el reloj la mueve de a poco (y al
## cargar una partida va de una vez), y de noche se lee en un teléfono con el
## brillo bajo. La mañana va de las 07:00 a las 10:30 y es la hora del inicio
## del juego.

## La tabla de la biblia, fila "Mañana". La luz de la ventana tiene la misma
## altura que el sol y gira 10° hacia la pared de la ventana (Arte 2.0, paso
## 5, docs/DECISIONES.md): así el parche de sol cruza la impresora del piso.
const SUN_DIRECTION: Vector3 = Vector3(0.707, -0.566, -0.424)
const WINDOW_DIRECTION: Vector3 = Vector3(0.774, -0.559, -0.297)
## Lo más que se separan las rayas del parche de las sombras del sol, en el
## piso (grados).
const MAX_STRIPE_TURN: float = 10.5
const SUN_COLOR: String = "fff0dc"
const SUN_ENERGY: float = 0.48
const SKY: String = "bfcdf0"
const SKY_ENERGY: float = 0.62
const GROUND: String = "e6bb92"
const GROUND_ENERGY: float = 0.5
const WINDOW_COLOR: String = "ffe2b0"
const WINDOW_ENERGY: float = 0.85
const FILL_COLOR: String = "fff4ea"
const FILL_ENERGY: float = 0.22
const FILL_CHARACTER: float = 0.25
## Factor de cada luz del sombreador en la mañana.
const LIGHT_FACTORS: Dictionary[String, float] = {
	"desk_lamp": 0.0, "monitor": 0.12, "bed_lamp": 0.0, "led_strip": 0.0,
	"printer_led": 1.0, "string_lights": 0.0, "window_shaft": 1.0,
}
const MORNING_HOURS: Array[float] = [7.0, 8.0, 8.25, 10.5]

## Las columnas de la tabla de luces del sombreador de la biblia (§6.2), en
## su orden: lámpara del escritorio, monitor, lámpara de la cama, tira LED,
## LED de la impresora del piso, guirnalda y haz y polvo.
const LIGHT_NAMES: Array[String] = ["desk_lamp", "monitor", "bed_lamp", "led_strip", "printer_led", "string_lights", "window_shaft"]
## Los otros cinco momentos de la biblia (§6.1 y §6.2), con las horas en que
## se ven tal cual: sol (dirección, color, energía), ambiente de arriba y de
## abajo, ventana (dirección, color, fuerza), relleno y su refuerzo para el
## personaje, factores de las luces (LIGHT_NAMES) y fondo (§4.1: centro,
## borde y resplandor; el resplandor del alba y del atardecer no lo dice la
## biblia).
const MOMENTS: Dictionary[String, Dictionary] = {
	"alba": {
		"hours": [5.75], "sun": [Vector3(0.6, -0.4, -0.7), "ffc4a6", 0.28],
		"sky": ["9490cc", 0.52], "ground": ["b08a80", 0.4],
		"window": [Vector3(0.74, -0.45, -0.5), "ffc4a0", 0.35], "fill": ["ffe8e0", 0.16, 0.25],
		"lights": [0.4, 0.3, 0.3, 0.0, 1.0, 0.3, 0.3], "background": ["202750", "11152b", ""],
	},
	"mediodía": {
		"hours": [12.5], "sun": [Vector3(0.22, -0.88, -0.42), "fff8ee", 0.52],
		"sky": ["bccaea", 0.68], "ground": ["dcb594", 0.52],
		"window": [Vector3(0.55, -0.8, -0.24), "fff6e6", 0.45], "fill": ["fff4ea", 0.18, 0.25],
		"lights": [0.0, 0.12, 0.0, 0.0, 1.0, 0.0, 0.6], "background": ["28365f", "151c30", "3a4a7a"],
	},
	"tarde dorada": {
		"hours": [16.5, 17.25, 18.0], "sun": [Vector3(0.6, -0.44, -0.66), "ffb874", 0.56],
		"sky": ["a597d0", 0.58], "ground": ["e8a070", 0.52],
		"window": [Vector3(0.86, -0.34, 0.38), "ffad5c", 0.75], "fill": ["ffe0c8", 0.16, 0.25],
		"lights": [0.25, 0.3, 0.2, 0.0, 1.0, 0.2, 1.0], "background": ["2c2450", "17142e", "5a3d6a"],
	},
	"atardecer": {
		"hours": [19.25], "sun": [Vector3(0.66, -0.3, -0.69), "ff9078", 0.22],
		"sky": ["7c74b8", 0.52], "ground": ["a2706a", 0.4],
		"window": [Vector3(0.8, -0.3, 0.52), "ff8a7a", 0.25], "fill": ["e0d0ff", 0.18, 0.35],
		"lights": [0.75, 0.4, 0.6, 0.6, 1.0, 0.6, 0.2], "background": ["231f4a", "121230", ""],
	},
	"noche": {
		"hours": [20.25, 22.0, 0.0, 3.0, 5.0], "sun": [Vector3(0.5, -0.7, -0.5), "9ab0ff", 0.18],
		"sky": ["6a7ad0", 0.74], "ground": ["5e4c78", 0.46],
		"window": [Vector3(0.7, -0.62, -0.35), "9db4ff", 0.3], "fill": ["b8c4ff", 0.2, 0.45],
		"lights": [1.0, 0.5, 1.0, 1.0, 1.0, 1.0, 0.0], "background": ["121a33", "070a16", "1c2a55"],
	},
}
## Fuerza del resplandor detrás del diorama (§4.1).
const GLOW_STRENGTH: float = 0.55
## Lo más que cambia la luz en un minuto de juego: cualquier color (por
## canal), energía o factor, y el giro de una dirección (grados; lo que más
## gira es la luz de la ventana del atardecer a la noche, ~1,5° por minuto).
const MAX_CHANGE_PER_MINUTE: float = 0.035
const MAX_TURN_PER_MINUTE: float = 2.0
## Biblia §6.4: un gris medio (albedo 0,5) del piso lejos de las luces, de
## noche, se ve con al menos esta luminancia en la pantalla.
const NIGHT_FLOOR_MIN: float = 70.0 / 255.0
const NIGHT_HOURS: Array[float] = [20.25, 22.0, 0.0, 3.0, 5.0]
## Lo mismo que hace el sombreador (kit_body.gdshaderinc, light(), y
## world_light.gdshaderinc, cc_world_light()) en un punto del piso que mira
## hacia arriba, sin oclusión, al sol y sin brillo: la envoltura y la mitad
## del ancho del terminador, la luz de borde y el relleno (cuánto de la
## dirección y desde dónde).
const WRAP: float = 0.35
const TERMINATOR: float = 0.18
const RIM: float = 0.28
const FILL_SPREAD: Vector2 = Vector2(0.6, 0.4)
## Pesos de la luminancia (Rec. 709).
const LUMA: Vector3 = Vector3(0.2126, 0.7152, 0.0722)
## Un cuadro a 60 por segundo.
const FRAME: float = 1.0 / 60.0


func test_the_morning_matches_the_art_bible() -> void:
	for hour: float in MORNING_HOURS:
		var light: Dictionary = DayCycle.sample(hour)
		var label: String = "a las %.2f" % hour
		_assert_vec(light["sun_direction"], SUN_DIRECTION.normalized(), "Sol " + label)
		assert_eq(light["sun_color"], Color(SUN_COLOR), label)
		assert_almost_eq(float(light["sun_energy"]), SUN_ENERGY, 0.0001, label)
		_assert_vec(light["ambient_sky"], _scaled(SKY, SKY_ENERGY), "Ambiente de arriba " + label)
		_assert_vec(light["ambient_ground"], _scaled(GROUND, GROUND_ENERGY), "Rebote de abajo " + label)
		_assert_vec(light["window_direction"], WINDOW_DIRECTION.normalized(), "Ventana: dirección " + label)
		var sun: Vector3 = light["sun_direction"]
		var window: Vector3 = light["window_direction"]
		assert_almost_eq(window.y, sun.y, 0.01, "La ventana tiene la altura del sol " + label)
		var turn: float = rad_to_deg(absf(Vector2(sun.x, sun.z).angle_to(Vector2(window.x, window.z))))
		assert_lte(turn, MAX_STRIPE_TURN, "Las rayas casi paralelas a las sombras " + label)
		_assert_vec(light["window_color"], _scaled(WINDOW_COLOR, WINDOW_ENERGY), "Ventana " + label)
		_assert_vec(light["fill"], _scaled(FILL_COLOR, FILL_ENERGY), "Relleno " + label)
		assert_almost_eq(float(light["fill_character"]), FILL_CHARACTER, 0.0001, label)
		assert_eq(float(light["night"]), 0.0, label)
		assert_eq(light["background_center"], Color("26335c"), "Fondo (biblia §4.1) " + label)
		assert_eq(light["background_edge"], Color("141b2d"), label)
		assert_eq(light["background_glow"], Color("3a4a7a") * GLOW_STRENGTH, label)
		assert_eq(light["view_mood"], Vector3(1.0, 0.0, 0.0), "Por la ventana, el día " + label)
		var factors: Dictionary = light["lights"]
		for light_name: String in LIGHT_FACTORS:
			assert_almost_eq(float(factors[light_name]), LIGHT_FACTORS[light_name], 0.0001, light_name + " " + label)


func test_every_other_moment_matches_the_art_bible() -> void:
	for moment_name: String in MOMENTS:
		var bible: Dictionary = MOMENTS[moment_name]
		for hour: float in bible["hours"]:
			var light: Dictionary = DayCycle.sample(hour)
			var label: String = "%s (%.2f)" % [moment_name, hour]
			var sun: Array = bible["sun"]
			_assert_vec(light["sun_direction"], (sun[0] as Vector3).normalized(), "Sol: dirección, " + label)
			_assert_color(light["sun_color"], Color(sun[1] as String), "Sol: color, " + label)
			assert_almost_eq(float(light["sun_energy"]), float(sun[2]), 0.0001, "Sol: energía, " + label)
			_assert_vec(light["ambient_sky"], _scaled(bible["sky"][0], bible["sky"][1]), "Ambiente de arriba, " + label)
			_assert_vec(light["ambient_ground"], _scaled(bible["ground"][0], bible["ground"][1]), "Rebote de abajo, " + label)
			var window: Array = bible["window"]
			_assert_vec(light["window_direction"], (window[0] as Vector3).normalized(), "Ventana: dirección, " + label)
			_assert_vec(light["window_color"], _scaled(window[1], window[2]), "Ventana: color, " + label)
			var fill: Array = bible["fill"]
			_assert_vec(light["fill"], _scaled(fill[0], fill[1]), "Relleno, " + label)
			assert_almost_eq(float(light["fill_character"]), float(fill[2]), 0.0001, "Refuerzo del personaje, " + label)
			var factors: Dictionary = light["lights"]
			for i: int in LIGHT_NAMES.size():
				assert_almost_eq(float(factors[LIGHT_NAMES[i]]), float(bible["lights"][i]), 0.0001, "%s, %s" % [LIGHT_NAMES[i], label])
			assert_almost_eq(float(light["night"]), float(factors["string_lights"]), 0.0001, "La noche se enciende con la guirnalda, " + label)
			assert_almost_eq(float(light["window_shaft"]), DayCycle.WINDOW_SHAFT_STRENGTH * float(factors["window_shaft"]), 0.0001, "Haz, " + label)
			var background: Array = bible["background"]
			_assert_color(light["background_center"], Color(background[0] as String), "Fondo: centro, " + label)
			_assert_color(light["background_edge"], Color(background[1] as String), "Fondo: borde, " + label)
			if background[2] != "":
				_assert_color(light["background_glow"], Color(background[2] as String) * GLOW_STRENGTH, "Resplandor, " + label)
	assert_eq(DayCycle.sample(12.5)["view_mood"], Vector3(1.0, 0.0, 0.0), "Por la ventana: día al mediodía")
	assert_eq(DayCycle.sample(17.0)["view_mood"], Vector3(0.0, 1.0, 0.0), "tarde en la tarde dorada")
	assert_eq(DayCycle.sample(23.0)["view_mood"], Vector3(0.0, 0.0, 1.0), "y noche de noche")
	assert_eq(float(DayCycle.sample(23.0)["night"]), 1.0, "Noche entera")


func test_the_light_never_jumps_from_one_minute_to_the_next() -> void:
	var worst: float = 0.0
	var worst_turn: float = 0.0
	var before: Dictionary = DayCycle.sample(0.0)
	for minute: int in range(1, 24 * 60 + 1):
		var now: Dictionary = DayCycle.sample(minute / 60.0)
		var change: Vector2 = _difference(before, now)
		worst = maxf(worst, change.x)
		worst_turn = maxf(worst_turn, change.y)
		before = now
	assert_lte(worst, MAX_CHANGE_PER_MINUTE, "Ningún color, energía ni luz cambia de golpe en un minuto")
	assert_lte(worst_turn, MAX_TURN_PER_MINUTE, "Ni gira el sol o la ventana de golpe")
	gut.p("Lo más que cambia la luz en un minuto: %.4f (giro %.2f°)" % [worst, worst_turn])
	assert_eq(_difference(DayCycle.sample(24.0), DayCycle.sample(0.0)), Vector2.ZERO, "Las 24:00 son la medianoche")
	assert_eq(_difference(DayCycle.sample(24.0 + 17.25), DayCycle.sample(17.25)), Vector2.ZERO, "Y otro día, la misma luz")


func test_two_moments_blend_with_smoothstep() -> void:
	# Del atardecer (19:15) a la noche (20:15): a un cuarto de camino pesa la
	# noche smoothstep(0,25) = 0,15625.
	var weight: float = smoothstep(0.0, 1.0, 0.25)
	var light: Dictionary = DayCycle.sample(19.5)
	assert_almost_eq(float(light["sun_energy"]), lerpf(0.22, 0.18, weight), 0.0001, "Energía del sol")
	assert_almost_eq(float((light["lights"] as Dictionary)["desk_lamp"]), lerpf(0.75, 1.0, weight), 0.0001, "Lámpara")
	_assert_vec(light["ambient_sky"], _scaled("7c74b8", 0.52).lerp(_scaled("6a7ad0", 0.74), weight), "Ambiente")
	# En la mitad, la mitad.
	assert_almost_eq(float(DayCycle.sample(19.75)["night"]), lerpf(0.6, 1.0, 0.5), 0.0001, "Noche a medias")


func test_the_desk_lamp_is_off_at_ten_and_on_at_night() -> void:
	assert_eq(float((DayCycle.sample(10.0)["lights"] as Dictionary)["desk_lamp"]), 0.0, "A las 10:00, apagada")
	assert_eq(float((DayCycle.sample(22.0)["lights"] as Dictionary)["desk_lamp"]), 1.0, "A las 22:00, encendida")


## Biblia §6.4: con la cuenta del sombreador, un gris medio del piso lejos de
## las luces se ve con al menos 70/255 de noche (el teléfono con el brillo
## bajo). Además el piso de verdad (la baldosa más oscura del damero) nunca
## baja de eso, a ninguna hora.
func test_the_night_floor_reads_on_a_dim_phone() -> void:
	var gray: Color = Color(0.5, 0.5, 0.5)
	for hour: float in NIGHT_HOURS:
		var luma: float = _floor_luma(DayCycle.sample(hour), gray)
		assert_gte(luma, NIGHT_FLOOR_MIN, "Gris medio de noche a las %.2f: %.1f/255" % [hour, luma * 255.0])
	gut.p("Gris medio del piso de noche: %.1f/255" % (_floor_luma(DayCycle.sample(22.0), gray) * 255.0))
	var tile: Color = Color(LookPalette.FLOOR_TILE_B)
	var darkest: float = INF
	for minute: int in 24 * 60:
		darkest = minf(darkest, _floor_luma(DayCycle.sample(minute / 60.0), tile))
	assert_gte(darkest, NIGHT_FLOOR_MIN, "La baldosa, a cualquier hora: %.1f/255" % (darkest * 255.0))


func test_sample_is_pure() -> void:
	var first: Dictionary = DayCycle.sample(8.0)
	(first["lights"] as Dictionary)["monitor"] = 5.0
	assert_almost_eq(float((DayCycle.sample(8.0)["lights"] as Dictionary)["monitor"]), 0.12, 0.0001, "Cambiar lo devuelto no cambia la tabla")


func test_the_sun_of_the_room_takes_the_morning() -> void:
	var cycle: DayCycle = _cycle()
	cycle.set_hour(8.0)
	_assert_vec(-cycle.sun.global_basis.z, SUN_DIRECTION.normalized(), "La luz viaja hacia donde dice la biblia")
	assert_eq(cycle.sun.light_color, Color(SUN_COLOR))
	assert_almost_eq(cycle.sun.light_energy, SUN_ENERGY, 0.0001)


## Lo que se ve por la ventana y el fondo del diorama cambian con el momento.
func test_the_window_view_and_the_backdrop_follow_the_moment() -> void:
	var cycle: DayCycle = _cycle()
	cycle.backdrop = ShaderMaterial.new()
	var view: ShaderMaterial = WorldPalette.glow("ffffff", WorldPalette.WINDOW_VIEW)
	for hour: float in [8.0, 17.25, 22.0]:
		cycle.set_hour(hour)
		var light: Dictionary = DayCycle.sample(hour)
		assert_eq(view.get_shader_parameter("mood"), light["view_mood"], "Por la ventana a las %.2f" % hour)
		assert_eq(cycle.backdrop.get_shader_parameter("center_color"), light["background_center"], "Fondo a las %.2f" % hour)
		assert_eq(cycle.backdrop.get_shader_parameter("glow_color"), light["background_glow"], "Resplandor a las %.2f" % hour)
		assert_almost_eq(float(WorldPalette.window_shaft().get_shader_parameter("strength")), float(light["window_shaft"]), 0.0001, "Haz a las %.2f" % hour)


## Biblia §6.4: las transiciones siempre mezcladas, nunca de golpe, y al
## cargar una partida la hora se aplica sin mezcla.
func test_the_clock_blends_the_light_and_loading_does_not() -> void:
	var cycle: DayCycle = _cycle()
	var sun: DirectionalLight3D = cycle.sun
	cycle.set_hour(19.25)
	assert_false(cycle.is_blending(), "Al poner la hora, de una vez")
	assert_almost_eq(sun.light_energy, 0.22, 0.0001)
	# Un minuto de juego en medio del paso del atardecer a la noche: la luz
	# no salta, llega de a poco.
	var next: float = 19.5
	cycle.go_to_hour(next)
	assert_true(cycle.is_blending(), "El reloj avanzó: la luz se mezcla")
	assert_almost_eq(sun.light_energy, 0.22, 0.0001, "Nada cambió de golpe")
	cycle.step(DayCycle.BLEND_SECONDS / 2.0)
	assert_almost_eq(cycle.shown_hour(), lerpf(19.25, next, 0.5), 0.0001, "A medio camino")
	assert_between(sun.light_energy, float(DayCycle.sample(next)["sun_energy"]) + 0.0001, 0.22 - 0.0001, "La energía va en camino")
	cycle.step(DayCycle.BLEND_SECONDS)
	assert_false(cycle.is_blending(), "Llegó")
	assert_almost_eq(sun.light_energy, float(DayCycle.sample(next)["sun_energy"]), 0.0001)
	# Un salto grande (de la tarde a la noche) también se mezcla, en el mismo
	# tiempo, y ningún cuadro salta.
	cycle.go_to_hour(23.0)
	var biggest: float = 0.0
	var last: float = sun.light_energy
	for i: int in ceili(DayCycle.BLEND_SECONDS / FRAME) + 1:
		cycle.step(FRAME)
		biggest = maxf(biggest, absf(sun.light_energy - last))
		last = sun.light_energy
	assert_false(cycle.is_blending())
	assert_almost_eq(cycle.shown_hour(), 23.0, 0.0001)
	assert_lt(biggest, 0.01, "Ningún cuadro cambia de golpe la energía del sol")
	# En medio de un momento (la noche) la luz no cambia: nada que mezclar.
	cycle.go_to_hour(23.5)
	assert_false(cycle.is_blending(), "De noche a noche no hay mezcla")
	assert_almost_eq(cycle.shown_hour(), 23.5, 0.0001)
	# Al cargar otra partida (la mañana), de una vez.
	cycle.set_hour(8.0)
	assert_false(cycle.is_blending())
	assert_almost_eq(sun.light_energy, SUN_ENERGY, 0.0001, "La mañana, sin mezcla")
	# Si el reloj vuelve atrás (otra partida que llega por el reloj), también.
	cycle.go_to_hour(30.0)
	cycle.go_to_hour(9.0)
	assert_false(cycle.is_blending(), "El reloj volvió atrás: de una vez")
	assert_almost_eq(cycle.shown_hour(), 9.0, 0.0001)


## Biblia §13: nada de memoria nueva en _process. La mezcla se aplica en
## cada cuadro (RoomView.step) y el reloj llega dentro del cuadro de Game.
func test_blending_the_light_needs_no_new_memory() -> void:
	var cycle: DayCycle = _cycle()
	cycle.backdrop = ShaderMaterial.new()
	var halos: HaloField = HaloField.new()
	var dust: DustField = DustField.new(1)
	add_child_autofree(halos)
	add_child_autofree(dust)
	cycle.halos = halos
	cycle.dust = dust
	cycle.led_strip_on = true
	for light_name: String in DayCycle.LIGHTS:
		cycle.place_light(light_name, Vector3.ONE)
	cycle.set_hour(18.5)
	cycle.go_to_hour(18.6)
	cycle.step(FRAME)
	var before: int = OS.get_static_memory_usage()
	for i: int in 30:
		cycle.step(FRAME)
	cycle.go_to_hour(19.0)
	for i: int in ceili(DayCycle.BLEND_SECONDS / FRAME):
		cycle.step(FRAME)
	assert_eq(OS.get_static_memory_usage() - before, 0, "Mezclar la luz no pide memoria")


func test_every_shader_light_has_a_slot_of_its_own() -> void:
	var slots: Array[int] = []
	for light_name: String in DayCycle.LIGHTS:
		var slot: int = DayCycle.LIGHTS[light_name]["slot"]
		assert_between(slot, 0, DayCycle.LIGHT_GLOBALS.size() - 1, light_name)
		assert_false(slot in slots, "Cada luz en su global: " + light_name)
		slots.append(slot)
		assert_true(light_name in LIGHT_FACTORS, "La mañana dice cuánto alumbra " + light_name)


func test_the_dust_of_the_window_shaft_follows_the_hour() -> void:
	var cycle: DayCycle = DayCycle.new()
	var dust: DustField = DustField.new(1)
	cycle.dust = dust
	add_child_autofree(cycle)
	add_child_autofree(dust)
	assert_false(dust.visible, "Sin hora, escondido")
	cycle.set_hour(8.0)
	assert_true(dust.visible, "De mañana el polvo flota en el haz (factor %.1f)" % LIGHT_FACTORS["window_shaft"])
	assert_almost_eq(float((dust.material_override as ShaderMaterial).get_shader_parameter("strength")), LIGHT_FACTORS["window_shaft"], 0.0001)
	cycle.set_hour(22.0)
	assert_false(dust.visible, "De noche no hay polvo en el haz")


## Un DayCycle con su sol, en el árbol.
func _cycle() -> DayCycle:
	var cycle: DayCycle = DayCycle.new()
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	cycle.sun = sun
	add_child_autofree(cycle)
	add_child_autofree(sun)
	return cycle


## Lo más que cambia de `a` a `b`: (colores, energías y factores; giro en
## grados de las direcciones).
func _difference(a: Dictionary, b: Dictionary) -> Vector2:
	var most: float = 0.0
	var turn: float = 0.0
	for key: String in a:
		var x: Variant = a[key]
		var y: Variant = b[key]
		if key.ends_with("direction"):
			turn = maxf(turn, rad_to_deg((x as Vector3).angle_to(y as Vector3)))
		elif x is Color:
			var d: Color = (x as Color) - (y as Color)
			most = maxf(most, maxf(absf(d.r), maxf(absf(d.g), absf(d.b))))
		elif x is Vector3:
			var v: Vector3 = ((x as Vector3) - (y as Vector3)).abs()
			most = maxf(most, maxf(v.x, maxf(v.y, v.z)))
		elif x is Dictionary:
			for light_name: String in x:
				most = maxf(most, absf(float(x[light_name]) - float(y[light_name])))
		else:
			most = maxf(most, absf(float(x) - float(y)))
	return Vector2(most, turn)


## Luminancia en la pantalla de un punto del piso de color `albedo`, lejos
## de las luces del sombreador y de las paredes, al sol (sin sombra), con la
## cuenta del sombreador: ambiente + relleno (pasada base) + sol (light()).
func _floor_luma(light: Dictionary, albedo: Color) -> float:
	var n: Vector3 = Vector3.UP
	var ambient: Vector3 = light["ambient_sky"]
	var f: float = clampf(n.dot(DayCycle.FILL_DIRECTION.normalized()) * FILL_SPREAD.x + FILL_SPREAD.y, 0.0, 1.0)
	var fill: Vector3 = (light["fill"] as Vector3) * f * f
	var to_sun: Vector3 = -(light["sun_direction"] as Vector3)
	var wrap: float = clampf((n.dot(to_sun) + WRAP) / (1.0 + WRAP), 0.0, 1.0)
	var diffuse: float = smoothstep(0.5 - TERMINATOR, 0.5 + TERMINATOR, wrap)
	var to_camera: Vector3 = -RoomShell.view_direction()
	var edge: float = pow(1.0 - clampf(n.dot(to_camera), 0.0, 1.0), 4.0) * RIM * diffuse
	var sun_color: Color = light["sun_color"]
	var sun: Vector3 = Vector3(sun_color.r, sun_color.g, sun_color.b) * float(light["sun_energy"]) * (diffuse + edge)
	var color: Vector3 = Vector3(albedo.r, albedo.g, albedo.b) * (ambient + fill + sun)
	return color.clampf(0.0, 1.0).dot(LUMA)


func _scaled(hex: String, energy: float) -> Vector3:
	var color: Color = Color(hex)
	return Vector3(color.r, color.g, color.b) * energy


func _assert_color(actual: Color, expected: Color, label: String) -> void:
	assert_true(actual.is_equal_approx(expected), "%s: %s, se esperaba %s" % [label, actual, expected])


func _assert_vec(actual: Vector3, expected: Vector3, label: String) -> void:
	assert_lt(actual.distance_to(expected), 0.0005, "%s: %s, se esperaba %s" % [label, actual, expected])

extends GutTest
## La luz de la mañana (DayCycle, biblia de arte §6.2): los valores que da
## sample() coinciden con la tabla de la biblia y el sol del cuarto los toma.
## La mañana va de las 07:00 a las 10:30 y es la hora del inicio del juego.

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
		var factors: Dictionary = light["lights"]
		for light_name: String in LIGHT_FACTORS:
			assert_almost_eq(float(factors[light_name]), LIGHT_FACTORS[light_name], 0.0001, light_name + " " + label)


func test_sample_is_pure() -> void:
	var first: Dictionary = DayCycle.sample(8.0)
	(first["lights"] as Dictionary)["monitor"] = 5.0
	assert_almost_eq(float((DayCycle.sample(8.0)["lights"] as Dictionary)["monitor"]), 0.12, 0.0001, "Cambiar lo devuelto no cambia la tabla")


func test_the_sun_of_the_room_takes_the_morning() -> void:
	var cycle: DayCycle = DayCycle.new()
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	cycle.sun = sun
	add_child_autofree(cycle)
	add_child_autofree(sun)
	cycle.apply_hour(8.0)
	_assert_vec(-sun.global_basis.z, SUN_DIRECTION.normalized(), "La luz viaja hacia donde dice la biblia")
	assert_eq(sun.light_color, Color(SUN_COLOR))
	assert_almost_eq(sun.light_energy, SUN_ENERGY, 0.0001)


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
	cycle.apply_hour(8.0)
	assert_true(dust.visible, "De mañana el polvo flota en el haz (factor %.1f)" % LIGHT_FACTORS["window_shaft"])
	assert_almost_eq(float((dust.material_override as ShaderMaterial).get_shader_parameter("strength")), LIGHT_FACTORS["window_shaft"], 0.0001)


func _scaled(hex: String, energy: float) -> Vector3:
	var color: Color = Color(hex)
	return Vector3(color.r, color.g, color.b) * energy


func _assert_vec(actual: Vector3, expected: Vector3, label: String) -> void:
	assert_lt(actual.distance_to(expected), 0.0005, "%s: %s, se esperaba %s" % [label, actual, expected])

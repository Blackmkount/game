extends GutTest
## ColorProbe.decide (biblia de arte §2.4): con lo leído en el cuadrito de la
## pasada base (0,25) y en el del sol con sombra (0,5) decide si cada pasada
## se convierte a sRGB. Si algo no se parece a ninguna de las dos opciones,
## quedan los valores medidos en llvmpipe.


func test_llvmpipe_does_not_convert_the_base_pass_but_converts_the_sun() -> void:
	var result: Dictionary = ColorProbe.decide(64.0 / 255.0, 0.68)
	assert_true(result["valid"])
	assert_eq(result["base_fix"], 0)
	assert_eq(result["sun_fix"], 1)
	# Lo que mide hoy (00_calibracion): base 0,251 y sol 0,737.
	assert_eq(ColorProbe.decide(0.251, 0.737), {"valid": true, "base_fix": 0, "sun_fix": 1})


func test_both_passes_converted() -> void:
	var result: Dictionary = ColorProbe.decide(137.0 / 255.0, 0.735)
	assert_eq(result, {"valid": true, "base_fix": 1, "sun_fix": 1})


func test_no_pass_converted() -> void:
	assert_eq(ColorProbe.decide(0.25, 0.5), {"valid": true, "base_fix": 0, "sun_fix": 0})


func test_readings_out_of_range_fall_back_to_llvmpipe() -> void:
	var fallback: Dictionary = {"valid": false, "base_fix": ColorProbe.DEFAULT_BASE_FIX, "sun_fix": ColorProbe.DEFAULT_SUN_FIX}
	assert_eq(ColorProbe.DEFAULT_BASE_FIX, 0)
	assert_eq(ColorProbe.DEFAULT_SUN_FIX, 1)
	for reading: Vector2 in [Vector2(-1.0, -1.0), Vector2(0.0, 0.0), Vector2(1.0, 1.0), Vector2(0.4, 0.735), Vector2(0.25, 0.62), Vector2(0.25, 0.95)]:
		assert_eq(ColorProbe.decide(reading.x, reading.y), fallback, "Fuera de rango: %s" % reading)


func test_the_tolerance_is_six_hundredths() -> void:
	assert_true(ColorProbe.decide(0.25 + 0.059, 0.5)["valid"])
	assert_false(ColorProbe.decide(0.25 + 0.061, 0.5)["valid"])
	assert_true(ColorProbe.decide(0.25, 0.7354 - 0.059)["valid"])
	assert_false(ColorProbe.decide(0.25, 0.7354 - 0.061)["valid"])


func test_without_a_screen_nothing_is_measured() -> void:
	# Las pruebas corren sin pantalla: la escena del cuarto ya pidió medir y
	# quedaron los valores por defecto.
	var host: Node = Node.new()
	add_child_autofree(host)
	ColorProbe.run(host, Viewport.MSAA_4X)
	assert_eq(ColorProbe.status, ColorProbe.Status.NO_SCREEN)
	assert_eq(ColorProbe.base_fix, ColorProbe.DEFAULT_BASE_FIX)
	assert_eq(ColorProbe.sun_fix, ColorProbe.DEFAULT_SUN_FIX)
	assert_eq(get_tree().root.get_node_or_null("ColorProbe"), null, "No arma nada")

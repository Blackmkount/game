extends GutTest
## Materiales del mundo (WorldPalette, biblia de arte §3.6): la caché devuelve
## siempre el mismo material para el mismo pedido (las vistas y las pruebas
## los comparan por identidad), cada uno lleva el color y la superficie
## pedidos, y cada estado de pantalla es un material propio.


func test_the_same_request_gives_the_same_material() -> void:
	assert_same(WorldPalette.kit(), WorldPalette.kit())
	assert_same(WorldPalette.solid("e0453a"), WorldPalette.solid("e0453a"))
	assert_same(WorldPalette.printing("e0453a"), WorldPalette.printing("e0453a"))
	assert_same(WorldPalette.paint("b97a48", WorldPalette.Surface.WOOD, 0.15), WorldPalette.paint("b97a48", WorldPalette.Surface.WOOD, 0.15))
	assert_same(WorldPalette.textured("cardboard"), WorldPalette.textured("cardboard"))
	assert_same(WorldPalette.glow("7fe0a0"), WorldPalette.glow("7fe0a0"))
	assert_same(WorldPalette.glow("ffffff", "crt_screen"), WorldPalette.glow("ffffff", "crt_screen"))
	assert_same(WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, 0.6), WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, 0.6))
	assert_same(WorldPalette.halo(LookPalette.LAMP_HALO), WorldPalette.halo(LookPalette.LAMP_HALO))


func test_different_requests_give_different_materials() -> void:
	assert_ne(WorldPalette.solid("e0453a"), WorldPalette.solid("4cbf5a"))
	assert_ne(WorldPalette.solid("e0453a"), WorldPalette.paint("e0453a"), "Impreso y pintado no son lo mismo")
	assert_ne(WorldPalette.solid("e0453a"), WorldPalette.printing("e0453a"), "La pieza que se imprime tiene su capa caliente")
	assert_ne(WorldPalette.paint("b97a48"), WorldPalette.paint("b97a48", WorldPalette.Surface.WOOD))
	assert_ne(WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, 0.6), WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, 0.8))


func test_solid_is_printed_plastic_of_that_color() -> void:
	for hex: String in ["f2efe6", "e0453a", "3b7fe0", WorldPalette.FAILED_PIECE]:
		var material: ShaderMaterial = WorldPalette.solid(hex)
		assert_eq(material.shader, WorldPalette.TINTED_SHADER)
		assert_eq(material.get_shader_parameter("albedo"), Color(hex), "Lleva el color " + hex)
		assert_eq(material.get_shader_parameter("layer"), PieceModel.LAYER_STEP, "Con las capas de la pieza")
		assert_eq(material.get_shader_parameter("emit"), 0.0)
	var printing: ShaderMaterial = WorldPalette.printing("e0453a")
	assert_eq(printing.shader, WorldPalette.PRINTING_SHADER)
	assert_eq(printing.get_shader_parameter("albedo"), Color("e0453a"))
	assert_eq(printing.get_shader_parameter("layer"), PieceModel.LAYER_STEP)


func test_paint_and_textures_carry_their_color_and_surface() -> void:
	var wood: ShaderMaterial = WorldPalette.paint(WorldPalette.WOOD_MID, WorldPalette.Surface.WOOD, 0.15)
	assert_eq(wood.get_shader_parameter("albedo"), Color(WorldPalette.WOOD_MID))
	assert_eq(wood.get_shader_parameter("surface"), WorldPalette.Surface.WOOD)
	assert_eq(wood.get_shader_parameter("gloss"), 0.15)
	assert_eq(wood.get_shader_parameter("layer"), 0.0, "Lo pintado no tiene capas")
	for texture_name: String in WorldPalette.TEXTURES:
		var look: Array = WorldPalette.TEXTURES[texture_name]
		var material: ShaderMaterial = WorldPalette.textured(texture_name)
		assert_eq(material.shader, WorldPalette.TINTED_SHADER)
		assert_eq(material.get_shader_parameter("albedo"), Color(look[0] as String), texture_name)
		assert_eq(material.get_shader_parameter("surface"), look[1], texture_name)
	assert_eq(WorldPalette.textured("cardboard").get_shader_parameter("surface"), WorldPalette.Surface.CARDBOARD)


func test_a_plain_glow_is_a_lit_kit_color_with_its_own_light() -> void:
	var led: ShaderMaterial = WorldPalette.glow("7fe0a0")
	assert_eq(led.shader, WorldPalette.TINTED_SHADER)
	assert_eq(led.get_shader_parameter("albedo"), Color("7fe0a0"))
	assert_gt(float(led.get_shader_parameter("emit")), 0.0)


func test_each_screen_state_is_its_own_stable_material() -> void:
	var seen: Array[Material] = []
	for state: String in WorldPalette.SCREEN_MODES:
		var screen: ShaderMaterial = WorldPalette.glow("ffffff", state)
		assert_eq(screen.shader, WorldPalette.SCREEN_SHADER, state)
		assert_eq(screen.get_shader_parameter("mode"), WorldPalette.SCREEN_MODES[state], state)
		assert_same(WorldPalette.glow("ffffff", state), screen, "Siempre el mismo: " + state)
		assert_false(screen in seen, "Uno por estado: " + state)
		seen.append(screen)
	assert_eq(seen.size(), 6, "crt_screen, crt_modeling y las 4 pantallitas de la impresora")
	assert_eq(WorldPalette.glow("ffffff", WorldPalette.WINDOW_VIEW).shader, WorldPalette.WINDOW_VIEW_SHADER)


func test_floor_marks_are_see_through_markers() -> void:
	var mark: ShaderMaterial = WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, 0.6)
	assert_eq(mark.shader, WorldPalette.MARKER_SHADER)
	assert_eq(mark.get_shader_parameter("color"), Color(LookPalette.INTERACTION))
	assert_eq(mark.get_shader_parameter("alpha"), 0.6)
	assert_eq(mark.get_shader_parameter("period"), 0.0, "Quieta si no se pide latido")
	var pulsing: ShaderMaterial = WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, 0.6, 0.2, 2.4)
	assert_ne(pulsing, mark, "La que late es otra")
	assert_same(WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, 0.6, 0.2, 2.4), pulsing)
	assert_eq(pulsing.get_shader_parameter("alpha_low"), 0.2)
	assert_eq(pulsing.get_shader_parameter("period"), 2.4)

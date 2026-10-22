extends GutTest
## Los sombreadores del mundo (game/world/look/, biblia de arte §3.1) se
## arman sin errores: cada material del kit se pone sobre una malla en la
## escena y el motor lee su código (sin pantalla también revisa el lenguaje de
## sombreadores: un error hace fallar la prueba). Además cada uno expone sus
## parámetros, así un sombreador roto (sin parámetros) no pasa callado.

## Cada sombreador y parámetros que debe tener.
const SHADERS: Dictionary[String, Array] = {
	"res://game/world/look/kit.gdshader": ["toon", "rim"],
	"res://game/world/look/kit_tinted.gdshader": ["albedo", "surface", "gloss", "layer", "emit"],
	"res://game/world/look/kit_printing.gdshader": ["albedo", "surface", "gloss", "layer", "emit"],
	"res://game/world/look/screen.gdshader": ["mode", "tint"],
	"res://game/world/look/window_view.gdshader": ["mood", "view_dir"],
	"res://game/world/look/window_shaft.gdshader": ["strength"],
	"res://game/world/look/halo.gdshader": ["color", "falloff", "aspect"],
	"res://game/world/look/backdrop.gdshader": ["center_color", "edge_color", "glow_color"],
	"res://game/world/look/base_shadow.gdshader": ["color"],
	"res://game/world/look/marker.gdshader": ["color", "alpha", "alpha_low", "period"],
	"res://game/world/look/color_probe.gdshader": ["base_level", "sun_level"],
}


func test_every_look_shader_compiles_and_exposes_its_parameters() -> void:
	for path: String in SHADERS:
		var shader: Shader = load(path)
		assert_not_null(shader, path)
		var names: Array[String] = []
		for uniform: Dictionary in shader.get_shader_uniform_list():
			names.append(uniform["name"])
		for parameter: String in SHADERS[path]:
			assert_true(parameter in names, "%s tiene %s" % [path.get_file(), parameter])


func test_every_palette_material_can_be_drawn_on_a_mesh() -> void:
	var root: Node3D = Node3D.new()
	add_child_autofree(root)
	var materials: Array[Material] = [
		WorldPalette.kit(), WorldPalette.solid("e0453a"), WorldPalette.printing("e0453a"),
		WorldPalette.paint(WorldPalette.WOOD_MID, WorldPalette.Surface.WOOD, 0.15),
		WorldPalette.glow("7fe0a0"), WorldPalette.glow("ffffff", "crt_modeling"),
		WorldPalette.glow("ffffff", WorldPalette.WINDOW_VIEW), WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, 0.6),
		WorldPalette.halo(LookPalette.LAMP_HALO, 3.0), WorldPalette.window_shaft(),
	]
	for surface: int in WorldPalette.Surface.size():
		materials.append(WorldPalette.paint("cccccc", surface as WorldPalette.Surface))
	for texture_name: String in WorldPalette.TEXTURES:
		materials.append(WorldPalette.textured(texture_name))
	for material: Material in materials:
		var box: MeshInstance3D = PropBuilder.box(root, "Box", Vector3.ONE * 0.2, Vector3.ZERO, material)
		assert_eq(box.material_override, material)
	await wait_process_frames(2)
	assert_eq(root.get_child_count(), materials.size())


func test_the_printing_piece_shows_its_hot_layer_on_top() -> void:
	var root: Node3D = Node3D.new()
	add_child_autofree(root)
	var piece: MeshInstance3D = PieceModel.build(root, "Piece")
	PieceModel.set_shape(piece, "S", "e0453a", 0.06, true)
	assert_eq(piece.material_override, WorldPalette.printing("e0453a"), "Mientras se imprime")
	assert_almost_eq(float(piece.get_instance_shader_parameter(&"hot_top")), 0.03, 0.0001, "Arriba de la pieza (la malla va centrada)")
	PieceModel.set_shape(piece, "S", "e0453a", PieceModel.full_size("S").y)
	assert_eq(piece.material_override, WorldPalette.solid("e0453a"), "Terminada, sin capa caliente")

extends GutTest
## Todos los sombreadores del juego (los del mundo en game/world/look/,
## biblia de arte §3.1, y los de la interfaz) se arman sin errores: cada uno
## se carga de nuevo, sin caché, dentro de la prueba (sin pantalla el motor
## también revisa el lenguaje de sombreadores: un error hace fallar la
## prueba; si se armara antes, por ejemplo al preparar otra prueba, GUT no lo
## contaría) y expone sus parámetros, así un sombreador roto (sin
## parámetros) no pasa callado. Ninguno queda fuera de la lista. Además cada
## material del kit se pone sobre una malla en la escena.

## Dónde se buscan los sombreadores del juego.
const GAME_DIR: String = "res://game"
## Cada sombreador y parámetros que debe tener.
const SHADERS: Dictionary[String, Array] = {
	"res://game/world/look/kit.gdshader": ["toon", "rim"],
	"res://game/world/look/kit_tinted.gdshader": ["albedo", "surface", "gloss", "layer", "emit"],
	"res://game/world/look/kit_printing.gdshader": ["albedo", "surface", "gloss", "layer", "emit", "hot_layer"],
	"res://game/world/look/kit_glass.gdshader": ["albedo", "surface", "gloss", "layer", "emit", "alpha"],
	"res://game/world/look/kit_reveal.gdshader": ["toon", "rim", "reveal_cut", "reveal_preview"],
	"res://game/world/look/kit_reveal_tinted.gdshader": ["albedo", "surface", "gloss", "layer", "emit", "reveal_cut", "reveal_preview"],
	"res://game/world/look/screen.gdshader": ["mode", "tint"],
	"res://game/world/look/window_view.gdshader": ["mood", "view_dir"],
	"res://game/world/look/window_shaft.gdshader": ["strength"],
	"res://game/world/look/dust.gdshader": ["strength", "size", "brightness", "reach", "drift"],
	"res://game/world/look/halo.gdshader": ["color", "falloff", "aspect"],
	"res://game/world/look/halo_field.gdshader": ["falloff", "intensity"],
	"res://game/world/look/backdrop.gdshader": ["center_color", "edge_color", "glow_color"],
	"res://game/world/look/base_shadow.gdshader": ["color"],
	"res://game/world/look/marker.gdshader": ["color", "alpha", "alpha_low", "period"],
	"res://game/world/look/color_probe.gdshader": ["base_level", "sun_level"],
	"res://game/world/look/kit_character.gdshader": ["toon", "rim", "studio_sky", "studio_ground", "studio_key", "studio_fill", "studio_rim"],
	"res://game/world/look/kit_head.gdshader": ["toon", "rim", "studio_key", "face_atlas", "face_cells", "face_axis", "face_span", "face_height", "eye_ink"],
	"res://game/world/look/outline_character.gdshader": ["ink", "hair_ink"],
	"res://game/world/look/display_field.gdshader": [],
	"res://game/ui/components/preview_premultiplied.gdshader": [],
}


func test_every_look_shader_compiles_and_exposes_its_parameters() -> void:
	for path: String in SHADERS:
		var shader: Shader = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		assert_not_null(shader, path)
		var names: Array[String] = []
		for uniform: Dictionary in shader.get_shader_uniform_list():
			names.append(uniform["name"])
		for parameter: String in SHADERS[path]:
			assert_true(parameter in names, "%s tiene %s" % [path.get_file(), parameter])


func test_every_game_shader_is_in_the_list() -> void:
	var missing: Array[String] = []
	for path: String in _shaders_in(GAME_DIR):
		if not SHADERS.has(path):
			missing.append(path)
	assert_eq(missing, [] as Array[String], "Sombreadores sin revisar")


func test_every_palette_material_can_be_drawn_on_a_mesh() -> void:
	var root: Node3D = Node3D.new()
	add_child_autofree(root)
	var materials: Array[Material] = [
		WorldPalette.kit(), WorldPalette.solid("e0453a"), WorldPalette.printing("e0453a"),
		WorldPalette.paint(WorldPalette.WOOD_MID, WorldPalette.Surface.WOOD, 0.15),
		WorldPalette.glow("7fe0a0"), WorldPalette.glow("ffffff", "crt_modeling"),
		WorldPalette.glow("ffffff", WorldPalette.WINDOW_VIEW), WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, 0.6),
		WorldPalette.halo(LookPalette.LAMP_HALO, 3.0), WorldPalette.window_shaft(),
		WorldPalette.kit_character(), WorldPalette.kit_head(), WorldPalette.outline_character(),
		WorldPalette.reveal_of(WorldPalette.kit()), WorldPalette.reveal_of(WorldPalette.solid("e0453a")),
	]
	for surface: int in WorldPalette.Surface.size():
		materials.append(WorldPalette.paint("cccccc", surface as WorldPalette.Surface))
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


## Los .gdshader de `dir_path` y sus carpetas.
func _shaders_in(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	for sub_dir: String in DirAccess.get_directories_at(dir_path):
		found.append_array(_shaders_in(dir_path.path_join(sub_dir)))
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.get_extension() == "gdshader":
			found.append(dir_path.path_join(file_name))
	return found

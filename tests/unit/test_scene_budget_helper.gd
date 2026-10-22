extends GutTest
## Las reglas con las que tests/helpers/scene_budget.gd cuenta lo que cuesta
## dibujar, con árboles armados a mano (sin pantalla). La prueba de
## presupuesto del juego (tests/integration/test_scene_budget.gd) confía en
## estas cuentas.

const SceneBudget: GDScript = preload("res://tests/helpers/scene_budget.gd")
## Una caja de BoxMesh sin subdivisiones: 6 caras de 2 triángulos.
const BOX_TRIANGLES: int = 12
const INCLUDE_PATH: String = "user://scene_budget_test.gdshaderinc"


func test_each_pass_draws_once_in_color_and_once_in_the_shadow_map() -> void:
	var root: Node3D = _root_with_sun(DirectionalLight3D.SHADOW_ORTHOGONAL)
	var outline: StandardMaterial3D = StandardMaterial3D.new()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.next_pass = outline
	_box(root, "Box", material)
	var budget: RefCounted = SceneBudget.measure(root)
	assert_eq(budget.get("draw_calls"), 4, "2 pasadas de color y 2 de sombra")
	assert_eq(budget.get("shadow_draw_calls"), 2)
	assert_eq(budget.get("triangles"), BOX_TRIANGLES)
	assert_eq(budget.get("visible_triangles"), BOX_TRIANGLES * 2)
	assert_eq(budget.call("total_triangles"), BOX_TRIANGLES * 4)
	assert_eq((budget.get("materials") as Dictionary).size(), 2)
	assert_eq(budget.get("shadow_meshes"), 1)
	assert_eq((budget.get("lights") as Dictionary).size(), 1)
	assert_eq((budget.get("lights") as Dictionary).get("DirectionalLight3D", 0), 1)
	assert_eq(budget.get("shadowed_lights"), 1)
	root.free()


func test_transparent_and_shadowless_meshes_skip_the_shadow_map() -> void:
	var root: Node3D = _root_with_sun(DirectionalLight3D.SHADOW_ORTHOGONAL)
	var glass: StandardMaterial3D = StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_box(root, "Glass", glass)
	var flat: MeshInstance3D = _box(root, "Flat", StandardMaterial3D.new())
	flat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var budget: RefCounted = SceneBudget.measure(root)
	assert_eq(budget.get("draw_calls"), 2, "Una llamada cada una, sin sombra")
	assert_eq(budget.get("transparent_surfaces"), 1)
	assert_eq(budget.get("shadow_meshes"), 0)
	root.free()


func test_shadow_only_meshes_draw_only_in_the_shadow_map() -> void:
	var root: Node3D = _root_with_sun(DirectionalLight3D.SHADOW_ORTHOGONAL)
	var caster: MeshInstance3D = _box(root, "Caster", StandardMaterial3D.new())
	caster.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	var budget: RefCounted = SceneBudget.measure(root)
	assert_eq(budget.get("draw_calls"), 1)
	assert_eq(budget.get("visible_triangles"), 0)
	assert_eq(budget.get("shadow_triangles"), BOX_TRIANGLES)
	root.free()


func test_hidden_branches_do_not_count_and_without_a_shadowed_light_nothing_casts() -> void:
	var root: Node3D = Node3D.new()
	var hidden: Node3D = Node3D.new()
	hidden.visible = false
	root.add_child(hidden)
	_box(hidden, "Hidden", StandardMaterial3D.new())
	_box(root, "Shown", StandardMaterial3D.new())
	var budget: RefCounted = SceneBudget.measure(root)
	assert_eq(budget.get("mesh_instances"), 1)
	assert_eq(budget.get("draw_calls"), 1, "Sin luz con sombra no hay pasada de sombra")
	assert_eq(budget.get("shadow_meshes"), 0)
	assert_true((budget.get("lights") as Dictionary).is_empty())
	root.free()


func test_a_multimesh_is_one_call_for_all_its_copies() -> void:
	var root: Node3D = _root_with_sun(DirectionalLight3D.SHADOW_ORTHOGONAL)
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = BoxMesh.new()
	multimesh.instance_count = 10
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	root.add_child(instance)
	var budget: RefCounted = SceneBudget.measure(root)
	assert_eq(budget.get("multimeshes"), 1)
	assert_eq(budget.get("draw_calls"), 2, "Una de color y una de sombra")
	assert_eq(budget.get("triangles"), BOX_TRIANGLES * 10)
	root.free()


func test_each_shadow_split_draws_the_casters_again() -> void:
	var root: Node3D = _root_with_sun(DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS)
	_box(root, "Box", StandardMaterial3D.new())
	var budget: RefCounted = SceneBudget.measure(root)
	assert_eq(budget.get("shadow_passes"), 4)
	assert_eq(budget.get("draw_calls"), 5)
	root.free()


func test_shader_materials_are_classified_like_godot_does() -> void:
	assert_false(SceneBudget.is_transparent(_shader_material("void fragment() { ALBEDO = vec3(1.0); }")))
	var alpha: ShaderMaterial = _shader_material("void fragment() { ALBEDO = vec3(1.0); ALPHA = 0.5; }")
	assert_true(SceneBudget.is_transparent(alpha), "Escribir ALPHA lo vuelve transparente")
	assert_false(SceneBudget.casts_shadow(alpha))
	var clipped: ShaderMaterial = _shader_material("void fragment() { ALPHA = 0.5; ALPHA_SCISSOR_THRESHOLD = 0.4; }")
	assert_false(SceneBudget.is_transparent(clipped), "Con recorte sigue siendo opaco")
	var added: ShaderMaterial = _shader_material("render_mode blend_add;\nvoid fragment() { ALBEDO = vec3(1.0); }")
	assert_true(SceneBudget.is_transparent(added))
	assert_false(SceneBudget.casts_shadow(added))
	var prepass: ShaderMaterial = _shader_material("render_mode depth_prepass_alpha;\nvoid fragment() { ALPHA = 0.5; }")
	assert_true(SceneBudget.is_transparent(prepass))
	assert_true(SceneBudget.casts_shadow(prepass), "Con la pasada previa de profundidad da sombra")


func test_shader_includes_are_read_too() -> void:
	var file: FileAccess = FileAccess.open(INCLUDE_PATH, FileAccess.WRITE)
	file.store_string("void set_alpha(inout float alpha) { alpha = 0.5; }\n#define FADE ALPHA = 0.5\n")
	file.close()
	var code: String = SceneBudget.call("_expanded", "#include \"scene_budget_test.gdshaderinc\"\nvoid fragment() { FADE; }", "user://", 0)
	assert_string_contains(code, "ALPHA = 0.5")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(INCLUDE_PATH))


func test_drawables_it_cannot_measure_are_reported() -> void:
	var root: Node3D = Node3D.new()
	var label: Label3D = Label3D.new()
	label.name = "Sign"
	root.add_child(label)
	var budget: RefCounted = SceneBudget.measure(root)
	assert_eq((budget.get("unmeasured") as Array).size(), 1)
	assert_string_contains(String(budget.call("report")), "Sign (Label3D)")
	root.free()


func test_the_breakdown_adds_each_child_with_its_shadows() -> void:
	var root: Node3D = _root_with_sun(DirectionalLight3D.SHADOW_ORTHOGONAL)
	var group: Node3D = Node3D.new()
	group.name = "Printer"
	root.add_child(group)
	_box(group, "Body", StandardMaterial3D.new())
	_box(group, "Head", StandardMaterial3D.new())
	_box(root, "Lamp", StandardMaterial3D.new())
	var budget: RefCounted = SceneBudget.measure(root)
	assert_eq(budget.call("child_draw_calls", "Printer"), 4)
	assert_eq(budget.call("child_triangles", "Printer"), BOX_TRIANGLES * 4)
	assert_eq(budget.call("child_draw_calls", "Lamp"), 2)
	var lines: PackedStringArray = String(budget.call("report")).split("\n")
	assert_string_contains(lines[1], "Printer: 4 llamadas", "El más caro va primero")
	root.free()


func _root_with_sun(mode: DirectionalLight3D.ShadowMode) -> Node3D:
	var root: Node3D = Node3D.new()
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = mode
	root.add_child(sun)
	return root


func _box(parent: Node3D, node_name: String, material: Material) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = BoxMesh.new()
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _shader_material(body: String) -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = "shader_type spatial;\n" + body
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	return material

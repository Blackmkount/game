extends RefCounted
## Mide lo que cuesta dibujar un árbol 3D sin pantalla (sirve en modo
## headless, en las pruebas de CI): mallas visibles, triángulos de la pasada
## de color y de la pasada de sombra, materiales distintos, mallas que dan
## sombra, superficies transparentes, luces y una estimación de las llamadas
## de dibujo del renderizador Compatibility.
##
## Reglas (las mismas del renderizador):
## - Cada superficie visible es una llamada por material de su cadena
##   (el material y cada next_pass).
## - Las pasadas opacas de una malla que da sombra se dibujan otra vez en el
##   mapa de sombras, una vez por cada corte de la luz con sombra (el sol con
##   SHADOW_ORTHOGONAL tiene un solo corte). Las transparentes no dan sombra.
## - Un MultiMesh es una sola llamada por pasada para todas sus copias.
## - Lo que está escondido (un Node3D con visible = false) no cuenta.
## - Lo que no sabe contar queda en `unmeasured` (y la prueba falla): otros
##   nodos que dibujan (Label3D, Sprite3D, partículas, CSG), material_overlay,
##   transparency > 0 en una malla y un SubViewport dentro del árbol (dibuja
##   otro mundo aparte).
##
## Calibrado contra los contadores reales de OpenGL (Viewport.get_render_info
## con xvfb + llvmpipe): tools/screenshots.sh deja los dos números en
## budget.csv, y con todo dentro de la vista dan lo mismo. No mira qué entra
## en la cámara: cuenta todo.
##
## Sin class_name: las pruebas lo cargan con preload.

## Cuánto de lo medido viene de un hijo de la raíz.
class Share:
	extends RefCounted
	var color_calls: int = 0
	var color_triangles: int = 0
	var casting_calls: int = 0
	var casting_triangles: int = 0

const SCRIPT_PATH: String = "res://tests/helpers/scene_budget.gd"
const MAX_INCLUDE_DEPTH: int = 8
## Modos de mezcla que mandan una superficie a la pasada transparente.
const BLEND_MODES: Array[String] = ["blend_add", "blend_sub", "blend_mul", "blend_premul_alpha"]

## Por sombreador (Shader → [transparente, da sombra]): leer el código cuesta.
static var _shader_cache: Dictionary[Shader, Array] = {}

var mesh_instances: int = 0
var multimeshes: int = 0
## Superficies visibles (una malla puede tener varias).
var surfaces: int = 0
## Triángulos de la geometría visible, contados una sola vez.
var triangles: int = 0
## Triángulos dibujados en la pasada de color (cada next_pass dibuja otra vez).
var visible_triangles: int = 0
## Triángulos dibujados en las pasadas de sombra.
var shadow_triangles: int = 0
## Llamadas de dibujo estimadas: pasada de color más pasadas de sombra.
var draw_calls: int = 0
var shadow_draw_calls: int = 0
## Mallas (MeshInstance3D o MultiMeshInstance3D) que dan sombra.
var shadow_meshes: int = 0
## Superficies con alguna pasada transparente.
var transparent_surfaces: int = 0
## Materiales distintos (cada uno cambia el estado del renderizador).
var materials: Dictionary[Material, bool] = {}
## Luces visibles por clase ("DirectionalLight3D": 1...).
var lights: Dictionary[String, int] = {}
var shadowed_lights: int = 0
## Veces que se dibuja el mapa de sombras (suma de cortes de las luces).
var shadow_passes: int = 0
## Nodos visibles que dibujan algo que esta medida no sabe contar (Label3D,
## Sprite3D, partículas, material_overlay, transparency, un SubViewport...).
## Si aparece uno, hay que enseñarle.
var unmeasured: Array[String] = []
## Lo medido por hijo directo de la raíz (nombre → Share).
var by_child: Dictionary[String, Share] = {}

var _casting_calls: int = 0
var _casting_triangles: int = 0
var _casting_meshes: int = 0


static func measure(root: Node) -> RefCounted:
	var budget: RefCounted = (load(SCRIPT_PATH) as GDScript).new()
	budget.call("_walk", root, root)
	budget.call("_finish")
	return budget


## Triángulos con la pasada de color y la de sombra juntas.
func total_triangles() -> int:
	return visible_triangles + shadow_triangles


## Llamadas de dibujo de un hijo de la raíz, con sus sombras.
func child_draw_calls(child_name: String) -> int:
	var share: Share = by_child.get(child_name)
	return share.color_calls + share.casting_calls * shadow_passes if share != null else 0


## Triángulos de un hijo de la raíz, con sus sombras.
func child_triangles(child_name: String) -> int:
	var share: Share = by_child.get(child_name)
	return share.color_triangles + share.casting_triangles * shadow_passes if share != null else 0


## Una línea con el total y, debajo, una línea por hijo de la raíz, del que
## más llamadas usa al que menos.
func report() -> String:
	var lines: PackedStringArray = []
	lines.append("llamadas ≈ %d (sombra %d) · triángulos %d en color, %d con la sombra (geometría %d) · mallas %d · MultiMesh %d · superficies %d · materiales %d · mallas con sombra %d · transparentes %d · luces %s (con sombra %d)" % [
		draw_calls, shadow_draw_calls, visible_triangles, total_triangles(), triangles, mesh_instances, multimeshes,
		surfaces, materials.size(), shadow_meshes, transparent_surfaces, lights, shadowed_lights])
	var names: Array[String] = []
	names.assign(by_child.keys())
	names.sort_custom(_heavier)
	for child_name: String in names:
		lines.append("  %s: %d llamadas, %d triángulos" % [child_name, child_draw_calls(child_name), child_triangles(child_name)])
	if not unmeasured.is_empty():
		lines.append("  sin medir: %s" % ", ".join(unmeasured))
	return "\n".join(lines)


## Si un material se dibuja en la pasada transparente (null: el material por
## defecto, opaco).
static func is_transparent(material: Material) -> bool:
	if material is BaseMaterial3D:
		return _base_is_transparent(material)
	if material is ShaderMaterial and (material as ShaderMaterial).shader != null:
		return bool(_shader_traits((material as ShaderMaterial).shader)[0])
	return false


## Si un material se dibuja en el mapa de sombras: las pasadas opacas sí, las
## transparentes no, salvo las que tienen su pasada previa de profundidad.
static func casts_shadow(material: Material) -> bool:
	if material is BaseMaterial3D:
		var base: BaseMaterial3D = material
		return not _base_is_transparent(base) or (base.blend_mode == BaseMaterial3D.BLEND_MODE_MIX \
			and base.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS)
	if material is ShaderMaterial and (material as ShaderMaterial).shader != null:
		return bool(_shader_traits((material as ShaderMaterial).shader)[1])
	return true


## Lo que hace que Godot dibuje un BaseMaterial3D en la pasada transparente:
## mezcla distinta de "mix", ALPHA (con o sin pasada previa de profundidad),
## refracción (lee la pantalla), desvanecer cerca de otra superficie (lee la
## profundidad) o desvanecer con la distancia por píxel. Recorte (scissor),
## hash y el desvanecer con tramado siguen siendo opacos.
static func _base_is_transparent(base: BaseMaterial3D) -> bool:
	return base.blend_mode != BaseMaterial3D.BLEND_MODE_MIX \
		or base.transparency in [BaseMaterial3D.TRANSPARENCY_ALPHA, BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS] \
		or base.refraction_enabled or base.proximity_fade_enabled \
		or base.distance_fade_mode == BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA


func _walk(root: Node, node: Node) -> void:
	if node is Node3D and not (node as Node3D).visible:
		return
	if node is Viewport and node != root:
		_report_unmeasured(root, node, "viewport anidado")
		return
	if node is GeometryInstance3D:
		var geometry: GeometryInstance3D = node
		if geometry.material_overlay != null:
			_report_unmeasured(root, node, "material_overlay")
		if geometry.transparency > 0.0:
			_report_unmeasured(root, node, "transparency")
	if node is Light3D:
		_add_light(node)
	elif node is MeshInstance3D:
		var instance: MeshInstance3D = node
		if instance.mesh != null:
			mesh_instances += 1
			var materials_by_surface: Array[Material] = []
			for surface: int in instance.mesh.get_surface_count():
				materials_by_surface.append(_material_of(instance, surface))
			_add_geometry(root, instance, instance.mesh, materials_by_surface, 1)
	elif node is MultiMeshInstance3D:
		var multi: MultiMeshInstance3D = node
		var multimesh: MultiMesh = multi.multimesh
		if multimesh != null and multimesh.mesh != null:
			multimeshes += 1
			var count: int = multimesh.visible_instance_count if multimesh.visible_instance_count >= 0 else multimesh.instance_count
			var materials_by_surface: Array[Material] = []
			for surface: int in multimesh.mesh.get_surface_count():
				materials_by_surface.append(multi.material_override if multi.material_override != null else multimesh.mesh.surface_get_material(surface))
			_add_geometry(root, multi, multimesh.mesh, materials_by_surface, count)
	elif node is GeometryInstance3D:
		unmeasured.append("%s (%s)" % [root.get_path_to(node), node.get_class()])
	for child: Node in node.get_children():
		_walk(root, child)


func _report_unmeasured(root: Node, node: Node, what: String) -> void:
	unmeasured.append("%s (%s: %s)" % [root.get_path_to(node), node.get_class(), what])


func _add_light(light: Light3D) -> void:
	lights[light.get_class()] = lights.get(light.get_class(), 0) + 1
	if light.shadow_enabled:
		shadowed_lights += 1
		shadow_passes += _shadow_splits(light)


## Suma las superficies de una malla (o de un MultiMesh con `copies` copias,
## que se dibujan en una sola llamada).
func _add_geometry(root: Node, instance: GeometryInstance3D, mesh: Mesh, materials_by_surface: Array[Material], copies: int) -> void:
	var setting: GeometryInstance3D.ShadowCastingSetting = instance.cast_shadow
	var drawn: bool = setting != GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	var casts: bool = setting != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var share: Share = _share_for(root, instance)
	var cast_any: bool = false
	for surface: int in materials_by_surface.size():
		var tris: int = _triangles(mesh, surface) * copies
		surfaces += 1
		triangles += tris
		var any_transparent: bool = false
		for pass_material: Material in _chain(materials_by_surface[surface]):
			if pass_material != null:
				materials[pass_material] = true
			if drawn:
				any_transparent = any_transparent or is_transparent(pass_material)
				visible_triangles += tris
				draw_calls += 1
				share.color_calls += 1
				share.color_triangles += tris
			if casts and casts_shadow(pass_material):
				cast_any = true
				_casting_calls += 1
				_casting_triangles += tris
				share.casting_calls += 1
				share.casting_triangles += tris
		if any_transparent:
			transparent_surfaces += 1
	if cast_any:
		_casting_meshes += 1


func _finish() -> void:
	shadow_draw_calls = _casting_calls * shadow_passes
	shadow_triangles = _casting_triangles * shadow_passes
	draw_calls += shadow_draw_calls
	shadow_meshes = _casting_meshes if shadow_passes > 0 else 0


## El material y sus next_pass. Sin material, Godot dibuja con el suyo por
## defecto: una pasada opaca (null).
static func _chain(material: Material) -> Array[Material]:
	var passes: Array[Material] = []
	var current: Material = material
	while current != null and current not in passes:
		passes.append(current)
		current = current.next_pass
	if passes.is_empty():
		passes.append(null)
	return passes


static func _material_of(instance: MeshInstance3D, surface: int) -> Material:
	if instance.material_override != null:
		return instance.material_override
	if instance.get_surface_override_material(surface) != null:
		return instance.get_surface_override_material(surface)
	return instance.mesh.surface_get_material(surface)


## Veces que una luz con sombra dibuja su mapa de sombras.
static func _shadow_splits(light: Light3D) -> int:
	if light is DirectionalLight3D:
		match (light as DirectionalLight3D).directional_shadow_mode:
			DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS:
				return 2
			DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS:
				return 4
		return 1
	if light is OmniLight3D:
		return 6 if (light as OmniLight3D).omni_shadow_mode == OmniLight3D.SHADOW_CUBE else 2
	return 1


## [transparente, da sombra] de un sombreador, leyendo su código (con los
## #include) como lo decide Godot: escribir ALPHA sin recorte, un modo de
## mezcla distinto de "mix" o leer la pantalla o la profundidad lo mandan a
## la pasada transparente; con depth_prepass_alpha igual da sombra.
static func _shader_traits(shader: Shader) -> Array:
	if _shader_cache.has(shader):
		return _shader_cache[shader]
	var code: String = _expanded(shader.code, shader.resource_path.get_base_dir(), 0)
	var modes: String = ""
	for mode_match: RegExMatch in RegEx.create_from_string("render_mode\\s+([^;]*);").search_all(code):
		modes += mode_match.get_string(1) + ","
	var blends: bool = false
	for blend: String in BLEND_MODES:
		blends = blends or modes.contains(blend)
	var writes_alpha: bool = RegEx.create_from_string("\\bALPHA\\s*[-+*/]?=(?!=)").search(code) != null
	var clipped: bool = code.contains("ALPHA_SCISSOR_THRESHOLD") or code.contains("ALPHA_HASH_SCALE")
	var reads_screen: bool = code.contains("hint_screen_texture") or code.contains("hint_depth_texture")
	var prepass: bool = modes.contains("depth_prepass_alpha")
	var transparent: bool = blends or reads_screen or prepass or (writes_alpha and not clipped)
	var traits: Array = [transparent, not transparent or (prepass and not blends)]
	_shader_cache[shader] = traits
	return traits


## El código con cada #include "ruta" reemplazado por el del archivo.
static func _expanded(code: String, base_dir: String, depth: int) -> String:
	if depth >= MAX_INCLUDE_DEPTH:
		return code
	var result: String = code
	for found: RegExMatch in RegEx.create_from_string("#include\\s+\"([^\"]+)\"").search_all(code):
		var path: String = found.get_string(1)
		if not path.begins_with("res://"):
			path = base_dir.path_join(path)
		var included: ShaderInclude = load(path) as ShaderInclude
		var text: String = _expanded(included.code, path.get_base_dir(), depth + 1) if included != null else ""
		result = result.replace(found.get_string(0), text)
	return result


## Triángulos de una superficie. Funciona sin pantalla: las PrimitiveMesh
## arman sus arreglos en la CPU y las ArrayMesh guardan sus largos.
static func _triangles(mesh: Mesh, surface: int) -> int:
	if mesh is PrimitiveMesh:
		var arrays: Array = (mesh as PrimitiveMesh).get_mesh_arrays()
		var indices: Variant = arrays[Mesh.ARRAY_INDEX]
		if indices != null and (indices as PackedInt32Array).size() > 0:
			return (indices as PackedInt32Array).size() / 3
		return (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	if mesh is ArrayMesh:
		var array_mesh: ArrayMesh = mesh
		var index_len: int = array_mesh.surface_get_array_index_len(surface)
		return (index_len if index_len > 0 else array_mesh.surface_get_array_len(surface)) / 3
	return mesh.get_faces().size() / 3


func _share_for(root: Node, node: Node) -> Share:
	var current: Node = node
	while current != root and current.get_parent() != root:
		current = current.get_parent()
	var key: String = "." if current == root else String(current.name)
	if not by_child.has(key):
		by_child[key] = Share.new()
	return by_child[key]


func _heavier(a: String, b: String) -> bool:
	var calls_a: int = child_draw_calls(a)
	var calls_b: int = child_draw_calls(b)
	return calls_a > calls_b or (calls_a == calls_b and a < b)

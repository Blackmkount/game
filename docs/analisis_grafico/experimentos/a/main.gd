extends Control
## Escena mínima para probar postprocesos en el renderizador Compatibility.
## Uso: godot --path . -- --mode=<modo> [--bench]

const OUTLINE_SHADER: Shader = preload("res://shaders/outline.gdshader")
const DEPTH_OUTLINE_SHADER: Shader = preload("res://shaders/depth_outline.gdshader")
const DEPTH_NORMALS_SHADER: Shader = preload("res://shaders/depth_outline_normals.gdshader")
const NORMAL_ROUGHNESS_SHADER: Shader = preload("res://shaders/normal_roughness_test.gdshader")
const PASSTHROUGH_SHADER: Shader = preload("res://shaders/screen_passthrough.gdshader")
const DITHER_SCREEN_SHADER: Shader = preload("res://shaders/dither_screen.gdshader")
const DITHER_CANVAS_SHADER: Shader = preload("res://shaders/dither_canvas.gdshader")

const CAMERA_SIZE: float = 3.6
const BENCH_FRAMES: int = 240

## Paleta de 32 colores sacada de docs/ESTILO.md más algunas luces y sombras.
const PALETTE_HEX: PackedStringArray = [
	"1a1320", "141b2d", "2c2532", "463c4c", "52475a", "6a3f22", "6e4426", "9c643c",
	"a86d43", "b3764a", "c98b4f", "e0a868", "2b2f3a", "4a5163", "7a8296", "23242b",
	"b3a585", "d8ccb0", "f3ead2", "1f3d73", "3a7bd5", "7fb2f0", "2e7a3a", "4cbf5a",
	"5c3a8a", "9b5de5", "38d6ff", "e5484d", "f5b82e", "f1c9a5", "fff1dc", "8a5530",
]

var _mode: String = "baseline"
var _bench: bool = false
var _crease_threshold: float = -1.0
var _container: SubViewportContainer
var _viewport: SubViewport
var _world: Node3D
var _environment: Environment
var _frame: int = 0
var _bench_start_usec: int = 0
var _cpu_total: float = 0.0
var _gpu_total: float = 0.0


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
		elif arg == "--bench":
			_bench = true
		elif arg.begins_with("--crease="):
			_crease_threshold = float(arg.trim_prefix("--crease="))
	_build_viewport()
	_build_environment()
	_build_camera()
	_build_props()
	_apply_mode()
	if OS.get_cmdline_user_args().has("--glow"):
		_enable_glow(0.0)
	RenderingServer.viewport_set_measure_render_time(_viewport.get_viewport_rid(), true)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 3:
		print("MODE=%s renderer=%s subviewport=%s" % [
			_mode, RenderingServer.get_current_rendering_method(), _viewport.size])
	if not _bench:
		return
	if _frame == 30:
		_bench_start_usec = Time.get_ticks_usec()
	elif _frame > 30:
		var rid: RID = _viewport.get_viewport_rid()
		_cpu_total += RenderingServer.viewport_get_measured_render_time_cpu(rid)
		_gpu_total += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	if _frame == 30 + BENCH_FRAMES:
		var wall_ms: float = float(Time.get_ticks_usec() - _bench_start_usec) / 1000.0 / BENCH_FRAMES
		print("BENCH mode=%s frame_ms=%.2f subviewport_cpu_ms=%.3f subviewport_gpu_ms=%.3f" % [
			_mode, wall_ms, _cpu_total / BENCH_FRAMES, _gpu_total / BENCH_FRAMES])
		get_tree().quit()


func _build_viewport() -> void:
	_container = SubViewportContainer.new()
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container.stretch = true
	_container.stretch_shrink = 2
	_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_container)
	_viewport = SubViewport.new()
	_viewport.msaa_3d = Viewport.MSAA_DISABLED
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_container.add_child(_viewport)
	_world = Node3D.new()
	if OS.get_cmdline_user_args().has("--direct"):
		# Sin SubViewport: el mundo se dibuja en la ventana principal.
		_container.visible = false
		add_child(_world)
	else:
		_viewport.add_child(_world)


func _build_environment() -> void:
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_COLOR
	_environment.background_color = Color("141b2d")
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has("--bg=clear"):
		_environment.background_mode = Environment.BG_CLEAR_COLOR
		RenderingServer.set_default_clear_color(Color("141b2d"))
	elif args.has("--bg=energy"):
		_environment.background_energy_multiplier = 0.25
	elif args.has("--bg=transparent"):
		_environment.background_mode = Environment.BG_CLEAR_COLOR
		_viewport.transparent_bg = true
		var back: ColorRect = ColorRect.new()
		back.color = Color("141b2d")
		back.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(back)
		move_child(back, 0)
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.ambient_light_color = Color("ffe6c7")
	_environment.ambient_light_energy = 0.5
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = _environment
	_world.add_child(world_environment)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -60.0, 0.0)
	sun.light_color = Color("fff1dc")
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 30.0
	_world.add_child(sun)


func _build_camera() -> void:
	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = CAMERA_SIZE
	camera.near = 0.1
	camera.far = 60.0
	camera.rotation_degrees = Vector3(-30.0, 45.0, 0.0)
	camera.position = Vector3(0.0, 0.35, -0.2) - camera.basis * Vector3.FORWARD * 20.0
	camera.current = true
	_world.add_child(camera)


func _build_props() -> void:
	var with_hull: bool = _mode in ["baseline", "passthrough", "dither", "dither_canvas", "glow", "glow_bloom", "normal_roughness"]
	# Piso con textura de tablas y una pared al fondo.
	_add_box(Vector3(3.0, 0.1, 3.0), Vector3(0.0, -0.05, 0.0), _floor_material(), false)
	_add_box(Vector3(3.0, 1.6, 0.12), Vector3(0.0, 0.8, -1.56), _toon("52475a"), false)
	_add_box(Vector3(0.12, 1.6, 3.0), Vector3(-1.56, 0.8, 0.0), _toon("463c4c"), false)
	# Dos cajas, una esfera y una mesita de patas finas.
	_add_box(Vector3(0.7, 0.7, 0.7), Vector3(-0.6, 0.35, -0.5), _toon("d8ccb0"), with_hull)
	_add_box(Vector3(0.45, 0.5, 0.45), Vector3(0.65, 0.25, 0.1), _toon("3a7bd5"), with_hull)
	_add_sphere(0.3, Vector3(0.0, 0.3, 0.75), _toon("9b5de5"), with_hull)
	_add_box(Vector3(0.7, 0.05, 0.45), Vector3(0.55, 0.6, -0.9), _toon("c98b4f"), with_hull)
	for leg: Vector3 in [Vector3(0.24, 0.0, -0.75), Vector3(0.86, 0.0, -0.75), Vector3(0.24, 0.0, -1.05), Vector3(0.86, 0.0, -1.05)]:
		_add_box(Vector3(0.05, 0.58, 0.05), leg + Vector3(0.0, 0.29, 0.0), _toon("6e4426"), with_hull)
	# Luces que brillan solas (LED y pantalla) con distinta intensidad.
	_add_box(Vector3(0.3, 0.2, 0.02), Vector3(0.55, 0.75, -0.95), _emissive("38d6ff", 1.0), false)
	_add_box(Vector3(0.06, 0.06, 0.06), Vector3(0.65, 0.53, 0.35), _emissive("4cbf5a", 2.0), false)
	_add_box(Vector3(0.06, 0.06, 0.06), Vector3(0.75, 0.53, 0.35), _emissive("e5484d", 4.0), false)
	_add_box(Vector3(0.06, 0.06, 0.06), Vector3(0.85, 0.53, 0.35), _emissive("f5b82e", 8.0), false)


func _apply_mode() -> void:
	match _mode:
		"baseline", "plain":
			pass
		"depth_outline":
			var material: ShaderMaterial = _add_fullscreen(DEPTH_OUTLINE_SHADER, 100)
			if _crease_threshold > 0.0:
				material.set_shader_parameter("crease_threshold", _crease_threshold)
		"depth_normals":
			var material: ShaderMaterial = _add_fullscreen(DEPTH_NORMALS_SHADER, 100)
			if _crease_threshold > 0.0:
				material.set_shader_parameter("crease_angle", _crease_threshold)
			if OS.get_cmdline_user_args().has("--debug"):
				material.set_shader_parameter("debug_view", 1)
			if OS.get_cmdline_user_args().has("--debug2"):
				material.set_shader_parameter("debug_view", 2)
		"depth_outline_silhouette":
			var material: ShaderMaterial = _add_fullscreen(DEPTH_OUTLINE_SHADER, 0)
			material.set_shader_parameter("use_creases", false)
		"normal_roughness":
			_add_fullscreen(NORMAL_ROUGHNESS_SHADER, 0)
		"albedo_test":
			_add_fullscreen(load("res://shaders/albedo_test.gdshader") as Shader, 0)
		"albedo_test_srgb":
			_add_fullscreen(load("res://shaders/albedo_test_srgb.gdshader") as Shader, 0)
		"albedo_test_alpha":
			_add_fullscreen(load("res://shaders/albedo_test_alpha.gdshader") as Shader, 0)
		"passthrough":
			_add_fullscreen(PASSTHROUGH_SHADER, 0)
		"dither":
			var material: ShaderMaterial = _add_fullscreen(DITHER_SCREEN_SHADER, 0)
			_set_palette(material)
		"dither_canvas":
			var material: ShaderMaterial = ShaderMaterial.new()
			material.shader = DITHER_CANVAS_SHADER
			_set_palette(material)
			for arg: String in OS.get_cmdline_user_args():
				if arg.begins_with("--spread="):
					material.set_shader_parameter("spread", float(arg.trim_prefix("--spread=")))
			_container.material = material
		"glow":
			_enable_glow(0.0)
		"glow_bloom":
			_enable_glow(0.25)
		"combo":
			_add_fullscreen(DEPTH_NORMALS_SHADER, 100)
			_enable_glow(0.0)
			_environment.background_energy_multiplier = 0.25
			var material: ShaderMaterial = ShaderMaterial.new()
			material.shader = DITHER_CANVAS_SHADER
			_set_palette(material)
			material.set_shader_parameter("spread", 0.04)
			_container.material = material
		"depth_glow":
			_add_fullscreen(DEPTH_NORMALS_SHADER, 100)
			_enable_glow(0.0)
			_environment.background_energy_multiplier = 0.25
		_:
			push_error("Modo desconocido: " + _mode)


func _enable_glow(bloom: float) -> void:
	_environment.glow_enabled = true
	_environment.glow_intensity = 0.8
	_environment.glow_strength = 1.0
	_environment.glow_bloom = bloom
	_environment.glow_hdr_threshold = 1.0
	_environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE


func _set_palette(material: ShaderMaterial) -> void:
	var colors: PackedVector3Array = PackedVector3Array()
	for hex: String in PALETTE_HEX:
		var color: Color = Color(hex)
		colors.append(Vector3(color.r, color.g, color.b))
	material.set_shader_parameter("palette", colors)
	material.set_shader_parameter("palette_size", colors.size())


func _add_fullscreen(shader: Shader, priority: int) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	material.render_priority = priority
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = quad
	instance.material_override = material
	instance.extra_cull_margin = 16384.0
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_world.add_child(instance)
	return material


func _add_box(size: Vector3, center: Vector3, material: Material, hull: bool) -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	_add_mesh(mesh, center, material, hull)


func _add_sphere(radius: float, center: Vector3, material: Material, hull: bool) -> void:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	_add_mesh(mesh, center, material, hull)


func _add_mesh(mesh: Mesh, center: Vector3, material: Material, hull: bool) -> void:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = center
	var surface: Material = material
	if hull:
		var outline: ShaderMaterial = ShaderMaterial.new()
		outline.shader = OUTLINE_SHADER
		var base: Material = material.duplicate()
		base.next_pass = outline
		surface = base
	instance.material_override = surface
	_world.add_child(instance)


func _toon(hex: String) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(hex)
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return material


func _emissive(hex: String, energy: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(hex) * energy
	material.albedo_color.a = 1.0
	return material


func _floor_material() -> StandardMaterial3D:
	var image: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var colors: Array[Color] = [Color("a86d43"), Color("9c643c"), Color("b3764a")]
	for y: int in 16:
		for x: int in 16:
			var plank: int = (y / 4 + (x / 8) * 2) % 3
			var color: Color = colors[plank]
			if y % 4 == 3:
				color = Color("6a3f22")
			image.set_pixel(x, y, color)
	var material: StandardMaterial3D = _toon("ffffff")
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3(1.6, 1.6, 1.6)
	return material

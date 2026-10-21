extends Control
## Experimentos B (iluminación y detalle) en el renderizador Compatibility.
## Uso: godot --path . -- --features=ramp,omni,limit,ao_quads,ao_vertex,decal,dust,shaft,screen,night [--bench]

const OUTLINE_SHADER: Shader = preload("res://shaders/outline.gdshader")
const TOON_RAMP_SHADER: Shader = preload("res://shaders/toon_ramp.gdshader")
const SCREEN_SHADER: Shader = preload("res://shaders/screen_flicker.gdshader")
const CONTACT_AO_SHADER: Shader = preload("res://shaders/contact_ao.gdshader")
const LIGHT_SHAFT_SHADER: Shader = preload("res://shaders/light_shaft.gdshader")

const PIXEL_WORLD_SIZE: float = 0.028
const ROOM_SIZE: float = 4.5
const WALL_HEIGHT: float = 2.6
const WALL_THICKNESS: float = 0.2
const CAMERA_SIZE: float = 6.8
const CAMERA_TARGET: Vector3 = Vector3(-0.1, 1.05, -0.1)
const CAMERA_DISTANCE: float = 20.0
const WINDOW_CENTER: Vector3 = Vector3(-2.24, 1.55, -0.7)
const WINDOW_SIZE: Vector2 = Vector2(1.16, 0.86)
const DESK_CENTER: Vector3 = Vector3(0.15, 0.0, -1.85)
const DESK_SIZE: Vector3 = Vector3(1.5, 0.75, 0.7)
const BOX_CENTER: Vector3 = Vector3(1.3, 0.0, -0.9)
const BOX_SIZE: float = 0.5
const AO_GRID_STEP: float = 0.075
const BENCH_WARMUP: int = 60
const BENCH_FRAMES: int = 400

var _features: PackedStringArray = PackedStringArray()
var _bench: bool = false
var _viewport: SubViewport
var _world: Node3D
var _sun: DirectionalLight3D
var _screen_light: OmniLight3D
var _screen_light_energy: float = 0.0
var _materials: Dictionary[String, Material] = {}
var _outline: ShaderMaterial
var _ramp: GradientTexture1D
var _contacts: Array[Rect2] = []
var _contact_strength: PackedFloat32Array = PackedFloat32Array()
var _contact_radius: PackedFloat32Array = PackedFloat32Array()
var _fps_label: Label
var _frame: int = 0
var _time: float = 0.0
var _bench_start_usec: int = 0
var _cpu_total: float = 0.0
var _gpu_total: float = 0.0


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--features="):
			_features = arg.trim_prefix("--features=").split(",", false)
		elif arg == "--bench":
			_bench = true
	if _bench:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
	_build_viewport()
	_build_environment()
	_build_camera()
	_build_room()
	_build_desk()
	_build_box()
	if _has("omni"):
		_build_local_lights()
	if _has("limit"):
		_build_light_grid()
	if _has("ao_quads"):
		_build_contact_quads()
	if _has("ao_vertex"):
		_build_vertex_ao()
	if _has("decal"):
		_build_decal()
	if _has("shaft"):
		_build_light_shaft()
	if _has("dust"):
		_build_dust()
	RenderingServer.viewport_set_measure_render_time(_viewport.get_viewport_rid(), true)
	print("FEATURES=%s renderer=%s adapter=%s max_lights_per_object=%s max_renderable_lights=%s" % [
		",".join(_features), RenderingServer.get_current_rendering_method(),
		RenderingServer.get_video_adapter_name(),
		ProjectSettings.get_setting("rendering/limits/opengl/max_lights_per_object"),
		ProjectSettings.get_setting("rendering/limits/opengl/max_renderable_lights")])


func _process(delta: float) -> void:
	_frame += 1
	_time += delta
	if _screen_light != null:
		var step: float = floorf(_time * 8.0)
		var noise: float = fposmod(sin(step * 12.9898) * 43758.5453, 1.0)
		_screen_light.light_energy = _screen_light_energy * (0.85 + 0.15 * noise)
	if _frame % 30 == 0:
		_fps_label.text = "FPS %d" % Engine.get_frames_per_second()
	if not _bench:
		return
	if _frame == BENCH_WARMUP:
		_bench_start_usec = Time.get_ticks_usec()
	elif _frame > BENCH_WARMUP:
		var rid: RID = _viewport.get_viewport_rid()
		_cpu_total += RenderingServer.viewport_get_measured_render_time_cpu(rid)
		_gpu_total += RenderingServer.viewport_get_measured_render_time_gpu(rid)
		if _frame == BENCH_WARMUP + BENCH_FRAMES:
			var elapsed: float = float(Time.get_ticks_usec() - _bench_start_usec) / 1000000.0
			print("BENCH features=%s frames=%d avg_fps=%.1f engine_fps=%.0f vp_cpu_ms=%.3f vp_gpu_ms=%.3f" % [
				",".join(_features), BENCH_FRAMES, float(BENCH_FRAMES) / elapsed,
				Engine.get_frames_per_second(), _cpu_total / BENCH_FRAMES, _gpu_total / BENCH_FRAMES])
			get_tree().quit()


func _has(feature: String) -> bool:
	return _features.has(feature)


# --- Escena base ---------------------------------------------------------

func _build_viewport() -> void:
	var container: SubViewportContainer = SubViewportContainer.new()
	container.stretch = true
	container.stretch_shrink = 2
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(container)
	_viewport = SubViewport.new()
	_viewport.msaa_3d = Viewport.MSAA_DISABLED
	container.add_child(_viewport)
	_world = Node3D.new()
	_viewport.add_child(_world)
	_fps_label = Label.new()
	_fps_label.position = Vector2(8.0, 8.0)
	_fps_label.add_theme_font_size_override("font_size", 18)
	add_child(_fps_label)


func _build_environment() -> void:
	var night: bool = _has("night")
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("141b2d")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	if _has("ramp"):
		# En Compatibility la luz con sombra se suma en otra pasada (en espacio
		# gamma) encima del ambiente: el ambiente "lava" la banda de sombra.
		# Con la rampa, el ambiente va en 0 y la rampa define todos los tonos.
		environment.ambient_light_color = Color("3d3f80")
		environment.ambient_light_energy = 0.0
	else:
		environment.ambient_light_color = Color("ffe6c7")
		environment.ambient_light_energy = 0.5
	if _has("no_ambient"):
		environment.ambient_light_energy = 0.0
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = environment
	_world.add_child(world_environment)

	_sun = DirectionalLight3D.new()
	_sun.name = "Sun"
	_sun.rotation_degrees = Vector3(-55.0, -60.0, 0.0)
	_sun.light_color = Color("fff1dc")
	_sun.light_energy = 1.6 if _has("ramp") else 0.75
	if night:
		_sun.light_color = Color("ffa66e")
		_sun.light_energy = 0.45
	if _has("limit"):
		_sun.light_energy = 0.2
	_sun.shadow_enabled = not _has("no_sun_shadow")
	_sun.directional_shadow_max_distance = 30.0
	if _has("sun_ortho"):
		# Un solo mapa de sombra (sin cortes PSSM): basta con cámara ortográfica fija.
		_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		_sun.directional_shadow_max_distance = 26.0
	_world.add_child(_sun)


func _build_camera() -> void:
	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = CAMERA_SIZE
	camera.near = 0.1
	camera.far = 60.0
	camera.rotation_degrees = Vector3(-30.0, 45.0, 0.0)
	camera.position = CAMERA_TARGET - camera.basis * Vector3.FORWARD * CAMERA_DISTANCE
	camera.current = true
	_world.add_child(camera)


func _build_room() -> void:
	var half: float = ROOM_SIZE / 2.0
	_box("Floor", Vector3(ROOM_SIZE, 0.2, ROOM_SIZE), Vector3(0.0, -0.1, 0.0), _textured("floor_planks"))
	var brick: Material = _textured("brick_wall")
	var trim: Material = _solid("3a2f3f")
	var base_board: Material = _solid("6e4426")
	var left_x: float = -half - WALL_THICKNESS / 2.0
	var back_z: float = -half - WALL_THICKNESS / 2.0
	_wall("LeftWall", Vector3(WALL_THICKNESS, WALL_HEIGHT, ROOM_SIZE + WALL_THICKNESS), Vector3(left_x, WALL_HEIGHT / 2.0, -WALL_THICKNESS / 2.0), brick)
	_wall("BackWall", Vector3(ROOM_SIZE, WALL_HEIGHT, WALL_THICKNESS), Vector3(0.0, WALL_HEIGHT / 2.0, back_z), brick)
	_wall("LeftCap", Vector3(WALL_THICKNESS + 0.06, 0.08, ROOM_SIZE + WALL_THICKNESS + 0.06), Vector3(left_x, WALL_HEIGHT + 0.04, -WALL_THICKNESS / 2.0), trim)
	_wall("BackCap", Vector3(ROOM_SIZE + 0.06, 0.08, WALL_THICKNESS + 0.06), Vector3(0.03, WALL_HEIGHT + 0.04, back_z), trim)
	_box("LeftBaseboard", Vector3(0.04, 0.12, ROOM_SIZE), Vector3(-half + 0.02, 0.06, 0.0), base_board)
	_box("BackBaseboard", Vector3(ROOM_SIZE, 0.12, 0.04), Vector3(0.0, 0.06, -half + 0.02), base_board)

	var frame: Material = _solid("6e4426")
	var window: Node3D = _group("Window", WINDOW_CENTER)
	_quad(window, "View", WINDOW_SIZE, Vector3.ZERO, _glow("ffffff", "window_view"), Vector3(0.0, 90.0, 0.0))
	_box("Top", Vector3(0.08, 0.08, 1.32), Vector3(0.0, 0.47, 0.0), frame, window)
	_box("Bottom", Vector3(0.14, 0.06, 1.36), Vector3(0.03, -0.47, 0.0), frame, window)
	_box("Left", Vector3(0.08, 0.86, 0.08), Vector3(0.0, 0.0, -0.62), frame, window)
	_box("Right", Vector3(0.08, 0.86, 0.08), Vector3(0.0, 0.0, 0.62), frame, window)
	_box("Middle", Vector3(0.05, 0.86, 0.04), Vector3(0.0, 0.0, 0.0), frame, window)


func _build_desk() -> void:
	var desk: Node3D = _group("Desk", DESK_CENTER)
	var top_y: float = DESK_SIZE.y
	_box("Top", Vector3(DESK_SIZE.x, 0.05, DESK_SIZE.z), Vector3(0.0, top_y - 0.025, 0.0), _solid("c98b4f"), desk)
	var leg_height: float = top_y - 0.05
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var leg: Vector3 = Vector3(sx * (DESK_SIZE.x / 2.0 - 0.06), leg_height / 2.0, sz * (DESK_SIZE.z / 2.0 - 0.06))
			_box("Leg", Vector3(0.06, leg_height, 0.06), leg, _solid("6e4426"), desk)
			_add_contact(Rect2(DESK_CENTER.x + leg.x - 0.03, DESK_CENTER.z + leg.z - 0.03, 0.06, 0.06), 0.75, 0.12)
	_add_contact(Rect2(DESK_CENTER.x - DESK_SIZE.x / 2.0, DESK_CENTER.z - DESK_SIZE.z / 2.0, DESK_SIZE.x, DESK_SIZE.z), 0.35, 0.22)

	# Monitor con pie.
	var plastic: Material = _solid("23242b")
	_box("MonitorBase", Vector3(0.24, 0.02, 0.16), Vector3(-0.05, top_y + 0.01, -0.14), plastic, desk)
	_box("MonitorNeck", Vector3(0.05, 0.24, 0.04), Vector3(-0.05, top_y + 0.13, -0.18), plastic, desk)
	_box("MonitorBody", Vector3(0.64, 0.42, 0.05), Vector3(-0.05, top_y + 0.44, -0.15), plastic, desk)
	var screen_material: Material = _screen_material()
	_quad(desk, "Screen", Vector2(0.58, 0.36), Vector3(-0.05, top_y + 0.44, -0.124), screen_material)
	_box("Keyboard", Vector3(0.44, 0.025, 0.14), Vector3(-0.05, top_y + 0.0125, 0.12), _solid("2b2f3a"), desk)
	_cylinder("Mug", 0.045, 0.1, Vector3(0.42, top_y + 0.05, 0.12), _solid("e5484d"), desk)
	_cylinder("SpoolA", 0.11, 0.07, Vector3(0.55, top_y + 0.035, -0.17), _solid("4cbf5a"), desk)
	_cylinder("SpoolB", 0.11, 0.07, Vector3(0.55, top_y + 0.105, -0.17), _solid("9b5de5"), desk)

	# Lámpara de escritorio.
	var metal: Material = _solid("2b2f3a")
	_cylinder("LampBase", 0.07, 0.03, Vector3(-0.6, top_y + 0.015, -0.18), metal, desk)
	var arm: MeshInstance3D = _box("LampArm", Vector3(0.025, 0.42, 0.025), Vector3(-0.56, top_y + 0.22, -0.16), metal, desk)
	arm.rotation_degrees = Vector3(15.0, 0.0, -12.0)
	var head: MeshInstance3D = _cylinder("LampHead", 0.075, 0.11, Vector3(-0.48, top_y + 0.42, -0.08), _solid("f2a541"), desk)
	head.rotation_degrees = Vector3(35.0, 0.0, -20.0)
	_sphere("LampBulb", 0.035, Vector3(-0.46, top_y + 0.37, -0.05), _glow("fff1c1"), desk)


func _build_box() -> void:
	_box("Box", Vector3(BOX_SIZE, BOX_SIZE, BOX_SIZE), BOX_CENTER + Vector3(0.0, BOX_SIZE / 2.0, 0.0), _textured("cardboard"))
	_add_contact(Rect2(BOX_CENTER.x - BOX_SIZE / 2.0, BOX_CENTER.z - BOX_SIZE / 2.0, BOX_SIZE, BOX_SIZE), 0.8, 0.25)


func _add_contact(rect: Rect2, strength: float, radius: float) -> void:
	_contacts.append(rect)
	_contact_strength.append(strength)
	_contact_radius.append(radius)


# --- Experimento 2: luces locales -----------------------------------------

func _build_local_lights() -> void:
	var night: bool = _has("night")
	var top_y: float = DESK_SIZE.y
	_omni("LampLight", DESK_CENTER + Vector3(-0.42, top_y + 0.3, 0.0), Color("ffb35c"), 2.2 if night else 1.4, 1.9)
	_screen_light_energy = 1.2 if night else 0.7
	_screen_light = _omni("ScreenLight", DESK_CENTER + Vector3(-0.05, top_y + 0.42, 0.2), Color("5fd7ff"), _screen_light_energy, 1.3)
	var half: float = ROOM_SIZE / 2.0
	var sconce: Node3D = _group("Sconce", Vector3(1.35, 1.85, -half))
	_box("Bracket", Vector3(0.12, 0.16, 0.06), Vector3(0.0, 0.0, 0.03), _solid("2b2f3a"), sconce)
	_sphere("Bulb", 0.05, Vector3(0.0, -0.02, 0.1), _glow("ffe3a3"), sconce)
	_omni("SconceLight", Vector3(1.35, 1.75, -half + 0.3), Color("ffcf87"), 1.8 if night else 1.0, 2.0)


func _build_light_grid() -> void:
	var colors: Array[Color] = [
		Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.MAGENTA, Color.CYAN,
		Color.ORANGE, Color.WHITE, Color.HOT_PINK, Color.CHARTREUSE, Color.PURPLE, Color.TEAL,
	]
	var index: int = 0
	for row: int in 3:
		for col: int in 4:
			var position: Vector3 = Vector3(-1.65 + col * 1.1, 0.3, -0.9 + row * 1.1)
			_omni("Grid%d" % index, position, colors[index], 3.0, 0.6)
			index += 1


func _omni(node_name: String, position: Vector3, color: Color, energy: float, light_range: float) -> OmniLight3D:
	var light: OmniLight3D = OmniLight3D.new()
	light.name = node_name
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.shadow_enabled = false
	_world.add_child(light)
	return light


# --- Experimento 3: oclusión ambiental falsa -------------------------------

func _build_contact_quads() -> void:
	var half: float = ROOM_SIZE / 2.0
	var strip: float = 0.35
	var wall_strip: float = 0.3
	# Franjas en el piso, junto a cada pared (UV.y = 0 en la pared).
	_ao_plane("FloorBack", Vector2(ROOM_SIZE, strip), Vector3(0.0, 0.003, -half + strip / 2.0), Vector3.ZERO, 0, 0.8)
	_ao_plane("FloorLeft", Vector2(ROOM_SIZE, strip), Vector3(-half + strip / 2.0, 0.003, 0.0), Vector3(0.0, 90.0, 0.0), 0, 0.8)
	# Franjas en la base de las paredes y en la esquina entre paredes.
	_ao_quad("WallBack", Vector2(ROOM_SIZE, wall_strip), Vector3(0.0, wall_strip / 2.0, -half + 0.003), Vector3(0.0, 0.0, 180.0), 0.75)
	_ao_quad("WallLeft", Vector2(ROOM_SIZE, wall_strip), Vector3(-half + 0.003, wall_strip / 2.0, 0.0), Vector3(0.0, 90.0, 180.0), 0.75)
	_ao_quad("CornerBack", Vector2(WALL_HEIGHT, wall_strip), Vector3(-half + wall_strip / 2.0, WALL_HEIGHT / 2.0, -half + 0.004), Vector3(0.0, 0.0, 90.0), 0.7)
	_ao_quad("CornerLeft", Vector2(WALL_HEIGHT, wall_strip), Vector3(-half + 0.004, WALL_HEIGHT / 2.0, -half + wall_strip / 2.0), Vector3(0.0, 90.0, -90.0), 0.7)
	# Manchas de contacto bajo cada objeto.
	for index: int in _contacts.size():
		var rect: Rect2 = _contacts[index]
		var radius: float = _contact_radius[index]
		var size: Vector2 = rect.size + Vector2(radius, radius) * 2.0
		var center: Vector2 = rect.get_center()
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = CONTACT_AO_SHADER
		material.set_shader_parameter("shape", 1)
		material.set_shader_parameter("size_m", size)
		material.set_shader_parameter("falloff_m", radius)
		material.set_shader_parameter("strength", minf(_contact_strength[index] * 1.25, 1.0))
		var mesh: PlaneMesh = PlaneMesh.new()
		mesh.size = size
		var instance: MeshInstance3D = _mesh_instance("Contact%d" % index, mesh, Vector3(center.x, 0.004 + index * 0.0005, center.y), material, _world)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _ao_plane(node_name: String, size: Vector2, position: Vector3, rotation: Vector3, shape: int, strength: float) -> void:
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = size
	var instance: MeshInstance3D = _mesh_instance(node_name, mesh, position, _ao_material(shape, strength), _world)
	instance.rotation_degrees = rotation
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _ao_quad(node_name: String, size: Vector2, position: Vector3, rotation: Vector3, strength: float) -> void:
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = size
	var instance: MeshInstance3D = _mesh_instance(node_name, mesh, position, _ao_material(0, strength), _world)
	instance.rotation_degrees = rotation
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _ao_material(shape: int, strength: float) -> ShaderMaterial:
	var key: String = "ao:%d:%s" % [shape, strength]
	if not _materials.has(key):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = CONTACT_AO_SHADER
		material.set_shader_parameter("shape", shape)
		material.set_shader_parameter("strength", strength)
		_materials[key] = material
	return _materials[key] as ShaderMaterial


func _build_vertex_ao() -> void:
	var half: float = ROOM_SIZE / 2.0
	var floor_material: Material = _lit_material("floor_ao", Color.WHITE, "floor_planks", true)
	var wall_material: Material = _lit_material("wall_ao", Color.WHITE, "brick_wall", true)
	var floor_mesh: ArrayMesh = _ao_grid(Vector3(-half, 0.002, -half), Vector3(ROOM_SIZE, 0.0, 0.0), Vector3(0.0, 0.0, ROOM_SIZE), Vector3.UP, false)
	var back_mesh: ArrayMesh = _ao_grid(Vector3(-half, 0.0, -half + 0.002), Vector3(ROOM_SIZE, 0.0, 0.0), Vector3(0.0, WALL_HEIGHT, 0.0), Vector3.BACK, true)
	var left_mesh: ArrayMesh = _ao_grid(Vector3(-half + 0.002, 0.0, -half), Vector3(0.0, 0.0, ROOM_SIZE), Vector3(0.0, WALL_HEIGHT, 0.0), Vector3.RIGHT, true)
	var triangles: int = 0
	for item: Array in [["FloorAO", floor_mesh, floor_material], ["BackAO", back_mesh, wall_material], ["LeftAO", left_mesh, wall_material]]:
		var mesh: ArrayMesh = item[1]
		var instance: MeshInstance3D = _mesh_instance(item[0], mesh, Vector3.ZERO, item[2], _world)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		triangles += mesh.surface_get_array_index_len(0) / 3
	print("VERTEX_AO triangles=%d" % triangles)


func _ao_grid(origin: Vector3, axis_u: Vector3, axis_v: Vector3, normal: Vector3, is_wall: bool) -> ArrayMesh:
	var cells_u: int = ceili(axis_u.length() / AO_GRID_STEP)
	var cells_v: int = ceili(axis_v.length() / AO_GRID_STEP)
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v: int in cells_v + 1:
		for u: int in cells_u + 1:
			var point: Vector3 = origin + axis_u * (float(u) / cells_u) + axis_v * (float(v) / cells_v)
			var light: float = 1.0 - _occlusion_at(point, is_wall)
			tool.set_color(Color(light, light, light))
			tool.set_normal(normal)
			tool.set_uv(Vector2(float(u) / cells_u, float(v) / cells_v))
			tool.add_vertex(point)
	# Godot toma como cara frontal la que se ve en sentido horario.
	var flip: bool = axis_u.cross(axis_v).dot(normal) > 0.0
	for v: int in cells_v:
		for u: int in cells_u:
			var a: int = v * (cells_u + 1) + u
			var b: int = a + 1
			var c: int = a + cells_u + 1
			var d: int = c + 1
			if flip:
				tool.add_index(a)
				tool.add_index(c)
				tool.add_index(b)
				tool.add_index(b)
				tool.add_index(c)
				tool.add_index(d)
			else:
				tool.add_index(a)
				tool.add_index(b)
				tool.add_index(c)
				tool.add_index(b)
				tool.add_index(d)
				tool.add_index(c)
	return tool.commit()


func _occlusion_at(point: Vector3, is_wall: bool) -> float:
	var half: float = ROOM_SIZE / 2.0
	var keep: float = 1.0
	# Cada pared ignora la distancia a su propio plano (sería 0).
	if point.x > -half + 0.01:
		keep *= 1.0 - 0.6 * _falloff(point.x + half, 0.4)
	if point.z > -half + 0.01:
		keep *= 1.0 - 0.6 * _falloff(point.z + half, 0.4)
	if is_wall:
		keep *= 1.0 - 0.55 * _falloff(point.y, 0.3)
	else:
		var flat: Vector2 = Vector2(point.x, point.z)
		for index: int in _contacts.size():
			var distance: float = _rect_distance(_contacts[index], flat)
			keep *= 1.0 - _contact_strength[index] * _falloff(distance, _contact_radius[index])
	return 1.0 - keep


func _falloff(distance: float, radius: float) -> float:
	return pow(clampf(1.0 - distance / radius, 0.0, 1.0), 1.5)


func _rect_distance(rect: Rect2, point: Vector2) -> float:
	var dx: float = maxf(maxf(rect.position.x - point.x, 0.0), point.x - rect.end.x)
	var dy: float = maxf(maxf(rect.position.y - point.y, 0.0), point.y - rect.end.y)
	return Vector2(dx, dy).length()


func _build_decal() -> void:
	var image: Image = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 0.0, 0.0, 1.0))
	var decal: Decal = Decal.new()
	decal.name = "TestDecal"
	decal.size = Vector3(0.8, 0.6, 0.8)
	decal.position = Vector3(0.4, 0.0, 0.6)
	decal.texture_albedo = ImageTexture.create_from_image(image)
	_world.add_child(decal)


# --- Experimento 4: polvo en la luz de la ventana --------------------------

func _beam_points() -> Array[Vector3]:
	var sun_direction: Vector3 = -_sun.basis.z
	var half_w: float = WINDOW_SIZE.x / 2.0
	var half_h: float = WINDOW_SIZE.y / 2.0
	var base: Vector3 = WINDOW_CENTER + Vector3(0.02, 0.0, 0.0)
	var window_points: Array[Vector3] = [
		base + Vector3(0.0, -half_h, -half_w), base + Vector3(0.0, half_h, -half_w),
		base + Vector3(0.0, half_h, half_w), base + Vector3(0.0, -half_h, half_w),
	]
	var points: Array[Vector3] = []
	points.append_array(window_points)
	for point: Vector3 in window_points:
		points.append(point + sun_direction * (point.y / -sun_direction.y))
	return points


func _build_light_shaft() -> void:
	var points: Array[Vector3] = _beam_points()
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in 4:
		var j: int = (i + 1) % 4
		var quad: Array[Vector3] = [points[i], points[j], points[j + 4], points[i + 4]]
		var uvs: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)]
		for k: int in [0, 1, 2, 0, 2, 3]:
			tool.set_uv(uvs[k])
			tool.add_vertex(quad[k])
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = LIGHT_SHAFT_SHADER
	var instance: MeshInstance3D = _mesh_instance("LightShaft", tool.commit(), Vector3.ZERO, material, _world)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_dust() -> void:
	var points: Array[Vector3] = _beam_points()
	var top: Vector3 = (points[0] + points[1] + points[2] + points[3]) / 4.0
	var bottom: Vector3 = (points[4] + points[5] + points[6] + points[7]) / 4.0
	var y_axis: Vector3 = (top - bottom).normalized()
	var x_axis: Vector3 = (Vector3.BACK - y_axis * y_axis.dot(Vector3.BACK)).normalized()
	var z_axis: Vector3 = x_axis.cross(y_axis)
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.name = "Dust"
	particles.transform = Transform3D(Basis(x_axis, y_axis, z_axis), (top + bottom) / 2.0)
	particles.amount = 70
	particles.lifetime = 7.0
	particles.preprocess = 7.0
	particles.local_coords = false
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(WINDOW_SIZE.x * 0.45, top.distance_to(bottom) * 0.45, WINDOW_SIZE.y * 0.3)
	particles.direction = Vector3.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 0.01
	particles.initial_velocity_max = 0.05
	particles.gravity = Vector3(0.0, -0.006, 0.0)
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 1.8
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.022, 0.022)
	particles.mesh = quad
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color("fff3d1")
	quad.material = material
	var gradient: Gradient = Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	gradient.offsets = PackedFloat32Array([0.0, 0.15, 0.3, 0.7, 0.85])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.0), Color(1.0, 1.0, 1.0, 0.45), Color(1.0, 1.0, 1.0, 0.9),
		Color(1.0, 1.0, 1.0, 0.45), Color(1.0, 1.0, 1.0, 0.0),
	])
	particles.color_ramp = gradient
	_world.add_child(particles)


# --- Experimento 5: pantalla animada ----------------------------------------

func _screen_material() -> Material:
	if _has("screen"):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = SCREEN_SHADER
		return material
	return _glow("ffffff", "crt_screen")


# --- Materiales -------------------------------------------------------------

func _solid(hex: String) -> Material:
	return _lit_material("solid:" + hex, Color(hex), "", false)


func _textured(texture_name: String) -> Material:
	return _lit_material("tex:" + texture_name, Color.WHITE, texture_name, false)


func _lit_material(key: String, color: Color, texture_name: String, vertex_ao: bool) -> Material:
	if _materials.has(key):
		return _materials[key]
	var material: Material
	if _has("ramp") or vertex_ao:
		var shader_material: ShaderMaterial = ShaderMaterial.new()
		shader_material.shader = TOON_RAMP_SHADER
		shader_material.set_shader_parameter("albedo", color)
		shader_material.set_shader_parameter("ramp", _ramp_texture())
		if _has("ramp_uniform"):
			shader_material.set_shader_parameter("ramp_source", 1)
		shader_material.set_shader_parameter("use_vertex_ao", vertex_ao)
		var debug_mode: int = 1 if _has("debug_atten") else (2 if _has("debug_ndl") else (3 if _has("debug_band") else (4 if _has("debug_lit") else (5 if _has("debug_const") else (6 if _has("debug_count") else 0)))))
		if debug_mode > 0:
			shader_material.set_shader_parameter("debug_mode", debug_mode)
			shader_material.set_shader_parameter("albedo", Color.WHITE)
			shader_material.set_shader_parameter("use_texture", false)
		if not texture_name.is_empty():
			var texture: Texture2D = PixelTextures.get_texture(texture_name)
			shader_material.set_shader_parameter("albedo_tex", texture)
			shader_material.set_shader_parameter("use_texture", true)
			shader_material.set_shader_parameter("tex_scale", 1.0 / (texture.get_width() * PIXEL_WORLD_SIZE))
		material = shader_material
		if debug_mode > 0:
			_materials[key] = material
			return material
	else:
		var standard: StandardMaterial3D = StandardMaterial3D.new()
		standard.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		standard.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		standard.roughness = 1.0
		standard.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		standard.albedo_color = color
		if not texture_name.is_empty():
			var texture: Texture2D = PixelTextures.get_texture(texture_name)
			standard.albedo_texture = texture
			standard.uv1_triplanar = true
			standard.uv1_world_triplanar = true
			standard.uv1_triplanar_sharpness = 64.0
			var scale: float = 1.0 / (texture.get_width() * PIXEL_WORLD_SIZE)
			standard.uv1_scale = Vector3(scale, scale, scale)
		material = standard
	if not vertex_ao:
		material.next_pass = _outline_material()
	_materials[key] = material
	return material


func _ramp_texture() -> Texture2D:
	if _has("ramp_image"):
		var image: Image = Image.create_empty(64, 1, false, Image.FORMAT_RGBA8)
		for x: int in 64:
			var t: float = float(x) / 63.0
			image.set_pixel(x, 0, Color("3e3478") if t < 0.18 else (Color("a88290") if t < 0.5 else Color("ffe2c0")))
		return ImageTexture.create_from_image(image)
	if _ramp == null:
		var gradient: Gradient = Gradient.new()
		gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
		gradient.offsets = PackedFloat32Array([0.0, 0.18, 0.5])
		gradient.colors = PackedColorArray([Color("3c3070"), Color("a07c90"), Color("ffe4c2")])
		_ramp = GradientTexture1D.new()
		_ramp.gradient = gradient
		_ramp.width = 64
	return _ramp


func _glow(hex: String, texture_name: String = "") -> StandardMaterial3D:
	var key: String = "glow:%s:%s" % [hex, texture_name]
	if not _materials.has(key):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(hex)
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		if not texture_name.is_empty():
			material.albedo_texture = PixelTextures.get_texture(texture_name)
		_materials[key] = material
	return _materials[key] as StandardMaterial3D


func _outline_material() -> ShaderMaterial:
	if _outline == null:
		_outline = ShaderMaterial.new()
		_outline.shader = OUTLINE_SHADER
		_outline.set_shader_parameter("outline_color", Color("1a1320"))
	return _outline


# --- Formas básicas ---------------------------------------------------------

func _group(node_name: String, position: Vector3) -> Node3D:
	var node: Node3D = Node3D.new()
	node.name = node_name
	node.position = position
	_world.add_child(node)
	return node


func _wall(node_name: String, size: Vector3, position: Vector3, material: Material) -> void:
	var wall: MeshInstance3D = _box(node_name, size, position, material)
	wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _box(node_name: String, size: Vector3, position: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	return _mesh_instance(node_name, mesh, position, material, parent if parent != null else _world)


func _cylinder(node_name: String, radius: float, height: float, position: Vector3, material: Material, parent: Node3D) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 1
	return _mesh_instance(node_name, mesh, position, material, parent)


func _sphere(node_name: String, radius: float, position: Vector3, material: Material, parent: Node3D) -> MeshInstance3D:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	return _mesh_instance(node_name, mesh, position, material, parent)


func _quad(parent: Node3D, node_name: String, size: Vector2, position: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = size
	var instance: MeshInstance3D = _mesh_instance(node_name, mesh, position, material, parent)
	instance.rotation_degrees = rotation
	return instance


func _mesh_instance(node_name: String, mesh: Mesh, position: Vector3, material: Material, parent: Node3D) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	if _has("no_cast"):
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance

extends GutTest
## Las vistas 3D de la interfaz (ModelPreview, biblia de arte §11 y §7.9):
## cada malla lleva la luz de estudio (una copia de su material con
## preview_light = 1; los materiales del mundo no cambian), se dibujan a la
## resolución del mundo (la misma k, con el tope del nivel de calidad) con
## MSAA 4× y se ven del tamaño de la vista, la cámara tiene la inclinación
## del mundo y el modelo entero entra en la vista, y detrás va el disco de
## luz.

const SETTINGS_PATH: String = "user://test_model_preview_settings.cfg"
## Lado de las vistas de la tienda (px de la interfaz).
const SIZE: float = Previews.SIZE
## Ventanas físicas (ancho, alto) y la k que les toca en Alta y en Baja (la
## interfaz mide 720 de ancho).
const WINDOWS: Array[Array] = [
	[405, 720, 0.5625, 0.5625],
	[720, 1280, 1.0, 1.0],
	[1080, 1920, 1.5, 1.0],
	[1440, 2560, 1.5, 1.0],
]
const PREVIEW_LIGHT: StringName = WorldPalette.PREVIEW_LIGHT

var _previous_window_size: Vector2i
var _previous_quality: GraphicsQuality
var _previous_settings_path: String
var _quality: GraphicsQuality
var _shelf: VBoxContainer


func before_each() -> void:
	_previous_window_size = get_tree().root.size
	_previous_quality = GraphicsQuality.current
	_previous_settings_path = UserSettings.path
	UserSettings.path = SETTINGS_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	_quality = GraphicsQuality.new(UserSettings.load_settings())
	_quality.set_mode(GraphicsQuality.Mode.HIGH)
	GraphicsQuality.current = _quality
	# Las vistas van dentro de contenedores, como en la tienda.
	_shelf = VBoxContainer.new()
	add_child_autofree(_shelf)


func after_each() -> void:
	get_tree().root.size = _previous_window_size
	GraphicsQuality.current = _previous_quality
	UserSettings.path = _previous_settings_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))


func test_every_mesh_of_a_view_is_lit_by_the_studio_and_the_world_is_not() -> void:
	var views: Array[ModelPreview] = []
	for printer: Dictionary in Game.catalog.files["printers"]:
		views.append(_add(Previews.printer(printer["id"])))
	for furniture: Dictionary in Game.catalog.files["furniture"]:
		views.append(_add(Previews.furniture(furniture["id"])))
	var portrait: ModelPreview = ModelPreview.new(func(world: Node3D) -> void: CharacterModel.build(world, "Character"), ProfileCard.PORTRAIT_SIZE, ProfileCard.PORTRAIT_FRAME, ProfileCard.PORTRAIT_TARGET, ProfileCard.PORTRAIT_YAW, ProfileCard.PORTRAIT_PITCH)
	_shelf.add_child(portrait)
	views.append(portrait)
	await wait_process_frames(1)
	assert_eq(views.size(), (Game.catalog.files["printers"] as Array).size() + (Game.catalog.files["furniture"] as Array).size() + 1)
	for view: ModelPreview in views:
		var lit: int = 0
		for node: Node in view.find_children("*", "GeometryInstance3D", true, false):
			var geometry: GeometryInstance3D = node
			var material: ShaderMaterial = geometry.material_override as ShaderMaterial
			assert_not_null(material, "%s: %s tiene material" % [view.name, geometry.name])
			if material == null or material.shader not in WorldPalette.STUDIO_LIT_SHADERS:
				continue
			lit += 1
			assert_eq(material.get_shader_parameter(PREVIEW_LIGHT), 1.0, "%s lleva la luz de estudio" % geometry.get_path())
		assert_gt(lit, 0, "La vista tiene mallas del kit")
	# Lo mismo armado en el mundo sigue con la luz del cuarto.
	var room: Node3D = Node3D.new()
	add_child_autofree(room)
	PrinterModel.build(room, "Printer", "cubo_uno")
	FurnitureModel.build(room, "Furniture", "estanteria_metalica")
	CharacterModel.build(room, "Character")
	var checked: int = 0
	for node: Node in room.find_children("*", "GeometryInstance3D", true, false):
		var material: ShaderMaterial = (node as GeometryInstance3D).material_override as ShaderMaterial
		if material != null and material.shader in WorldPalette.STUDIO_LIT_SHADERS:
			checked += 1
			assert_ne(material.get_shader_parameter(PREVIEW_LIGHT), 1.0, "%s: el mundo no cambia" % node.name)
	assert_gt(checked, 3)


func test_the_view_copy_keeps_everything_else_of_the_material() -> void:
	var sources: Array[Material] = [
		WorldPalette.kit(), WorldPalette.solid("e0453a"), WorldPalette.glass("f28c28", 0.55),
		WorldPalette.paint(WorldPalette.WOOD_MID, WorldPalette.Surface.WOOD, 0.15),
		WorldPalette.kit_character(), WorldPalette.kit_head(),
	]
	for source: Material in sources:
		var copy: ShaderMaterial = WorldPalette.preview_of(source)
		assert_ne(copy, source, "Una copia: el mundo sigue igual")
		assert_eq(WorldPalette.preview_of(source), copy, "En caché")
		assert_eq(copy.shader, (source as ShaderMaterial).shader)
		for uniform: Dictionary in copy.shader.get_shader_uniform_list():
			var parameter: StringName = uniform["name"]
			if parameter != PREVIEW_LIGHT:
				assert_eq(copy.get_shader_parameter(parameter), (source as ShaderMaterial).get_shader_parameter(parameter), "%s: %s" % [source, parameter])
	for other: Material in [WorldPalette.glow("ffffff", "printer_display"), WorldPalette.outline_character(), null]:
		assert_eq(WorldPalette.preview_of(other), other, "Lo que no usa la luz del cuarto queda igual")


func test_a_view_is_drawn_at_the_resolution_of_the_world() -> void:
	var view: ModelPreview = _add(Previews.printer("cubo_uno"))
	var sub: SubViewport = view.get_node("View/SubViewport")
	var container: SubViewportContainer = view.get_node("View")
	assert_eq(sub.msaa_3d, Viewport.MSAA_4X, "Bordes suavizados")
	for level: int in 2:
		_quality.set_mode(GraphicsQuality.Mode.HIGH if level == 0 else GraphicsQuality.Mode.LOW)
		for window: Array in WINDOWS:
			# Como si ya se hubiera dibujado: al cambiar de tamaño se dibuja otra vez.
			sub.render_target_update_mode = SubViewport.UPDATE_DISABLED
			get_tree().root.size = Vector2i(window[0], window[1])
			await wait_process_frames(1)
			var k: float = window[2 + level]
			var label: String = "%dx%d %s" % [window[0], window[1], "Alta" if level == 0 else "Baja"]
			assert_almost_eq(view.view_scale(), k, 0.001, label)
			assert_almost_eq(view.view_scale(), WorldViewport.scale_in(get_viewport(), GraphicsQuality.current.max_width()), 0.0001, "La misma k que el mundo")
			assert_eq(sub.size, Vector2i((view.size * k).ceil()), label + ": el dibujo mide la vista × k")
			assert_almost_eq(container.size.x * container.scale.x, view.size.x, 1.0, label + ": y se ve del tamaño de la vista")
			assert_eq(sub.render_target_update_mode, SubViewport.UPDATE_ONCE, label + ": se vuelve a dibujar")


func test_a_view_out_of_the_tree_fits_again_when_it_comes_back() -> void:
	get_tree().root.size = Vector2i(720, 1280)
	var tile: Control = Previews.furniture("mesa_auxiliar")
	var view: ModelPreview = _add(tile)
	await wait_process_frames(1)
	# Un panel que se saca del árbol mientras cambian la pantalla y la calidad:
	# no se toca (sin errores: tools/run_tests.sh los busca).
	_shelf.remove_child(tile)
	get_tree().root.size = Vector2i(1080, 1920)
	_quality.set_mode(GraphicsQuality.Mode.LOW)
	_quality.set_mode(GraphicsQuality.Mode.HIGH)
	await wait_process_frames(1)
	assert_almost_eq(view.view_scale(), 1.0, 0.001, "Fuera del árbol no se ajusta")
	_shelf.add_child(tile)
	await wait_process_frames(1)
	assert_almost_eq(view.view_scale(), 1.5, 0.001, "Al volver, sigue a la pantalla de ahora")
	get_tree().root.size = Vector2i(720, 1280)
	await wait_process_frames(1)
	assert_almost_eq(view.view_scale(), 1.0, 0.001, "Y a los cambios que vengan")


func test_the_camera_tilts_like_the_world_and_frames_the_whole_model() -> void:
	var views: Array[ModelPreview] = []
	for printer: Dictionary in Game.catalog.files["printers"]:
		views.append(_add(Previews.printer(printer["id"])))
	for furniture: Dictionary in Game.catalog.files["furniture"]:
		views.append(_add(Previews.furniture(furniture["id"])))
	await wait_process_frames(1)
	for view: ModelPreview in views:
		var camera: Camera3D = view.find_children("*", "Camera3D", true, false)[0]
		assert_almost_eq(camera.rotation_degrees.x, CameraRig.PITCH, 0.01, "La inclinación del mundo")
		var half: float = camera.size / 2.0
		var reach: Vector2 = Vector2.ZERO
		for node: Node in view.find_children("*", "MeshInstance3D", true, false):
			var mesh: MeshInstance3D = node
			var box: AABB = mesh.get_aabb()
			for i: int in 8:
				var corner: Vector3 = camera.global_transform.affine_inverse() * (mesh.global_transform * box.get_endpoint(i))
				reach = Vector2(maxf(reach.x, absf(corner.x)), maxf(reach.y, absf(corner.y)))
		assert_lt(maxf(reach.x, reach.y), half, "%s entra entero" % camera.get_path())
		assert_gt(maxf(reach.x, reach.y), half * 0.85, "%s llena la vista" % camera.get_path())


func test_a_light_disc_goes_behind_every_view() -> void:
	var disc: GradientTexture2D = ModelPreview.disc()
	assert_eq(ModelPreview.disc(), disc, "Uno para todas")
	assert_eq(disc.fill, GradientTexture2D.FILL_RADIAL)
	assert_eq(disc.fill_from, Vector2(0.5, 0.5), "Centrado")
	var center: Color = disc.gradient.sample(0.0)
	assert_eq(Color(center, 1.0), UiPalette.PREVIEW_DISC, "Del azul del disco")
	assert_eq(center.a, 1.0)
	assert_eq(disc.gradient.sample(1.0).a, 0.0, "Transparente en el borde")


## Agrega una vista de la tienda (Previews: la vista dentro de su marco) y
## devuelve la vista.
func _add(tile: Control) -> ModelPreview:
	_shelf.add_child(tile)
	return tile.get_child(0) as ModelPreview

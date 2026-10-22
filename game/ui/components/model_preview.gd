class_name ModelPreview
extends SubViewportContainer
## Vista de un modelo 3D dentro de la interfaz (retrato del personaje,
## impresoras y muebles de la tienda), con bordes suavizados. Se dibuja una
## sola vez.
## Con camera_size = 0 la cámara se ajusta sola al tamaño del modelo.

## Color y fuerza del sol de la vista (sobre el ambiente de la mañana del
## mundo): el del sol de la mañana, un poco más fuerte.
const LIGHT_COLOR: String = "fff0dc"
const LIGHT_ENERGY: float = 0.5

## Recibe el nodo raíz del mundo del retrato y arma el modelo dentro.
var _build_model: Callable
var _camera_size: float
var _camera_target: Vector3
var _yaw: float


func _init(build_model: Callable, size: float, camera_size: float = 0.0, camera_target: Vector3 = Vector3.ZERO, yaw: float = 45.0) -> void:
	_build_model = build_model
	_camera_size = camera_size
	_camera_target = camera_target
	_yaw = yaw
	custom_minimum_size = Vector2(size, size)
	stretch = true
	stretch_shrink = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_4X
	# Sin luces de punto ni de foco: no hace falta su mapa de sombras.
	viewport.positional_shadow_atlas_size = 0
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var world: Node3D = Node3D.new()
	viewport.add_child(world)

	# Como el mundo (biblia de arte §2.4 y §11): el ambiente lo pone el
	# sombreador del kit, tonemap lineal y un sol con sombra, para que valga
	# la misma cuenta de color.
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = environment
	world.add_child(world_environment)
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40.0, 20.0, 0.0)
	light.light_color = Color(LIGHT_COLOR)
	light.light_energy = LIGHT_ENERGY
	light.shadow_enabled = true
	world.add_child(light)

	_build_model.call(world)
	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.rotation_degrees = Vector3(-20.0, _yaw, 0.0)
	var target: Vector3 = _camera_target
	if _camera_size > 0.0:
		camera.size = _camera_size
	else:
		var bounds: AABB = _bounds(world)
		target = bounds.get_center()
		# Un mínimo por si el modelo no tiene mallas.
		camera.size = maxf(bounds.get_longest_axis_size() * 1.3, 0.5)
	camera.position = target - camera.basis * Vector3.FORWARD * 10.0
	world.add_child(camera)


func _bounds(root: Node3D) -> AABB:
	var bounds: AABB = AABB()
	var first: bool = true
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node
		var box: AABB = mesh_instance.global_transform * mesh_instance.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return bounds

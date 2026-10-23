class_name ModelPreview
extends Control
## Vista de un modelo 3D dentro de la interfaz (biblia de arte §11 y §7.9):
## las impresoras y los muebles de la tienda, del inventario y de los
## paneles, y los retratos del personaje. Se dibuja una sola vez (redraw()
## la vuelve a dibujar, por ejemplo cuando el retrato cambia de cara).
##
## - Resolución como la del mundo (WorldViewport): se dibuja a k píxeles por
##   píxel de la interfaz (el ancho físico de la pantalla hasta el tope del
##   nivel de calidad, entre el ancho de la interfaz) y se ve del tamaño de la
##   vista. En un teléfono de 1080 px, un píxel del modelo es un píxel de la
##   pantalla. Bordes suavizados con MSAA 4× (se dibuja una vez: no cuesta).
##   El dibujo sale premultiplicado y se pone así sobre la tarjeta
##   (PREMULTIPLIED; si no, el borde suavizado queda oscuro).
## - Luz de estudio: cada malla lleva la versión de vista previa de su
##   material (WorldPalette.preview_of, preview_light = 1), así ni la hora, ni
##   las lámparas, ni dónde está el personaje cambian cómo se ve. Su sol da
##   sombra o no como el del mundo (GraphicsQuality): así vale la misma cuenta
##   de color (cc_sun_shadowed es un global de todos los sombreadores). Y la
##   da como el del mundo: una sola sombra ortogonal (usa las mismas variantes
##   de los sombreadores del kit que el cuarto).
## - Se vuelve a dibujar cuando ColorProbe termina de medir
##   (Events.color_model_changed): la primera vez se dibuja antes.
## - Detrás, en 2D, un disco de luz (UiPalette.PREVIEW_DISC → transparente)
##   para que lo oscuro se lea sobre el azul de la tarjeta.
## - Cámara ortográfica con la inclinación del mundo (los retratos pueden
##   pedir otra: de frente la cara se lee mejor). Con camera_size = 0 se
##   ajusta sola: el modelo entero, visto desde la cámara, llena la vista.
##
## El contorno del personaje recibe "px_m_override" (los metros por píxel de
## esta vista): mide los mismos píxeles que en el mundo.

## Color y fuerza del sol de la vista: el de la mañana del mundo, un poco
## más fuerte.
const LIGHT_COLOR: String = "fff0dc"
const LIGHT_ENERGY: float = 0.5
const LIGHT_ROTATION: Vector3 = Vector3(-40.0, 20.0, 0.0)
## Inclinación de la cámara (grados), si no se pide otra: la del mundo.
const PITCH: float = CameraRig.PITCH
## Ajuste solo: el modelo visto desde la cámara ocupa 1/FIT_MARGIN de la
## vista (un poco de aire alrededor). Lo más chico que se muestra (m).
const FIT_MARGIN: float = 1.08
const MIN_FRAME: float = 0.5
## El disco de luz: tamaño de su textura (px) y cómo se apaga del centro al
## borde (posición, alfa).
const DISC_TEXELS: int = 128
const DISC_FADE: Array[Vector2] = [Vector2(0.0, 1.0), Vector2(0.5, 0.7), Vector2(1.0, 0.0)]
## La cámara está a esta distancia (m) del centro del modelo y ve hasta el
## doble: con cámara ortográfica la sombra del sol cubre de near a far, así
## que un far corto le da detalle.
const CAMERA_DISTANCE: float = 10.0
## Cómo se pone el dibujo sobre la tarjeta (ver arriba).
const PREMULTIPLIED: Shader = preload("res://game/ui/components/preview_premultiplied.gdshader")

static var _disc: GradientTexture2D
static var _premultiplied: ShaderMaterial

## El material de PREMULTIPLIED (uno para todas las vistas).
static func premultiplied() -> ShaderMaterial:
	if _premultiplied == null:
		_premultiplied = ShaderMaterial.new()
		_premultiplied.shader = PREMULTIPLIED
	return _premultiplied


## Recibe el nodo raíz del mundo de la vista y arma el modelo dentro.
var _build_model: Callable
var _camera_size: float
var _camera_target: Vector3
var _yaw: float
var _pitch: float
var _container: SubViewportContainer
var _viewport: SubViewport
var _light: DirectionalLight3D
var _camera: Camera3D
var _world: Node3D
## Píxeles del dibujo por píxel de la interfaz (k).
var _scale: float = 1.0


func _init(build_model: Callable, size: float, camera_size: float = 0.0, camera_target: Vector3 = Vector3.ZERO, yaw: float = 45.0, pitch: float = PITCH) -> void:
	_build_model = build_model
	_camera_size = camera_size
	_camera_target = camera_target
	_yaw = yaw
	_pitch = pitch
	custom_minimum_size = Vector2(size, size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## El disco de luz que va detrás de cada vista (uno para todas).
static func disc() -> GradientTexture2D:
	if _disc == null:
		var gradient: Gradient = Gradient.new()
		var offsets: PackedFloat32Array = PackedFloat32Array()
		var colors: PackedColorArray = PackedColorArray()
		for point: Vector2 in DISC_FADE:
			offsets.append(point.x)
			colors.append(Color(UiPalette.PREVIEW_DISC, point.y))
		gradient.offsets = offsets
		gradient.colors = colors
		_disc = GradientTexture2D.new()
		_disc.gradient = gradient
		_disc.fill = GradientTexture2D.FILL_RADIAL
		_disc.fill_from = Vector2(0.5, 0.5)
		_disc.fill_to = Vector2(1.0, 0.5)
		_disc.width = DISC_TEXELS
		_disc.height = DISC_TEXELS
	return _disc


func _ready() -> void:
	# El contenedor no lo acomoda nadie: _fit() le pone el tamaño (la vista ×
	# k) y la escala (1/k), como al mundo.
	_container = SubViewportContainer.new()
	_container.name = "View"
	_container.stretch = true
	_container.stretch_shrink = 1
	_container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_container.material = premultiplied()
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)
	_viewport = SubViewport.new()
	_viewport.name = "SubViewport"
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	# Sin luces de punto ni de foco: no hace falta su mapa de sombras.
	_viewport.positional_shadow_atlas_size = 0
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_container.add_child(_viewport)
	_world = Node3D.new()
	_viewport.add_child(_world)

	# Como el mundo (biblia de arte §2.4): el ambiente lo pone el sombreador
	# del kit (aquí, la luz de estudio), tonemap lineal y un sol.
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = environment
	_world.add_child(world_environment)
	_light = DirectionalLight3D.new()
	_light.rotation_degrees = LIGHT_ROTATION
	_light.light_color = Color(LIGHT_COLOR)
	_light.light_energy = LIGHT_ENERGY
	_light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_light.shadow_enabled = GraphicsQuality.current.sun_shadow()
	_world.add_child(_light)

	_build_model.call(_world)
	for node: Node in _world.find_children("*", "GeometryInstance3D", true, false):
		var geometry: GeometryInstance3D = node
		geometry.material_override = WorldPalette.preview_of(geometry.material_override)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.rotation_degrees = Vector3(_pitch, _yaw, 0.0)
	var target: Vector3 = _camera_target
	if _camera_size > 0.0:
		_camera.size = _camera_size
	else:
		# Lo que ocupan las mallas vistas desde la cámara (a lo ancho y a lo
		# alto de la vista): su centro queda al centro y lo más largo, con un
		# poco de aire, es el ancho de la vista.
		var seen: Rect2 = _seen_from(_camera.basis)
		target = _camera.basis.x * seen.get_center().x + _camera.basis.y * seen.get_center().y
		_camera.size = maxf(maxf(seen.size.x, seen.size.y) * FIT_MARGIN, MIN_FRAME)
	_camera.position = target - _camera.basis * Vector3.FORWARD * CAMERA_DISTANCE
	_camera.far = CAMERA_DISTANCE * 2.0
	_world.add_child(_camera)

	GraphicsQuality.current.changed.connect(_on_quality_changed)
	Events.color_model_changed.connect(redraw)
	resized.connect(_fit)
	get_viewport().size_changed.connect(_fit)
	_fit()


## Si vuelve al árbol (un panel que se saca y se vuelve a poner): sigue a la
## pantalla otra vez.
func _enter_tree() -> void:
	if _container != null:
		get_viewport().size_changed.connect(_fit)
		_fit()


func _exit_tree() -> void:
	if get_viewport().size_changed.is_connected(_fit):
		get_viewport().size_changed.disconnect(_fit)


func _draw() -> void:
	draw_texture_rect(disc(), Rect2(Vector2.ZERO, size), false)


## Vuelve a dibujar la vista una vez (el retrato cuando cambia la cara).
func redraw() -> void:
	if _viewport != null:
		_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## Píxeles del dibujo por píxel de la interfaz (k).
func view_scale() -> float:
	return _scale


## Tamaño del dibujo (k) para el tamaño de ahora y la pantalla de ahora.
func _fit() -> void:
	if not is_inside_tree() or size.x <= 0.0 or size.y <= 0.0:
		return
	_scale = WorldViewport.scale_in(get_viewport(), GraphicsQuality.current.max_width())
	_container.position = Vector2.ZERO
	_container.scale = Vector2.ONE / _scale
	_container.size = (size * _scale).ceil()
	var meters_per_pixel: float = _camera.size / maxf(_container.size.y, 1.0)
	for node: Node in _world.find_children("*", "GeometryInstance3D", true, false):
		var geometry: GeometryInstance3D = node
		if geometry.material_override == WorldPalette.outline_character():
			geometry.set_instance_shader_parameter(&"px_m_override", meters_per_pixel)
	redraw()


## El nivel de calidad cambió: el sol con o sin sombra, como el del mundo, y
## el tope del ancho.
func _on_quality_changed() -> void:
	_light.shadow_enabled = GraphicsQuality.current.sun_shadow()
	_fit()


## Lo que ocupan las cajas de las mallas del modelo vistas por una cámara
## ortográfica con `basis`: x a lo ancho de la vista e y a lo alto (m).
func _seen_from(basis: Basis) -> Rect2:
	var low: Vector2 = Vector2.INF
	var high: Vector2 = -Vector2.INF
	for node: Node in _world.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node
		var box: AABB = mesh_instance.get_aabb()
		for i: int in 8:
			var corner: Vector3 = mesh_instance.global_transform * box.get_endpoint(i)
			var seen: Vector2 = Vector2(corner.dot(basis.x), corner.dot(basis.y))
			low = low.min(seen)
			high = high.max(seen)
	if low.x > high.x:
		return Rect2()
	return Rect2(low, high - low)

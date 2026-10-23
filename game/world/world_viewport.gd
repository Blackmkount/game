class_name WorldViewport
extends SubViewportContainer
## Vista del mundo 3D (Main/WorldView). El mundo se dibuja a resolución alta,
## con los bordes suavizados (MSAA) y con un ancho interno que no depende del
## teléfono: el ancho físico de la pantalla, hasta un tope.
##
## La interfaz mide 720 de ancho (la pantalla virtual del proyecto). Con
## k = ancho interno / ancho de la interfaz, este contenedor mide la pantalla
## × k y se dibuja con escala 1/k: el SubViewport tiene exactamente el ancho
## interno en píxeles y se ve del tamaño de la pantalla. En un teléfono de
## 1080 px un píxel del mundo es un píxel físico; en uno de 1440 se dibuja a
## 1080 y se estira con filtro lineal.
##
## Las cuentas entre la interfaz y el dibujo del mundo pasan por view_per_ui
## (k), ui_to_view() y view_to_ui().
##
## El tope del ancho y el suavizado salen del nivel de calidad gráfica
## (GraphicsQuality, biblia §2.2: Alta 1080 px y MSAA 4×, Baja 720 px y
## 2×); si cambia, se vuelve a ajustar. Mientras el modo automático mide los
## primeros cuadros, este nodo le pasa cuánto dura cada uno.

## Píxeles del dibujo del mundo por cada píxel de la interfaz (k).
var view_per_ui: float = 1.0
## Si hay pantalla: sin ella (pruebas y herramientas sin ventana) no hay
## cuadros de verdad que medir para el modo automático.
var has_screen: bool = DisplayServer.get_name() != "headless"

var _view: SubViewport
var _quality: GraphicsQuality


func _init() -> void:
	stretch = true
	stretch_shrink = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _ready() -> void:
	_view = get_node("SubViewport")
	# Solo hay un sol: ninguna luz de punto ni de foco necesita sombras.
	_view.positional_shadow_atlas_size = 0
	# El tamaño lo pone _fit(), no los anclajes.
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_quality = GraphicsQuality.current
	_quality.changed.connect(_apply_quality)
	var parent: Control = get_parent() as Control
	if parent != null:
		parent.resized.connect(_fit)
	# La pantalla física puede cambiar sin que cambie la virtual.
	get_viewport().size_changed.connect(_fit)
	_apply_quality()


## Mientras el automático mide: la duración de cada cuadro de verdad.
func _process(delta: float) -> void:
	_quality.add_frame(delta)
	if not _quality.is_measuring():
		set_process(false)


## k para una pantalla de `physical_width` píxeles físicos y `ui_width` de
## interfaz: el ancho interno es el físico, sin pasar de `max_width`.
static func scale_for(physical_width: float, ui_width: float, max_width: float) -> float:
	if physical_width <= 0.0 or ui_width <= 0.0:
		return 1.0
	return minf(physical_width, max_width) / ui_width


## k para lo 3D que se dibuja dentro de la interfaz de `viewport` (las vistas
## de la tienda y los retratos, ModelPreview): la misma cuenta que el mundo,
## con el ancho de su pantalla y el tope `max_width`.
static func scale_in(viewport: Viewport, max_width: float) -> float:
	var ui_width: float = viewport.get_visible_rect().size.x
	return scale_for(ui_width * viewport.get_final_transform().get_scale().x, ui_width, max_width)


## Punto de la interfaz (coordenadas globales del lienzo) → píxel del dibujo.
func ui_to_view(ui_point: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * ui_point


## Píxel del dibujo → punto de la interfaz (coordenadas globales del lienzo).
func view_to_ui(view_point: Vector2) -> Vector2:
	return get_global_transform() * view_point


## El nivel de calidad: el suavizado (el SubViewport no hereda el del
## proyecto) y el tope del ancho; y, si el automático mide, los cuadros.
func _apply_quality() -> void:
	_view.msaa_3d = _quality.msaa()
	_fit()
	set_process(_quality.is_measuring() and has_screen)


## Tamaño y escala según la pantalla de ahora.
func _fit() -> void:
	var parent: Control = get_parent() as Control
	var ui_size: Vector2 = parent.size if parent != null else get_viewport_rect().size
	if ui_size.x <= 0.0 or ui_size.y <= 0.0:
		return
	var physical_width: float = ui_size.x * get_viewport().get_final_transform().get_scale().x
	view_per_ui = scale_for(physical_width, ui_size.x, _quality.max_width())
	position = Vector2.ZERO
	scale = Vector2.ONE / view_per_ui
	size = (ui_size * view_per_ui).ceil()

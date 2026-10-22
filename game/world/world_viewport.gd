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

## Tope del ancho interno (píxeles) y suavizado de bordes del nivel de calidad
## Alto (biblia de arte §2.2). Los niveles de calidad llegan más adelante.
const MAX_WIDTH_HIGH: float = 1080.0
const MSAA_HIGH: Viewport.MSAA = Viewport.MSAA_4X

## Píxeles del dibujo del mundo por cada píxel de la interfaz (k).
var view_per_ui: float = 1.0

var _view: SubViewport


func _init() -> void:
	stretch = true
	stretch_shrink = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _ready() -> void:
	_view = get_node("SubViewport")
	# El SubViewport no hereda el suavizado del proyecto.
	_view.msaa_3d = MSAA_HIGH
	# Solo hay un sol: ninguna luz de punto ni de foco necesita sombras.
	_view.positional_shadow_atlas_size = 0
	# El tamaño lo pone _fit(), no los anclajes.
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	var parent: Control = get_parent() as Control
	if parent != null:
		parent.resized.connect(_fit)
	# La pantalla física puede cambiar sin que cambie la virtual.
	get_viewport().size_changed.connect(_fit)
	_fit()


## k para una pantalla de `physical_width` píxeles físicos y `ui_width` de
## interfaz: el ancho interno es el físico, sin pasar de `max_width`.
static func scale_for(physical_width: float, ui_width: float, max_width: float) -> float:
	if physical_width <= 0.0 or ui_width <= 0.0:
		return 1.0
	return minf(physical_width, max_width) / ui_width


## Punto de la interfaz (coordenadas globales del lienzo) → píxel del dibujo.
func ui_to_view(ui_point: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * ui_point


## Píxel del dibujo → punto de la interfaz (coordenadas globales del lienzo).
func view_to_ui(view_point: Vector2) -> Vector2:
	return get_global_transform() * view_point


## Tamaño y escala según la pantalla de ahora.
func _fit() -> void:
	var parent: Control = get_parent() as Control
	var ui_size: Vector2 = parent.size if parent != null else get_viewport_rect().size
	if ui_size.x <= 0.0 or ui_size.y <= 0.0:
		return
	var physical_width: float = ui_size.x * get_viewport().get_final_transform().get_scale().x
	view_per_ui = scale_for(physical_width, ui_size.x, MAX_WIDTH_HIGH)
	position = Vector2.ZERO
	scale = Vector2.ONE / view_per_ui
	size = (ui_size * view_per_ui).ceil()

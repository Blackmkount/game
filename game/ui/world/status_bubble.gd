class_name StatusBubble
extends PanelContainer
## Burbuja de estado sobre un objeto del mundo: un icono de color (lista,
## falló, modelando...) y, a veces, un texto corto (cuánto falta, piezas).
## Usa el panel oscuro del HUD: el papel claro es solo para lo que dice el
## personaje (docs/ESTILO.md). No recibe toques; StatusBubbles.hit() revisa
## si un toque le dio.

const SIZE: float = 72.0
## Lado mínimo del cuadro que acepta toques, centrado en la burbuja.
const HIT_SIZE: float = 88.0
const ICON_SIZE: float = 36.0
## Latido de lo que espera al jugador (pieza lista, falla): el icono se
## aclara y vuelve (self_modulate). Agrandar la burbuja la obligaba a
## dibujarse de nuevo en cada cuadro (el borde y el brillo de PillPanel se
## arman otra vez: memoria nueva por cuadro); el color no.
const PULSE_BRIGHTNESS: float = 1.6
const PULSE_TIME: float = 0.5

var _icon: TextureRect
var _label: Label
var _icon_name: String = ""
var _text: String = ""
var _color: Color = Color.WHITE
var _pulse: bool = false
var _pulse_tween: Tween


func _init() -> void:
	theme_type_variation = "PillPanel"
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var column: VBoxContainer = UiKit.vbox(0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	# Los contenedores dejan pasar el toque a sus padres del HUD: así nunca
	# llegaría a WorldControls, que es el que revisa la burbuja.
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	_icon = UiKit.icon("printer", ICON_SIZE)
	_icon.name = "Icon"
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_icon)
	_label = UiKit.label("", "SmallLabel")
	_label.add_theme_color_override("font_color", UiPalette.TEXT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.visible = false
	column.add_child(_label)


## Cambia lo que muestra. Si es lo mismo que ya muestra, no hace nada.
func set_state(icon_name: String, text: String, color: Color, pulse: bool) -> void:
	if icon_name == _icon_name and text == _text and color == _color and pulse == _pulse:
		return
	if icon_name != _icon_name:
		_icon.texture = UiKit.icon_texture(icon_name)
		_icon_name = icon_name
	_icon.modulate = color
	_color = color
	_label.text = text
	_label.visible = not text.is_empty()
	_text = text
	# Sin texto (o con uno más corto) vuelve a su tamaño.
	reset_size()
	_set_pulse(pulse)


## Cuadro que acepta toques, en coordenadas globales: al menos HIT_SIZE de
## lado y centrado en la burbuja, para que sea fácil de tocar con el pulgar.
func hit_rect() -> Rect2:
	var rect: Rect2 = get_global_rect()
	var side: Vector2 = rect.size.max(Vector2(HIT_SIZE, HIT_SIZE))
	return Rect2(rect.get_center() - side / 2.0, side)


func _set_pulse(pulse: bool) -> void:
	if pulse == _pulse:
		return
	_pulse = pulse
	if _pulse_tween != null:
		_pulse_tween.kill()
		_pulse_tween = null
	_icon.self_modulate = Color.WHITE
	if pulse:
		_pulse_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_pulse_tween.tween_property(_icon, "self_modulate", Color.WHITE * PULSE_BRIGHTNESS, PULSE_TIME)
		_pulse_tween.tween_property(_icon, "self_modulate", Color.WHITE, PULSE_TIME)

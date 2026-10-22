class_name FeedbackLayer
extends Control
## Capa sobre las pantallas para celebrar lo que pasa: textos que vuelan hacia
## el HUD ("+$6" hacia el dinero, "+5 XP" hacia la barra) y avisos cortos
## bajo la barra de arriba (el agradecimiento del cliente). No recibe toques.
##
## Los textos que vuelan salen de un grupo fijo de etiquetas creadas una vez;
## después solo se crean las animaciones.

## Cuántos textos pueden volar a la vez. Si llega uno más, reemplaza al más
## viejo.
const FLOAT_COUNT: int = 6
const FLOAT_FONT_SIZE: int = 34
## Lo que dura un aviso en pantalla, contando cuando aparece y se va.
const TOAST_SECONDS: float = 2.2
const TOAST_FADE_SECONDS: float = 0.2
## Avisos que esperan su turno mientras se ve otro. Si llegan más, se
## descarta el más viejo.
const MAX_WAITING_TOASTS: int = 2

var _floats: Array[Label] = []
var _float_tweens: Array[Tween] = []
var _next_float: int = 0
var _toast: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _waiting_toasts: Array[Dictionary] = []
## Esquina de arriba a la izquierda donde va el aviso (la pone el HUD para no
## tapar lo que acaba de cambiar). Sin ella, va bajo la barra de arriba.
var toast_spot: Callable = Callable()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index: int in FLOAT_COUNT:
		var label: Label = UiKit.label("", "HintLabel")
		label.name = "Float%d" % index
		label.add_theme_font_size_override("font_size", FLOAT_FONT_SIZE)
		label.visible = false
		add_child(label)
		_floats.append(label)
	_float_tweens.resize(FLOAT_COUNT)
	# El aviso va debajo de los textos que vuelan: "+$6" pasa por encima.
	_toast = UiKit.panel("PillPanel")
	_toast.name = "Toast"
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_left = Hud.MARGIN
	_toast.offset_right = -Hud.MARGIN
	_toast.offset_top = Hud.CONTENT_TOP
	_toast.visible = false
	_toast_label = UiKit.label("", "BoldLabel", true)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_child(_toast_label)
	add_child(_toast)
	move_child(_toast, 0)


## Hace volar `text` desde `from_ui` hasta `to_ui` (centros, en coordenadas de
## la interfaz) en `duration` segundos, y llama a `on_done` al llegar.
func fly(text: String, color: Color, from_ui: Vector2, to_ui: Vector2, duration: float = 0.8, on_done: Callable = Callable()) -> void:
	var index: int = _next_float
	_next_float = (_next_float + 1) % FLOAT_COUNT
	if _float_tweens[index] != null:
		_float_tweens[index].kill()
	var label: Label = _floats[index]
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.reset_size()
	var half: Vector2 = label.size / 2.0
	label.position = from_ui - half
	label.visible = true
	var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(label, "position", to_ui - half, duration)
	tween.tween_callback(_land.bind(index, on_done))
	_float_tweens[index] = tween


## Aviso corto arriba, donde no tape el HUD. Si ya se ve otro, espera su turno.
func toast(text: String, color: Color = UiPalette.TEXT) -> void:
	if _toast.visible:
		_waiting_toasts.append({"text": text, "color": color})
		if _waiting_toasts.size() > MAX_WAITING_TOASTS:
			_waiting_toasts.pop_front()
		return
	_show_toast(text, color)


func _land(index: int, on_done: Callable) -> void:
	_floats[index].visible = false
	_float_tweens[index] = null
	if on_done.is_valid():
		on_done.call()


func _show_toast(text: String, color: Color) -> void:
	var spot: Vector2 = toast_spot.call() if toast_spot.is_valid() else Vector2(Hud.MARGIN, Hud.CONTENT_TOP)
	_toast.offset_left = spot.x
	_toast.offset_top = spot.y
	_toast.offset_bottom = spot.y
	_toast_label.text = text
	_toast_label.add_theme_color_override("font_color", color)
	_toast.visible = true
	_toast.modulate.a = 0.0
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, TOAST_FADE_SECONDS)
	_toast_tween.tween_interval(TOAST_SECONDS - 2.0 * TOAST_FADE_SECONDS)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, TOAST_FADE_SECONDS)
	_toast_tween.tween_callback(_next_toast)


func _next_toast() -> void:
	_toast.visible = false
	if _waiting_toasts.is_empty():
		return
	var next: Dictionary = _waiting_toasts.pop_front()
	_show_toast(next["text"], next["color"])

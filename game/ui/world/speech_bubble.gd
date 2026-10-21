class_name SpeechBubble
extends PanelContainer
## Globo de diálogo sobre la cabeza del personaje, con una frase graciosa al
## tocarlo. Desaparece solo después de unos segundos.

const MAX_WIDTH: float = 380.0
const DURATION: float = 2.8
## Distancia entre la cabeza y el globo.
const LIFT: float = 8.0

var _label: Label
var _hide_tween: Tween


func _ready() -> void:
	theme_type_variation = "BubblePanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = UiKit.label("", "BubbleLabel", true)
	_label.custom_minimum_size = Vector2(MAX_WIDTH - 40.0, 0.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	visible = false


func say(text: String) -> void:
	_label.text = text
	reset_size()
	visible = true
	modulate.a = 1.0
	if _hide_tween != null:
		_hide_tween.kill()
	_hide_tween = create_tween()
	_hide_tween.tween_interval(DURATION)
	_hide_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	_hide_tween.tween_callback(func() -> void: visible = false)


func is_talking() -> bool:
	return visible


func hush() -> void:
	if _hide_tween != null:
		_hide_tween.kill()
	visible = false

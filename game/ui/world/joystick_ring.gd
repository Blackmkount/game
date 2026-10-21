class_name JoystickRing
extends Control
## Dibujo del joystick flotante: un aro donde se apoyó el dedo y una perilla
## que lo sigue. Solo dibuja; los gestos los interpreta TouchTracker.

const KNOB_RADIUS: float = 30.0

var tuning: ControlsTuning = ControlsTuning.current
var _base: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO
var _active: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func show_at(base: Vector2, knob: Vector2) -> void:
	if _active and base == _base and knob == _knob:
		return
	_active = true
	_base = base
	_knob = knob
	queue_redraw()


func hide_stick() -> void:
	if not _active:
		return
	_active = false
	queue_redraw()


func is_shown() -> bool:
	return _active


func _draw() -> void:
	if not _active:
		return
	var radius: float = tuning.joystick_ring_px
	draw_circle(_base, radius, Color(UiPalette.PANEL, 0.35))
	draw_arc(_base, radius, 0.0, TAU, 48, Color(UiPalette.ACCENT, 0.55), 4.0, true)
	var knob: Vector2 = _base + (_knob - _base).limit_length(radius)
	draw_circle(knob, KNOB_RADIUS, Color(UiPalette.ACCENT, 0.6))
	draw_circle(knob, KNOB_RADIUS * 0.55, Color(UiPalette.TEXT, 0.55))

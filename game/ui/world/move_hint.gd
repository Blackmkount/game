class_name MoveHint
extends Control
## Pista para jugadores nuevos, en la zona del pulgar.
## - MOVE: un joystick fantasma que se mueve solo y "Arrastra el dedo para
##   caminar". Se quita al caminar un poco con el joystick.
## - TAP: "Toca un objeto para verlo". Se quita al abrir un panel.

enum Mode { NONE, MOVE, TAP }

## Altura del centro de la pista sobre el borde de abajo de la zona libre.
const LIFT: float = 230.0
const ORBIT: float = 40.0

var mode: Mode = Mode.NONE
var _label: Label
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_label = UiKit.label("", "HintLabel")
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	set_mode(Mode.MOVE)


func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	visible = mode != Mode.NONE
	set_process(visible)
	if mode == Mode.MOVE:
		_label.text = tr("HINT_MOVE")
	elif mode == Mode.TAP:
		_label.text = tr("HINT_TAP")
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _label != null:
		set_mode(mode)


func _process(delta: float) -> void:
	_time += delta
	var center: Vector2 = _center()
	_label.reset_size()
	_label.position = Vector2(center.x - _label.size.x / 2.0, center.y + ControlsTuning.current.joystick_ring_px * 0.6 + 16.0)
	queue_redraw()


func _draw() -> void:
	if mode != Mode.MOVE:
		return
	var center: Vector2 = _center()
	var ring: float = ControlsTuning.current.joystick_ring_px * 0.6
	var alpha: float = 0.45 + 0.2 * sin(_time * 3.0)
	draw_arc(center, ring, 0.0, TAU, 40, Color(UiPalette.ACCENT, alpha), 3.0, true)
	var knob: Vector2 = center + Vector2(cos(_time * 1.6), sin(_time * 1.6) * 0.6) * ORBIT
	draw_circle(knob, 22.0, Color(UiPalette.TEXT, alpha))


func _center() -> Vector2:
	var area: Vector2 = get_viewport_rect().size
	return Vector2(area.x / 2.0, area.y - Hud.NAV_HEIGHT - Hud.MARGIN - LIFT)

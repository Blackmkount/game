class_name MoveHint
extends Control
## Pista para jugadores nuevos, en la zona del pulgar.
## - MOVE: un joystick fantasma que se mueve solo y "Arrastra el dedo para
##   caminar". Se quita al caminar un poco con el joystick.
## - TAP: "Toca un objeto para verlo". Se quita al abrir un panel.
## Solo trabaja en cada cuadro mientras se ve el joystick fantasma.

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
	get_viewport().size_changed.connect(_place_label)
	set_mode(Mode.MOVE)


func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	visible = mode != Mode.NONE
	if mode == Mode.MOVE:
		_label.text = tr("HINT_MOVE")
	elif mode == Mode.TAP:
		_label.text = tr("HINT_TAP")
	_place_label()
	_update_processing()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _label != null:
		set_mode(mode)
	elif what == NOTIFICATION_VISIBILITY_CHANGED:
		_update_processing()


func _process(delta: float) -> void:
	_time += delta
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


func _update_processing() -> void:
	set_process(is_visible_in_tree() and mode == Mode.MOVE)


## El texto va debajo del joystick fantasma. Se acomoda al cambiar el texto o
## el tamaño de la pantalla, no en cada cuadro.
func _place_label() -> void:
	var center: Vector2 = _center()
	_label.reset_size()
	_label.position = Vector2(center.x - _label.size.x / 2.0, center.y + ControlsTuning.current.joystick_ring_px * 0.6 + 16.0)


func _center() -> Vector2:
	var area: Vector2 = get_viewport_rect().size
	return Vector2(area.x / 2.0, area.y - Hud.NAV_HEIGHT - Hud.MARGIN - LIFT)

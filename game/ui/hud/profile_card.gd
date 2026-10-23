class_name ProfileCard
extends PanelContainer
## Tarjeta superior izquierda: retrato del personaje, nivel y barra de
## experiencia hacia el siguiente nivel. Cuando se gana experiencia dentro del
## mismo nivel, la barra se llena de a poco.
##
## El retrato (biblia de arte §7.9) cambia de cara en los momentos
## importantes: feliz al cobrar a tiempo, preocupado cuando falla una
## impresión, sorpresa y después feliz al subir de nivel, por lo mismo que
## el personaje del cuarto (CharacterFace). Se vuelve a dibujar solo
## entonces.
##
## Cinco toques seguidos sobre la tarjeta piden el panel de depuración
## (PerfOverlay): así se abre también en el teléfono.

## Se tocó la tarjeta DEBUG_TAPS veces seguidas.
signal debug_requested

const XP_FILL_TIME: float = 0.4
## Toques seguidos que piden el panel de depuración, todos dentro de esta
## ventana de tiempo (ms).
const DEBUG_TAPS: int = 5
const DEBUG_TAP_WINDOW_MSEC: int = 2500
## Retrato: lado de la vista (px), ancho que muestra (m), punto que queda al
## centro (la cabeza), giro e inclinación (grados). Más de frente que el
## mundo (−30°): así la cara no queda bajo el flequillo.
const PORTRAIT_SIZE: float = 76.0
const PORTRAIT_FRAME: float = 0.62
const PORTRAIT_TARGET: Vector3 = Vector3(0.0, 1.15, 0.0)
const PORTRAIT_YAW: float = 20.0
const PORTRAIT_PITCH: float = -20.0

var _level_label: Label
var _xp_bar: ProgressBar
var _xp_label: Label
## Nivel que muestra la barra; 0 antes de la primera vez.
var _shown_level: int = 0
var _xp_tween: Tween
var _portrait: ModelPreview
var _character: Node3D
## Cuánto falta para volver a la cara normal, y la cara que sigue después
## de la que se ve (con su tiempo), si hay una.
var _face_timer: Timer
var _next_face: FacePainter.Face = FacePainter.Face.NEUTRAL
var _next_face_time: float = 0.0
var _shown_face: FacePainter.Face = FacePainter.Face.NEUTRAL
## Toques seguidos y cuándo empezó la serie (ms desde que arrancó el juego).
var _taps: int = 0
var _taps_started: int = 0


func _ready() -> void:
	var row: HBoxContainer = UiKit.hbox(12)
	# Los toques llegan a la tarjeta, no a lo que tiene adentro.
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	var frame: PanelContainer = UiKit.panel("IconTile")
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.custom_minimum_size = Vector2(84, 84)
	_portrait = ModelPreview.new(func(world: Node3D) -> void: _character = CharacterModel.build(world, "Character"), PORTRAIT_SIZE, PORTRAIT_FRAME, PORTRAIT_TARGET, PORTRAIT_YAW, PORTRAIT_PITCH)
	frame.add_child(_portrait)
	row.add_child(frame)
	_face_timer = Timer.new()
	_face_timer.one_shot = true
	_face_timer.timeout.connect(_on_face_timeout)
	add_child(_face_timer)
	Events.order_delivered.connect(_on_order_delivered)
	Events.print_failed.connect(_on_print_failed)
	Events.level_up.connect(_on_level_up)
	var info: VBoxContainer = UiKit.vbox(4)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)
	_level_label = UiKit.label("", "BoldLabel")
	_level_label.add_theme_font_size_override("font_size", 28)
	info.add_child(_level_label)
	_xp_bar = UiKit.xp_bar(0.0, 1.0)
	info.add_child(_xp_bar)
	_xp_label = UiKit.label("", "SmallLabel")
	info.add_child(_xp_label)
	refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _level_label != null:
		refresh()


## Cuenta los toques seguidos (con el dedo o el mouse). El clic que el
## motor inventa a partir de un toque no cuenta otra vez.
func _gui_input(event: InputEvent) -> void:
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	var click: InputEventMouseButton = event as InputEventMouseButton
	var tapped: bool = (touch != null and touch.pressed) \
		or (click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and click.device != InputEvent.DEVICE_ID_EMULATION)
	if not tapped:
		return
	var now: int = Time.get_ticks_msec()
	if _taps == 0 or now - _taps_started > DEBUG_TAP_WINDOW_MSEC:
		_taps = 0
		_taps_started = now
	_taps += 1
	if _taps >= DEBUG_TAPS:
		_taps = 0
		debug_requested.emit()


func refresh() -> void:
	if Game.state == null:
		return
	var xp: int = Game.state.xp
	var level: int = Game.level()
	_level_label.text = UiFormat.tr_format("HUD_LEVEL", [level])
	var span: int = Game.levels.xp_span_of_level(xp)
	var into: int = Game.levels.xp_into_level(xp)
	var target: float = into if span > 0 else 1
	if _xp_tween != null:
		_xp_tween.kill()
	if level == _shown_level and target > _xp_bar.value:
		_xp_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_xp_tween.tween_property(_xp_bar, "value", target, XP_FILL_TIME)
	else:
		# Al cambiar de nivel (o al empezar) la barra cambia de escala: va
		# directo a su valor.
		_xp_bar.max_value = maxi(span, 1)
		_xp_bar.value = target
	_shown_level = level
	if span > 0:
		_xp_label.text = UiFormat.tr_format("HUD_XP", [UiFormat.number(into), UiFormat.number(span)])
	else:
		_xp_label.text = tr("HUD_XP_MAX")


## Pone esa cara en el retrato por `seconds` segundos; después, la cara
## `then` por `then_seconds` (si los hay) y al final la normal.
func show_face(face: FacePainter.Face, seconds: float, then: FacePainter.Face = FacePainter.Face.NEUTRAL, then_seconds: float = 0.0) -> void:
	_set_face(face)
	_next_face = then
	_next_face_time = then_seconds
	_face_timer.start(seconds)


## La cara que muestra el retrato.
func shown_face() -> FacePainter.Face:
	return _shown_face


func _on_order_delivered(_order_uid: int, _order_id: String, _cents: int, _xp: int, late: bool) -> void:
	# Si llegó tarde no hay festejo.
	if not late:
		show_face(FacePainter.Face.HAPPY, CharacterFace.HAPPY_TIME)


func _on_print_failed(_printer_uid: int, _failure_type: String) -> void:
	show_face(FacePainter.Face.WORRIED, CharacterFace.WORRIED_TIME)


func _on_level_up(_level: int) -> void:
	show_face(FacePainter.Face.SURPRISE, CharacterFace.SURPRISE_TIME, FacePainter.Face.HAPPY, CharacterFace.LEVEL_UP_TIME - CharacterFace.SURPRISE_TIME)


func _on_face_timeout() -> void:
	if _next_face_time > 0.0:
		show_face(_next_face, _next_face_time)
	else:
		_set_face(FacePainter.Face.NEUTRAL)


func _set_face(face_now: FacePainter.Face) -> void:
	if _character == null or face_now == _shown_face:
		return
	_shown_face = face_now
	CharacterModel.set_expression(_character, face_now)
	_portrait.redraw()


## Centro de la barra de experiencia, en coordenadas de la interfaz: hacia ahí
## vuela la experiencia ganada.
func xp_bar_center() -> Vector2:
	return _xp_bar.get_global_rect().get_center()

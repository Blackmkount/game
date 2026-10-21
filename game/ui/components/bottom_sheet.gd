class_name BottomSheet
extends PanelContainer
## Panel que sube desde abajo con la información de un objeto del mundo
## (impresora, mueble, lugar libre, puerta). La habitación sigue visible
## encima. Se cierra con la X, deslizándolo hacia abajo o tocando el mundo.
##
## Se arma con add_line(), add_tip() y add_action() antes de agregarlo al
## árbol. Hud lo coloca y lo anima.

signal close_requested
signal action_pressed(action_id: String)

## Arrastre hacia abajo (píxeles) que cierra el panel al soltar.
const DISMISS_DRAG: float = 70.0
const SLIDE_TIME: float = 0.18
## Cuánto se desliza (píxeles) al entrar y al salir, mientras se funde.
const SLIDE_DISTANCE: float = 160.0
const ACTION_HEIGHT: float = 96.0
## Lo máximo que el panel cuenta como tapado para la cámara (fracción del alto
## de la pantalla).
const MAX_COVER: float = 0.6

var _preview: Control
var _title: String
var _subtitle: String
var _lines: Array[Dictionary] = []
var _actions: Array[Dictionary] = []
var _drag_start: Variant = null
var _drag_offset: float = 0.0
var _tween: Tween
var _margin: float = 0.0


func _init(preview: Control, title: String, subtitle: String = "") -> void:
	_preview = preview
	_title = title
	_subtitle = subtitle
	mouse_filter = Control.MOUSE_FILTER_STOP


## Fila con icono y texto.
func add_line(icon_name: String, text: String, color: Color = UiPalette.TEXT) -> void:
	_lines.append({"icon": icon_name, "text": text, "color": color, "tip": false})


## Consejo destacado (fondo cian oscuro con estrella dorada).
func add_tip(text: String) -> void:
	_lines.append({"icon": "star", "text": text, "color": UiPalette.GOLD, "tip": true})


## Botón grande al pie del panel. El primero que se marca `primary` va destacado.
func add_action(action_id: String, text: String, primary: bool = false) -> void:
	_actions.append({"id": action_id, "text": text, "primary": primary})


func _ready() -> void:
	var column: VBoxContainer = UiKit.vbox(12)
	add_child(column)
	var handle: PanelContainer = UiKit.panel("SheetHandle")
	handle.custom_minimum_size = Vector2(64, 6)
	handle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(handle)

	var header: HBoxContainer = UiKit.hbox(14)
	column.add_child(header)
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(_preview)
	var titles: VBoxContainer = UiKit.vbox(2)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(titles)
	var title: Label = UiKit.label(_title, "TitleLabel", true)
	title.name = "Title"
	titles.add_child(title)
	if not _subtitle.is_empty():
		titles.add_child(UiKit.label(_subtitle, "MutedLabel", true))
	var close: Button = Button.new()
	close.name = "CloseButton"
	close.theme_type_variation = "IconButton"
	close.icon = UiKit.icon_texture("close")
	close.add_theme_constant_override("icon_max_width", 28)
	close.custom_minimum_size = Vector2(64, 64)
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(close)

	for line: Dictionary in _lines:
		column.add_child(_line_row(line))

	if not _actions.is_empty():
		# Con dos botones van lado a lado, para que el panel tape menos.
		var actions: BoxContainer = UiKit.hbox(10) if _actions.size() == 2 else UiKit.vbox(10)
		actions.name = "Actions"
		column.add_child(actions)
		for action: Dictionary in _actions:
			var button: Button = Button.new()
			button.name = "Action_" + action["id"]
			button.text = action["text"]
			button.theme_type_variation = "PrimaryButton" if action["primary"] else "Button"
			button.custom_minimum_size = Vector2(0, ACTION_HEIGHT)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.focus_mode = Control.FOCUS_NONE
			var action_id: String = action["id"]
			button.pressed.connect(func() -> void: action_pressed.emit(action_id))
			actions.add_child(button)


## Coloca el panel abajo, sobre la barra de secciones, y lo hace subir.
## Crece hacia arriba desde su borde de abajo: su alto siempre es el que pide
## su contenido, también mientras los textos con salto de línea todavía se
## acomodan. Al entrar y al salir solo se mueve el dibujo (desplazamiento
## visual) y se funde, sin tocar el acomodo.
func slide_in(margin: float) -> void:
	_margin = margin
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = margin
	offset_right = -margin
	offset_top = -margin
	offset_bottom = -margin
	offset_transform_enabled = true
	offset_transform_visual_only = true
	offset_transform_position = Vector2(0.0, SLIDE_DISTANCE)
	modulate.a = 0.0
	_animate(0.0, 1.0, Tween.EASE_OUT, Callable())


## Altura que tapa el panel en la pantalla, contando el margen de abajo.
func covered_height() -> float:
	if not is_inside_tree():
		return 0.0
	return minf(size.y, get_viewport_rect().size.y * MAX_COVER) + _margin


func slide_out(on_done: Callable) -> void:
	_animate(SLIDE_DISTANCE, 0.0, Tween.EASE_IN, on_done)


func _animate(shift: float, alpha: float, easing: Tween.EaseType, on_done: Callable) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(easing)
	_tween.tween_property(self, "offset_transform_position:y", shift, SLIDE_TIME)
	_tween.tween_property(self, "modulate:a", alpha, SLIDE_TIME)
	if on_done.is_valid():
		_tween.chain().tween_callback(on_done)


## Deslizar hacia abajo para cerrar. Se usan los eventos de mouse, que en el
## teléfono llegan también al tocar.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var button: InputEventMouseButton = event
		if button.pressed:
			_drag_start = button.global_position.y
			_drag_offset = 0.0
		elif _drag_start != null:
			_drag_start = null
			if _drag_offset > DISMISS_DRAG:
				close_requested.emit()
			elif _drag_offset > 0.0:
				_animate(0.0, 1.0, Tween.EASE_OUT, Callable())
				_drag_offset = 0.0
		accept_event()
	elif event is InputEventMouseMotion and _drag_start != null:
		_drag_offset = maxf((event as InputEventMouseMotion).global_position.y - (_drag_start as float), 0.0)
		# Solo se mueve el dibujo: el dedo sigue "agarrando" el panel.
		offset_transform_position.y = _drag_offset
		accept_event()


func _line_row(line: Dictionary) -> Control:
	var row: HBoxContainer = UiKit.hbox(10)
	row.add_child(UiKit.icon(line["icon"], 30, line["color"]))
	row.add_child(UiKit.label(line["text"], "MutedLabel" if line["tip"] else "", true))
	if not line["tip"]:
		return row
	var tip: PanelContainer = UiKit.panel("ActivePanel")
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.add_child(row)
	return tip

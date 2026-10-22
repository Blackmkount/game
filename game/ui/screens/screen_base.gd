class_name ScreenBase
extends PanelContainer
## Base de las pantallas que se abren sobre la habitación: encabezado con
## icono, título y botón de cerrar, y un contenido con desplazamiento.
## Cada pantalla arma su contenido en _build_content(), y rebuild() lo vuelve
## a armar cuando cambia la partida.

signal close_requested

var content: VBoxContainer
var scroll: ScrollContainer
var _icon_name: String
var _title_key: String


func _init(icon_name: String, title_key: String) -> void:
	_icon_name = icon_name
	_title_key = title_key


func _ready() -> void:
	var column: VBoxContainer = UiKit.vbox(14)
	add_child(column)
	var header: HBoxContainer = UiKit.hbox(12)
	column.add_child(header)
	header.add_child(UiKit.icon(_icon_name, 40, UiPalette.ACCENT))
	var title: Label = UiKit.label(tr(_title_key), "TitleLabel")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close: Button = Button.new()
	close.name = "CloseButton"
	close.theme_type_variation = "IconButton"
	close.icon = UiKit.icon_texture("close")
	close.add_theme_constant_override("icon_max_width", 28)
	close.custom_minimum_size = Vector2(64, 64)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(close)
	_build_header(column)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	content = UiKit.vbox(12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	_build_content()


## Espacio opcional entre el encabezado y el contenido (pestañas, avisos).
func _build_header(_column: VBoxContainer) -> void:
	pass


func _build_content() -> void:
	pass


## Vuelve a armar el contenido sin perder hasta dónde se había bajado. El
## desplazamiento se repone al final del cuadro, cuando el contenido nuevo ya
## tiene su alto.
func rebuild() -> void:
	var offset: int = scroll.scroll_vertical
	clear_content()
	_build_content()
	_restore_scroll.call_deferred(offset)


func clear_content() -> void:
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()


func add_section(title_key: String) -> void:
	var label: Label = UiKit.label(tr(title_key), "BoldLabel")
	label.add_theme_color_override("font_color", UiPalette.ACCENT)
	content.add_child(label)


## Aviso destacado (por ejemplo, funciones que llegan pronto).
func add_notice(parent: Container, text_key: String) -> void:
	var notice: PanelContainer = UiKit.panel("ActivePanel")
	var row: HBoxContainer = UiKit.hbox(10)
	notice.add_child(row)
	row.add_child(UiKit.icon("star", 28, UiPalette.GOLD))
	row.add_child(UiKit.label(tr(text_key), "MutedLabel", true))
	parent.add_child(notice)


func _restore_scroll(offset: int) -> void:
	scroll.scroll_vertical = offset

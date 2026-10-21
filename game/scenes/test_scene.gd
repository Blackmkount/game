extends Node3D
## Escena de prueba de la Fase 0: un cuarto hecho con cajas y una impresora
## armada con formas básicas. Sirve para comprobar que la versión web abre en
## el navegador del teléfono. Se reemplaza en la Fase 2.

## Colores que recorre el botón, en el mismo orden que COLOR_NAME_KEYS.
const PRINTER_COLORS: Array[Color] = [
	Color("ef8354"),
	Color("2a9d8f"),
	Color("e9c46a"),
	Color("8e7dbe"),
]
const COLOR_NAME_KEYS: Array[StringName] = [
	&"COLOR_ORANGE",
	&"COLOR_TEAL",
	&"COLOR_YELLOW",
	&"COLOR_PURPLE",
]
## Recorrido del cabezal a cada lado del centro (metros) y duración de cada pasada (segundos).
const HEAD_TRAVEL: float = 0.18
const HEAD_PASS_SECONDS: float = 1.2

## Material compartido por todas las piezas de la carcasa de la impresora.
@export var printer_body_material: StandardMaterial3D

var _color_index: int = 0

@onready var _print_head: Node3D = %PrintHead
@onready var _title_label: Label = %TitleLabel
@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _color_label: Label = %ColorLabel
@onready var _change_color_button: Button = %ChangeColorButton


func _ready() -> void:
	_title_label.text = tr("GAME_TITLE")
	_subtitle_label.text = tr("TEST_SCENE_SUBTITLE")
	_change_color_button.text = tr("TEST_CHANGE_COLOR")
	_change_color_button.pressed.connect(_on_change_color_pressed)
	_apply_color()
	_start_print_head_animation()


func _on_change_color_pressed() -> void:
	_color_index = (_color_index + 1) % PRINTER_COLORS.size()
	_apply_color()


func _apply_color() -> void:
	printer_body_material.albedo_color = PRINTER_COLORS[_color_index]
	_color_label.text = tr("TEST_PRINTER_COLOR") % tr(COLOR_NAME_KEYS[_color_index])


func _start_print_head_animation() -> void:
	var center_x: float = _print_head.position.x
	var tween: Tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tween.tween_property(_print_head, "position:x", center_x + HEAD_TRAVEL, HEAD_PASS_SECONDS)
	tween.tween_property(_print_head, "position:x", center_x - HEAD_TRAVEL, HEAD_PASS_SECONDS)

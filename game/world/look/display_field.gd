class_name DisplayField
extends MultiMeshInstance3D
## Las pantallitas de las impresoras de los muebles con el zoom lejos (biblia
## de arte §5.3 y §13): una copia por impresora en UN MultiMesh, una llamada
## de dibujo para todas (cada "Display" cuesta una). Cada copia se dibuja
## igual que su pantallita (display_field.gdshader, con el mismo dibujo que
## screen.gdshader) y muestra el estado que le pone su PrinterView: libre,
## imprimiendo, lista o con falla.
##
## Cada impresora pide la suya con add() y le cambia el estado con
## set_mode(); cuando cambia lo que hay en el cuarto, RoomView las quita
## todas (clear) y las vuelve a pedir. Solo se ve con el zoom lejos
## (set_shown): con el zoom normal se ven las "Display" de siempre.

## Copias que se reservan de una vez (se agranda si hace falta).
const START_CAPACITY: int = 16
## Los modos de screen.gdshader que dibuja (WorldPalette.SCREEN_MODES): de
## FIRST_MODE (libre) a FIRST_MODE + MODES - 1 (falla). Van en el rojo del
## color de la copia (display_field.gdshader).
const FIRST_MODE: int = 2
const MODES: int = 4

var _transforms: Array[Transform3D] = []
var _modes: Array[int] = []
var _shown: bool = false


func _init() -> void:
	name = "FarDisplays"
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Un cuadro de 1 × 1 que mira hacia +Z, como PropBuilder.quad: cada copia
	# lleva el lugar y el tamaño de su pantallita.
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = quad
	multimesh.instance_count = START_CAPACITY
	multimesh.visible_instance_count = 0
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = preload("res://game/world/look/display_field.gdshader")
	material_override = material
	visible = false


## Agrega una pantallita: `at` es su lugar en el espacio del padre de este
## nodo (el centro del cuadro, mirando hacia su +Z), `size` su ancho y alto
## y `mode` lo que muestra (modo de screen.gdshader). Devuelve su número.
func add(at: Transform3D, size: Vector2, mode: int) -> int:
	var placed: Transform3D = at * Transform3D(Basis.from_scale(Vector3(size.x, size.y, 1.0)), Vector3.ZERO)
	_transforms.append(placed)
	_modes.append(mode)
	var index: int = _transforms.size() - 1
	if index >= multimesh.instance_count:
		_grow()
	else:
		multimesh.set_instance_transform(index, placed)
		multimesh.set_instance_color(index, _instance_color(mode))
	multimesh.visible_instance_count = _transforms.size()
	_refresh()
	return index


## Lo que muestra la pantallita `index` (modo de screen.gdshader).
func set_mode(index: int, mode: int) -> void:
	_modes[index] = mode
	multimesh.set_instance_color(index, _instance_color(mode))


func mode_of(index: int) -> int:
	return _modes[index]


## Dónde está la pantallita `index` (en el espacio del padre, con su tamaño
## en la escala).
func transform_of(index: int) -> Transform3D:
	return _transforms[index]


func count() -> int:
	return _transforms.size()


## Quita todas (RoomView las vuelve a pedir, en orden, cuando cambia lo que
## hay en el cuarto). Las copias reservadas quedan para las nuevas.
func clear() -> void:
	_transforms.clear()
	_modes.clear()
	multimesh.visible_instance_count = 0
	_refresh()


## Con el zoom lejos se ven; con el normal, no (se ven las de siempre).
func set_shown(shown: bool) -> void:
	_shown = shown
	_refresh()


func _refresh() -> void:
	visible = _shown and not _transforms.is_empty()


## Más lugar: cambiar instance_count borra las copias, se vuelven a poner.
func _grow() -> void:
	multimesh.instance_count = maxi(multimesh.instance_count * 2, _transforms.size())
	for i: int in _transforms.size():
		multimesh.set_instance_transform(i, _transforms[i])
		multimesh.set_instance_color(i, _instance_color(_modes[i]))


## El modo en el rojo del color, al medio de su franja (así lo lee el
## sombreador aunque el color pierda precisión).
static func _instance_color(mode: int) -> Color:
	return Color((float(mode - FIRST_MODE) + 0.5) / float(MODES), 0.0, 0.0)

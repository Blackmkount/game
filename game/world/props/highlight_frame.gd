class_name HighlightFrame
extends Node3D
## Marco cian que late en el piso alrededor del objeto que el personaje tiene
## cerca. Tiene el mismo estilo que las marcas de lugares libres (ver
## docs/ESTILO.md).

const LINE: float = 0.05
const HEIGHT: float = 0.012
const MARGIN: float = 0.12
## Latido: el alfa va de ALPHA a ALPHA_LOW y vuelve en PULSE_PERIOD segundos
## (lo anima el sombreador con el tiempo del mundo).
const ALPHA: float = 0.9
const ALPHA_LOW: float = 0.45
const PULSE_PERIOD: float = 1.2

var _sides: Array[MeshInstance3D] = []


static func build(parent: Node3D, node_name: String) -> HighlightFrame:
	var frame: HighlightFrame = HighlightFrame.new()
	frame.name = node_name
	parent.add_child(frame)
	var material: ShaderMaterial = WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, ALPHA, ALPHA_LOW, PULSE_PERIOD)
	for side_name: String in ["Front", "Back", "Left", "Right"]:
		frame._sides.append(PropBuilder.box(frame, side_name, Vector3.ONE * LINE, Vector3.ZERO, material))
	frame.visible = false
	return frame


## Muestra el marco alrededor de un rectángulo del piso (plano XZ).
func show_around(footprint: Rect2) -> void:
	var rect: Rect2 = footprint.grow(MARGIN)
	position = Vector3(rect.get_center().x, HEIGHT, rect.get_center().y)
	var width: float = rect.size.x
	var depth: float = rect.size.y
	_place(0, Vector3(width + LINE, HEIGHT, LINE), Vector3(0.0, 0.0, depth / 2.0))
	_place(1, Vector3(width + LINE, HEIGHT, LINE), Vector3(0.0, 0.0, -depth / 2.0))
	_place(2, Vector3(LINE, HEIGHT, depth), Vector3(-width / 2.0, 0.0, 0.0))
	_place(3, Vector3(LINE, HEIGHT, depth), Vector3(width / 2.0, 0.0, 0.0))
	visible = true


func hide_frame() -> void:
	visible = false


func _place(index: int, size: Vector3, offset: Vector3) -> void:
	(_sides[index].mesh as BoxMesh).size = size
	_sides[index].position = offset

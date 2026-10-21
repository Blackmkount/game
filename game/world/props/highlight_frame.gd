class_name HighlightFrame
extends Node3D
## Marco cian que late en el piso alrededor del objeto que el personaje tiene
## cerca. Tiene el mismo estilo que las marcas de lugares libres (ver
## docs/ESTILO.md).

const LINE: float = 0.05
const HEIGHT: float = 0.012
const MARGIN: float = 0.12

var _sides: Array[MeshInstance3D] = []
var _material: StandardMaterial3D
var _pulse: Tween


static func build(parent: Node3D, node_name: String) -> HighlightFrame:
	var frame: HighlightFrame = HighlightFrame.new()
	frame.name = node_name
	parent.add_child(frame)
	frame._material = WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, 0.9).duplicate() as StandardMaterial3D
	for side_name: String in ["Front", "Back", "Left", "Right"]:
		frame._sides.append(PropBuilder.box(frame, side_name, Vector3.ONE * LINE, Vector3.ZERO, frame._material))
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
	if not visible:
		visible = true
		_start_pulse()


func hide_frame() -> void:
	visible = false
	if _pulse != null:
		_pulse.kill()
		_pulse = null


func _place(index: int, size: Vector3, offset: Vector3) -> void:
	(_sides[index].mesh as BoxMesh).size = size
	_sides[index].position = offset


func _start_pulse() -> void:
	if _pulse != null:
		_pulse.kill()
	_material.albedo_color.a = 0.9
	_pulse = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	_pulse.tween_property(_material, "albedo_color:a", 0.45, 0.6)
	_pulse.tween_property(_material, "albedo_color:a", 0.9, 0.6)

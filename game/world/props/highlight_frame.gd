class_name HighlightFrame
extends Node3D
## Marco cian que late en el piso alrededor del objeto que el personaje tiene
## cerca (biblia de arte §8.7): cuatro esquinas en L, como las marcas de
## lugares libres, alrededor de la huella del objeto más MARGIN. Una malla por
## tamaño de huella (se guarda: hay pocos objetos distintos) y una llamada de
## dibujo.

const LINE: float = 0.03
const HEIGHT: float = 0.012
const MARGIN: float = 0.12
## Brazos de las esquinas: esta parte del lado, entre ARM_MIN y ARM_MAX.
const ARM_SHARE: float = 0.25
const ARM_MIN: float = 0.14
const ARM_MAX: float = 0.3
## Latido: el alfa va de ALPHA a ALPHA_LOW y vuelve en PULSE_PERIOD segundos
## (lo anima el sombreador con el tiempo del mundo).
const ALPHA: float = 0.8
const ALPHA_LOW: float = 0.45
const PULSE_PERIOD: float = 1.2

var _frame: MeshInstance3D


static func build(parent: Node3D, node_name: String) -> HighlightFrame:
	var frame: HighlightFrame = HighlightFrame.new()
	frame.name = node_name
	parent.add_child(frame)
	var material: ShaderMaterial = WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, ALPHA, ALPHA_LOW, PULSE_PERIOD)
	frame._frame = PropBuilder.kit(frame, "Frame", ArrayMesh.new(), material)
	frame._frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	frame.visible = false
	return frame


## Muestra el marco alrededor de un rectángulo del piso (plano XZ).
func show_around(footprint: Rect2) -> void:
	var rect: Rect2 = footprint.grow(MARGIN)
	position = Vector3(rect.get_center().x, HEIGHT, rect.get_center().y)
	var size: Vector2 = rect.size.snappedf(0.01)
	_frame.mesh = KitMesh.cached("highlight:%.2f:%.2f" % [size.x, size.y], func() -> ArrayMesh: return _corners(size))
	visible = true


func hide_frame() -> void:
	visible = false


## Cuatro esquinas en L de un rectángulo de ese tamaño, centrado.
static func _corners(size: Vector2) -> ArrayMesh:
	var kit: KitMesh = KitMesh.new()
	kit.ao_enabled = false
	var half: Vector2 = size / 2.0
	var arm: Vector2 = (size * ARM_SHARE).clampf(ARM_MIN, ARM_MAX)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_flat(kit, Vector2(sx * (half.x - arm.x / 2.0), sz * (half.y - LINE / 2.0)), Vector2(arm.x, LINE))
			_flat(kit, Vector2(sx * (half.x - LINE / 2.0), sz * (half.y - LINE - (arm.y - LINE) / 2.0)), Vector2(LINE, arm.y - LINE))
	return kit.commit()


static func _flat(kit: KitMesh, center: Vector2, size: Vector2) -> void:
	kit.quad(size, Vector3(center.x, 0.0, center.y), Vector3(-90.0, 0.0, 0.0))

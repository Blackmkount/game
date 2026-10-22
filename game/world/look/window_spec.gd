class_name WindowSpec
extends RefCounted
## La ventana de la pared izquierda en una sola constante (biblia de arte
## §6.3 y §8.5): el hueco, las rejas de hierro, el travesaño, el parante
## central de la ventana corrediza y el adorno de sol. La usan la geometría
## del cuarto (RoomShell) y el parche de sol que calcula el sombreador
## (world_light.gdshaderinc), así las rayas del piso salen de las mismas
## rejas que se ven.
##
## Medidas en metros, en el mundo. La pared de la ventana es el plano x = -3
## (la cara de adentro); el hueco atraviesa la pared hacia -X.

## Plano de la pared (la cara de adentro).
const WALL_X: float = -3.0
## Hueco: de z0 a z1 y de y0 a y1.
const HOLE_Z: Vector2 = Vector2(-1.8, -0.6)
const HOLE_Y: Vector2 = Vector2(1.15, 2.05)
## Rejas verticales: separación y medio grosor. Van a media separación de los
## bordes del hueco (la primera, a BAR_SPACING / 2 del borde).
const BAR_SPACING: float = 0.2
const BAR_HALF: float = 0.009
## Travesaño de la reja: a media altura del hueco, del mismo hierro.
const CROSSBAR_Y: float = 1.6
## Parante central de la ventana corrediza (donde se cruzan las dos hojas):
## medio ancho.
const MULLION_HALF: float = 0.025
## Adorno de sol de la reja: dos aros entre las dos rejas del medio, arriba
## del travesaño (centro en y, radio de afuera y de adentro). El grosor es el
## de las rejas.
const SUN_Y: float = 1.83
const SUN_OUTER: float = 0.1
const SUN_INNER: float = 0.05


## Centro del hueco en z (ahí van el parante y el adorno de sol).
static func center_z() -> float:
	return (HOLE_Z.x + HOLE_Z.y) / 2.0


## Dónde va cada reja vertical (z), a media separación de los bordes.
static func bar_positions() -> PackedFloat32Array:
	var positions: PackedFloat32Array = PackedFloat32Array()
	var count: int = roundi((HOLE_Z.y - HOLE_Z.x) / BAR_SPACING)
	for i: int in count:
		positions.append(HOLE_Z.x + BAR_SPACING * (i + 0.5))
	return positions


## Los globales del parche (biblia §3.2): hueco, plano de la pared, rejas y
## adorno de sol.
static func globals() -> Dictionary[StringName, Variant]:
	return {
		&"cc_window_rect": Vector4(HOLE_Z.x, HOLE_Z.y, HOLE_Y.x, HOLE_Y.y),
		&"cc_window_x": WALL_X,
		&"cc_window_bars": Vector4(BAR_SPACING, BAR_HALF, CROSSBAR_Y, MULLION_HALF),
		&"cc_window_sun": Vector4(center_z(), SUN_Y, SUN_OUTER, SUN_INNER),
	}


## Pone los globales del parche en los sombreadores.
static func publish() -> void:
	var values: Dictionary[StringName, Variant] = globals()
	for parameter: StringName in values:
		RenderingServer.global_shader_parameter_set(parameter, values[parameter])

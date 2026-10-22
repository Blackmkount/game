class_name ComputerDeskModel
extends RefCounted
## Mesa vieja de madera con un computador viejo (monitor de tubo, torre
## beige, teclado y ratón) y una caja de cartón que hace de silla.
## El frente mira hacia +Z.

## El tablero: ancho, alto de arriba y fondo. Con él RoomView arma la caja que
## tapa el parche de sol de la ventana (el escritorio está bajo la ventana).
const TABLE_SIZE: Vector3 = Vector3(1.3, 0.75, 0.62)
const TABLE_THICKNESS: float = 0.06


## La caja del tablero (con lo que hay debajo), en el espacio del mueble.
static func table_box() -> AABB:
	return AABB(Vector3(-TABLE_SIZE.x / 2.0, 0.0, -TABLE_SIZE.z / 2.0), TABLE_SIZE)


static func build(parent: Node3D, node_name: String) -> Node3D:
	var desk: Node3D = PropBuilder.group(parent, node_name)
	var wood: Material = WorldPalette.paint(WorldPalette.WOOD_MID, WorldPalette.Surface.WOOD, 0.15)
	var beige: Material = WorldPalette.paint(WorldPalette.PLASTIC_BEIGE, WorldPalette.Surface.SMOOTH, 0.2)
	var beige_dark: Material = WorldPalette.paint(WorldPalette.PLASTIC_BEIGE_DARK, WorldPalette.Surface.SMOOTH, 0.2)
	PropBuilder.box(desk, "Top", Vector3(TABLE_SIZE.x, TABLE_THICKNESS, TABLE_SIZE.z), Vector3(0.0, TABLE_SIZE.y - TABLE_THICKNESS / 2.0, 0.0), wood)
	for i: int in 4:
		var x: float = 0.6 if i % 2 == 0 else -0.6
		var z: float = 0.26 if i < 2 else -0.26
		PropBuilder.box(desk, "Leg%d" % (i + 1), Vector3(0.06, 0.69, 0.06), Vector3(x, 0.345, z), wood)

	var monitor: Node3D = PropBuilder.group(desk, "Monitor", Vector3(-0.15, 0.75, -0.08))
	PropBuilder.box(monitor, "Body", Vector3(0.44, 0.38, 0.36), Vector3(0.0, 0.21, -0.02), beige)
	PropBuilder.box(monitor, "Back", Vector3(0.3, 0.26, 0.14), Vector3(0.0, 0.2, -0.26), beige_dark)
	PropBuilder.quad(monitor, "Screen", Vector2(0.34, 0.26), Vector3(0.0, 0.22, 0.165), WorldPalette.glow("ffffff", "crt_screen"))
	PropBuilder.box(monitor, "Stand", Vector3(0.2, 0.03, 0.2), Vector3(0.0, 0.015, 0.0), beige_dark)

	PropBuilder.box(desk, "Keyboard", Vector3(0.4, 0.03, 0.13), Vector3(-0.12, 0.765, 0.2), beige)
	PropBuilder.box(desk, "Mouse", Vector3(0.05, 0.03, 0.08), Vector3(0.18, 0.765, 0.2), beige)
	PropBuilder.box(desk, "Tower", Vector3(0.18, 0.4, 0.4), Vector3(0.42, 0.95, -0.08), beige_dark)
	PropBuilder.box(desk, "TowerLight", Vector3(0.03, 0.03, 0.01), Vector3(0.42, 1.08, 0.125), WorldPalette.glow("7fe0a0"))
	PropBuilder.box(desk, "Mug", Vector3(0.07, 0.09, 0.07), Vector3(0.4, 0.795, 0.2), WorldPalette.paint("e0453a", WorldPalette.Surface.SMOOTH, 0.3))

	PropBuilder.box(desk, "CardboardSeat", Vector3(0.42, 0.4, 0.42), Vector3(0.05, 0.2, 0.6), WorldPalette.textured("cardboard"))
	return desk

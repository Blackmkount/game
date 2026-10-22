class_name DispatchCornerModel
extends RefCounted
## Rincón de despacho junto a la puerta: una mesita para embalar, con cajas
## planas debajo y un rollo de cinta, y un cajón de madera donde esperan los
## paquetes listos. El frente mira hacia +Z y la base queda en y = 0.
##
## Las marcas "PackSpot0..2" (sobre la mesa) y "OutSpot0..2" (apiladas sobre el
## cajón) dicen dónde van las cajas abiertas y los paquetes (DispatchView).

const PACK_SPOTS: int = 3
const OUT_SPOTS: int = 3


static func build(parent: Node3D, node_name: String) -> Node3D:
	var corner: Node3D = PropBuilder.group(parent, node_name)
	var wood_mid: StandardMaterial3D = WorldPalette.solid(WorldPalette.WOOD_MID)

	var table: Node3D = PropBuilder.group(corner, "PackTable")
	PropBuilder.box(table, "Top", Vector3(0.5, 0.04, 0.4), Vector3(0.2, 0.48, 0.0), WorldPalette.solid(WorldPalette.WOOD_LIGHT))
	for i: int in 4:
		var x: float = 0.2 + (0.22 if i % 2 == 0 else -0.22)
		var z: float = 0.17 if i < 2 else -0.17
		PropBuilder.box(table, "Leg%d" % i, Vector3(0.04, 0.46, 0.04), Vector3(x, 0.23, z), wood_mid)
	PropBuilder.box(table, "FlatBoxes", Vector3(0.4, 0.1, 0.3), Vector3(0.2, 0.05, 0.0), WorldPalette.textured("cardboard"))
	PropBuilder.cylinder(table, "TapeRoll", 0.04, 0.04, Vector3(0.38, 0.52, -0.13), WorldPalette.solid(WorldPalette.TAPE))

	var crate: Node3D = PropBuilder.group(corner, "OutCrate")
	PropBuilder.box(crate, "Body", Vector3(0.36, 0.26, 0.34), Vector3(-0.25, 0.13, 0.0), wood_mid)
	var slat: StandardMaterial3D = WorldPalette.solid(WorldPalette.WOOD_DARK)
	PropBuilder.box(crate, "Slat0", Vector3(0.37, 0.03, 0.35), Vector3(-0.25, 0.08, 0.0), slat)
	PropBuilder.box(crate, "Slat1", Vector3(0.37, 0.03, 0.35), Vector3(-0.25, 0.18, 0.0), slat)

	# Las cajas abiertas se apoyan en la mesa; los paquetes se apilan con su
	# centro en cada marca.
	for i: int in PACK_SPOTS:
		_marker(corner, "PackSpot%d" % i, Vector3(0.03 + i * 0.17, 0.5, 0.02))
	for i: int in OUT_SPOTS:
		_marker(corner, "OutSpot%d" % i, Vector3(-0.25, 0.33 + i * 0.14, 0.0))
	return corner


static func _marker(parent: Node3D, node_name: String, position: Vector3) -> void:
	var marker: Marker3D = Marker3D.new()
	marker.name = node_name
	marker.position = position
	parent.add_child(marker)

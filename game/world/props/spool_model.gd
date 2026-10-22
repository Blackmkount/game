class_name SpoolModel
extends RefCounted
## Carrete de filamento: dos tapas oscuras y el filamento del color elegido.
## Queda acostado, con el eje a lo largo de X.


static func build(parent: Node3D, node_name: String, position: Vector3, color_hex: String, radius: float = 0.1) -> Node3D:
	var spool: Node3D = PropBuilder.group(parent, node_name, position)
	var flange: Material = WorldPalette.paint(LookPalette.SPOOL_FLANGE, WorldPalette.Surface.SMOOTH, 0.3)
	var sideways: Vector3 = Vector3(0.0, 0.0, 90.0)
	PropBuilder.cylinder(spool, "Filament", radius * 0.86, radius * 0.6, Vector3.ZERO, WorldPalette.solid(color_hex), sideways)
	PropBuilder.cylinder(spool, "FlangeA", radius, radius * 0.1, Vector3(radius * 0.33, 0.0, 0.0), flange, sideways)
	PropBuilder.cylinder(spool, "FlangeB", radius, radius * 0.1, Vector3(-radius * 0.33, 0.0, 0.0), flange, sideways)
	return spool

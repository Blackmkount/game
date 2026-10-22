class_name PackageModel
extends RefCounted
## Cajas del rincón de despacho, exageradas para que se vean (más de 3 cm,
## ver docs/ESTILO.md):
## - package: un paquete cerrado con cinta, centrado en su origen (se apilan
##   sobre el cajón de salida).
## - open_box: una caja abierta con la pieza asomando, con la base en su
##   origen (se apoya en la mesa de embalar).


static func package(parent: Node3D, node_name: String) -> Node3D:
	var root: Node3D = PropBuilder.group(parent, node_name)
	PropBuilder.box(root, "Box", Vector3(0.18, 0.14, 0.16), Vector3.ZERO, WorldPalette.textured("cardboard"))
	PropBuilder.box(root, "Tape", Vector3(0.185, 0.006, 0.04), Vector3(0.0, 0.073, 0.0), WorldPalette.solid(WorldPalette.TAPE))
	return root


## La pieza de adentro ("Piece") se tiñe con el color del pedido.
static func open_box(parent: Node3D, node_name: String) -> Node3D:
	var root: Node3D = PropBuilder.group(parent, node_name)
	PropBuilder.box(root, "Box", Vector3(0.16, 0.08, 0.14), Vector3(0.0, 0.04, 0.0), WorldPalette.textured("cardboard"))
	PropBuilder.box(root, "Piece", Vector3(0.08, 0.06, 0.08), Vector3(0.0, 0.11, 0.0), WorldPalette.solid(WorldPalette.PLASTIC_BEIGE))
	return root

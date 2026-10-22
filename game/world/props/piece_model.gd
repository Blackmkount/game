class_name PieceModel
extends RefCounted
## La pieza que se imprime sobre la cama: un bloque del color del filamento
## que crece capa a capa. Los tamaños están exagerados a propósito (un
## llavero real mide unos 4 cm y no se vería; ver docs/ESTILO.md). Son
## constantes de presentación, no de balance.

## Ancho, alto final y fondo según el tamaño del pedido (orders.json "size").
const SIZES: Dictionary[String, Vector3] = {
	"S": Vector3(0.12, 0.14, 0.12),
	"M": Vector3(0.18, 0.2, 0.18),
	"L": Vector3(0.24, 0.26, 0.24),
}
## Alto mínimo de la malla: una pieza recién empezada no tiene alto, pero la
## caja no puede medir 0.
const MIN_HEIGHT: float = 0.001
## Alto de cada capa que se ve crecer (presentación): la pieza sube de a 1 cm
## y nunca baja.
const LAYER_STEP: float = 0.01


## Arma la pieza escondida, con su propia malla (cambia de tamaño mientras
## crece). Su base queda en el origen del padre.
static func build(parent: Node3D, node_name: String) -> MeshInstance3D:
	var piece: MeshInstance3D = PropBuilder.box(parent, node_name, Vector3.ONE * MIN_HEIGHT, Vector3.ZERO, WorldPalette.solid(WorldPalette.PLASTIC_BEIGE))
	piece.visible = false
	return piece


## Tamaño, color y alto actual de la pieza. Se cambia el tamaño de la malla y
## no la escala del nodo, para que el contorno no crezca con la pieza.
static func set_shape(piece: MeshInstance3D, size_id: String, color_hex: String, height: float) -> void:
	var full: Vector3 = full_size(size_id)
	var mesh: BoxMesh = piece.mesh
	var shown: float = maxf(height, MIN_HEIGHT)
	mesh.size = Vector3(full.x, shown, full.z)
	piece.position.y = shown / 2.0
	piece.material_override = WorldPalette.solid(color_hex)


## Medidas de la pieza terminada; un tamaño desconocido se ve como S.
static func full_size(size_id: String) -> Vector3:
	return SIZES.get(size_id, SIZES["S"])


## Color (hex) de un filamento de config.filament_colors; beige si no existe.
static func filament_hex(rules: SimRules, color_id: String) -> String:
	var color: Dictionary = rules.colors.get(color_id, {})
	return color.get("hex", WorldPalette.PLASTIC_BEIGE)

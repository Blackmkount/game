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
## Nido de "espagueti" de una falla (biblia de arte §9.5): rulos enredados
## sobre la pieza y dos hebras que suben SPAGHETTI_RISE hasta la boquilla
## (PrinterView deja ahí el cabezal), del color del filamento un poco más
## claro. Hilo de 6 mm (la biblia pide 4: con 4 mm, a zoom normal, el nido
## medía menos de un píxel y no se leía). La semilla es fija: siempre el
## mismo nido.
const SPAGHETTI_LOOPS: int = 11
const SPAGHETTI_STRANDS: int = 2
const SPAGHETTI_RADIUS: float = 0.003
const SPAGHETTI_RISE: float = 0.09
const SPAGHETTI_SEED: int = 7
const SPAGHETTI_BRIGHTNESS: float = 1.1
const SPAGHETTI_GLOSS: float = 0.5


## Arma la pieza escondida, con su propia malla (cambia de tamaño mientras
## crece). Su base queda en el origen del padre.
static func build(parent: Node3D, node_name: String) -> MeshInstance3D:
	var piece: MeshInstance3D = PropBuilder.box(parent, node_name, Vector3.ONE * MIN_HEIGHT, Vector3.ZERO, WorldPalette.solid(WorldPalette.PLASTIC_BEIGE))
	piece.visible = false
	return piece


## Tamaño, color y alto actual de la pieza. Se cambia el tamaño de la malla y
## no la escala del nodo, así las capas y la capa caliente miden siempre lo
## mismo. Mientras se imprime (`printing`), la capa de arriba brilla caliente.
static func set_shape(piece: MeshInstance3D, size_id: String, color_hex: String, height: float, printing: bool = false) -> void:
	var full: Vector3 = full_size(size_id)
	var mesh: BoxMesh = piece.mesh
	var shown: float = maxf(height, MIN_HEIGHT)
	mesh.size = Vector3(full.x, shown, full.z)
	piece.position.y = shown / 2.0
	if printing:
		piece.material_override = WorldPalette.printing(color_hex)
		piece.set_instance_shader_parameter(&"hot_top", shown / 2.0)
	else:
		piece.material_override = WorldPalette.solid(color_hex)


## Alto de la pieza que se ve (hoy, el de su caja). Las pruebas lo leen por
## aquí: así sirve también cuando las piezas tengan forma.
static func shown_height(piece: MeshInstance3D) -> float:
	return (piece.mesh as BoxMesh).size.y


## El nido de espagueti, escondido. Su base va arriba de la pieza fallida
## (la mueve PrinterView); el material lo pone spaghetti_material().
static func build_spaghetti(parent: Node3D, node_name: String) -> MeshInstance3D:
	var nest: MeshInstance3D = PropBuilder.kit(parent, node_name, KitMesh.cached("spaghetti", _spaghetti_mesh))
	nest.visible = false
	return nest


## Material del espagueti: el color del filamento × SPAGHETTI_BRIGHTNESS, con
## brillo (se lee sobre la pieza fallida oscura sin abrir el panel).
static func spaghetti_material(hex: String) -> ShaderMaterial:
	var color: Color = Color(hex)
	var bright: Color = Color(minf(color.r * SPAGHETTI_BRIGHTNESS, 1.0), minf(color.g * SPAGHETTI_BRIGHTNESS, 1.0), minf(color.b * SPAGHETTI_BRIGHTNESS, 1.0))
	return WorldPalette.paint(bright.to_html(false), WorldPalette.Surface.SMOOTH, SPAGHETTI_GLOSS)


## Medidas de la pieza terminada; un tamaño desconocido se ve como S.
static func full_size(size_id: String) -> Vector3:
	return SIZES.get(size_id, SIZES["S"])


## Color (hex) de un filamento de config.filament_colors; beige si no existe.
static func filament_hex(rules: SimRules, color_id: String) -> String:
	var color: Dictionary = rules.colors.get(color_id, {})
	return color.get("hex", WorldPalette.PLASTIC_BEIGE)


## Rulos del tamaño de la pieza chica (cada uno, una vuelta y algo torcida)
## y dos hebras que suben ondulando hasta la boquilla, en (0, RISE, 0).
static func _spaghetti_mesh() -> ArrayMesh:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SPAGHETTI_SEED
	var kit: KitMesh = KitMesh.new()
	kit.ao_enabled = false
	for loop: int in SPAGHETTI_LOOPS:
		var center: Vector3 = Vector3(rng.randf_range(-0.05, 0.05), rng.randf_range(0.012, 0.04), rng.randf_range(-0.045, 0.045))
		var radius: float = rng.randf_range(0.022, 0.042)
		var tilt: Basis = Basis.from_euler(Vector3(rng.randf_range(-0.9, 0.9), rng.randf_range(0.0, TAU), rng.randf_range(-0.9, 0.9)))
		var turns: float = rng.randf_range(0.9, 1.5)
		var points: PackedVector3Array = PackedVector3Array()
		for i: int in 10:
			var a: float = float(i) / 9.0 * TAU * turns
			var wobble: float = 1.0 + rng.randf_range(-0.25, 0.25)
			var p: Vector3 = center + tilt * Vector3(cos(a) * radius * wobble, rng.randf_range(-0.006, 0.006), sin(a) * radius * wobble)
			points.append(p)
		# Suavizada antes y sin bajar del borde de arriba de la pieza: ningún
		# hilo se mete adentro.
		var path: PackedVector3Array = KitMesh.smooth_path(points, 2)
		for k: int in path.size():
			path[k].y = maxf(path[k].y, SPAGHETTI_RADIUS)
		kit.tube(path, SPAGHETTI_RADIUS, 4, 1)
	for strand: int in SPAGHETTI_STRANDS:
		var side: float = -1.0 if strand == 0 else 1.0
		var points: PackedVector3Array = PackedVector3Array()
		for i: int in 6:
			var t: float = float(i) / 5.0
			var spread: float = 1.0 - t
			points.append(Vector3(side * (0.02 * spread + sin(t * 9.0) * 0.008 * spread), 0.035 + t * (SPAGHETTI_RISE - 0.035), side * 0.012 * spread + cos(t * 7.0) * 0.008 * spread))
		kit.tube(points, SPAGHETTI_RADIUS, 4, 3)
	return kit.commit()

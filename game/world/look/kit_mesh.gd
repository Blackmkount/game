class_name KitMesh
extends RefCounted
## Arma UNA malla con muchas formas (biblia de arte §5): cajas con bisel,
## cilindros con canto, tornos, formas redondas (superelipsoides), cápsulas,
## tubos por una curva, toroides, discos, rectángulos y triángulos. Cada
## vértice lleva lo que lee el material del kit (biblia §3.3,
## kit_body.gdshaderinc):
##   COLOR.rgb  color (hex de la paleta)       COLOR.a  oclusión horneada
##   UV.x       superficie + brillo            UV.y     peso del balanceo
##   UV2.x      alto de capa si fue impreso    UV2.y    luz propia
## Así un mueble entero es una malla con un solo material
## (WorldPalette.kit()): una llamada de dibujo.
##
## Medidas en metros, escala real, el origen en la base del objeto (y = 0
## toca el piso o la mesa) y el frente hacia +Z. Las mallas se arman una vez
## y se guardan en caché (cached), con una clave que diga todo lo que las
## cambia: modelo, variante, detalle y color. Ejemplo:
##   var mesh: ArrayMesh = KitMesh.cached("mesa:0.8", func() -> ArrayMesh:
##       var kit: KitMesh = KitMesh.new()
##       kit.detail = 0.8
##       kit.paint(LookPalette.WOOD_MID, WorldPalette.Surface.WOOD, 0.15)
##       kit.box(Vector3(1.3, 0.05, 0.6), Vector3(0.0, 0.72, 0.0), 0.012)
##       return kit.commit())
##   PropBuilder.kit(parent, "Body", mesh)

## Oclusión de contacto horneada (biblia §3.5): a la altura `ao_base` queda
## en CONTACT_AO (−35 %) y se aclara del todo CONTACT_FADE metros más arriba.
const CONTACT_AO: float = 0.65
const CONTACT_FADE: float = 0.14
## Las caras que miran hacia abajo pierden hasta este tanto (−25 %).
const DOWN_AO: float = 0.25
## Los triángulos de menos área (m²) no se agregan: así no quedan triángulos
## degenerados (los polos de las formas redondas, un punto repetido).
const MIN_AREA: float = 1e-9
## Brillo máximo (UV.x guarda superficie + brillo: tiene que quedar < 1).
const MAX_GLOSS: float = 0.98
## El bisel no pasa de esta fracción de la mitad del lado menor; por debajo
## de MIN_BEVEL la caja sale sin bisel.
const MAX_BEVEL: float = 0.9
const MIN_BEVEL: float = 0.0005
## Lados mínimos con cualquier `detail`: alrededor de una forma redonda y en
## su otra dirección (filas de una esfera, lados de un tubo).
const MIN_AROUND: int = 6
const MIN_ROWS: int = 4
## Paso de las diferencias finitas para las normales de las formas
## redondas (radianes de su parámetro).
const NORMAL_STEP: float = 0.001

const SIGNS: Array[float] = [-1.0, 1.0]
const SQUARE: Array[Vector2] = [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)]

## Mallas ya armadas, por clave: el cuarto, la tienda, los retratos y las
## pruebas comparten las mismas (y armarlas cuesta).
static var _cache: Dictionary[String, ArrayMesh] = {}

## Lo que se pinta con las formas que siguen (lo cambian paint, printed,
## glowing y night_glow).
var color: Color = Color.WHITE
var surface: WorldPalette.Surface = WorldPalette.Surface.SMOOTH
var gloss: float = 0.0
## Alto de capa si fue impreso en 3D (0 = no impreso).
var layer: float = 0.0
## Luz propia: > 0 siempre, < 0 solo de noche.
var emit: float = 0.0
## Peso del balanceo (plantas, cortina, cobija colgando).
var sway: float = 0.0
## Altura del contacto (el piso, la mesa) para la oclusión horneada.
var ao_base: float = 0.0
## Sin oclusión de contacto (lo que cuelga de la pared). Las caras que miran
## hacia abajo se oscurecen igual.
var ao_enabled: bool = true
## Multiplica los lados de las formas redondas (biblia §5.1: impresora del
## piso 1,0; de mueble 0,6; lejana 0,35; cabeza 1,1).
var detail: float = 1.0
## Transformación de todo lo que se agrega (para armar grupos girados).
var origin: Transform3D = Transform3D.IDENTITY

var _positions: PackedVector3Array = PackedVector3Array()
var _normals: PackedVector3Array = PackedVector3Array()
var _colors: PackedColorArray = PackedColorArray()
var _uvs: PackedVector2Array = PackedVector2Array()
var _uv2s: PackedVector2Array = PackedVector2Array()
var _indices: PackedInt32Array = PackedInt32Array()
## Lugar de la forma que se está agregando (origin × su posición y giro) y
## la base que lleva sus normales.
var _place_xform: Transform3D = Transform3D.IDENTITY
var _normal_basis: Basis = Basis.IDENTITY


## Malla guardada con esa clave; si no está, la arma `build` (una función
## sin argumentos que devuelve la ArrayMesh) y la guarda.
static func cached(key: String, build: Callable) -> ArrayMesh:
	var mesh: ArrayMesh = _cache.get(key, null)
	if mesh == null:
		mesh = build.call()
		_cache[key] = mesh
	return mesh


# --- Qué se pinta --------------------------------------------------------------

## Color y superficie para lo que sigue. Deja lo que sigue sin capas, sin luz
## propia y sin balanceo.
func paint(hex: String, p_surface: WorldPalette.Surface = WorldPalette.Surface.SMOOTH, p_gloss: float = 0.0) -> KitMesh:
	color = Color(hex)
	surface = p_surface
	gloss = clampf(p_gloss, 0.0, MAX_GLOSS)
	layer = 0.0
	emit = 0.0
	sway = 0.0
	return self


## Plástico impreso en 3D: muestra sus capas (biblia §3.5) y un brillo
## satinado.
func printed(hex: String, layer_height: float = PieceModel.LAYER_STEP, p_gloss: float = WorldPalette.PRINTED_GLOSS) -> KitMesh:
	paint(hex, WorldPalette.Surface.SMOOTH, p_gloss)
	layer = layer_height
	return self


## Algo encendido siempre (un LED, una pantallita).
func glowing(hex: String, energy: float = 1.0) -> KitMesh:
	paint(hex)
	emit = absf(energy)
	return self


## Algo que solo se enciende de noche (una lámpara, las luces del barrio).
func night_glow(hex: String, energy: float = 1.0) -> KitMesh:
	paint(hex)
	emit = -absf(energy)
	return self


# --- Formas ----------------------------------------------------------------------

## Caja centrada en `pos` con las aristas biseladas (atrapan la luz). Sin
## bisel es una caja de 12 triángulos.
func box(size: Vector3, pos: Vector3, bevel: float = 0.01, rot_deg: Vector3 = Vector3.ZERO) -> KitMesh:
	_place(pos, rot_deg)
	var h: Vector3 = size * 0.5
	var b: float = clampf(bevel, 0.0, minf(h.x, minf(h.y, h.z)) * MAX_BEVEL)
	if b < MIN_BEVEL:
		b = 0.0
	for axis: int in 3:
		var u: int = (axis + 1) % 3
		var v: int = (axis + 2) % 3
		for s: float in SIGNS:
			var n: Vector3 = Vector3.ZERO
			n[axis] = s
			var face: PackedVector3Array = PackedVector3Array()
			for c: Vector2 in SQUARE:
				var p: Vector3 = Vector3.ZERO
				p[axis] = s * h[axis]
				p[u] = c.x * (h[u] - b)
				p[v] = c.y * (h[v] - b)
				face.append(p)
			_flat(face, n)
	if b == 0.0:
		return self
	# Las 12 aristas: una franja plana a 45°.
	for axis: int in 3:
		var u: int = (axis + 1) % 3
		var v: int = (axis + 2) % 3
		for su: float in SIGNS:
			for sv: float in SIGNS:
				var n: Vector3 = Vector3.ZERO
				n[u] = su
				n[v] = sv
				var strip: PackedVector3Array = PackedVector3Array()
				for sa: float in SIGNS:
					var on_u: Vector3 = Vector3.ZERO
					on_u[axis] = sa * (h[axis] - b)
					on_u[u] = su * h[u]
					on_u[v] = sv * (h[v] - b)
					var on_v: Vector3 = Vector3.ZERO
					on_v[axis] = sa * (h[axis] - b)
					on_v[u] = su * (h[u] - b)
					on_v[v] = sv * h[v]
					if sa < 0.0:
						strip.append(on_u)
						strip.append(on_v)
					else:
						strip.append(on_v)
						strip.append(on_u)
				_flat(strip, n.normalized())
	# Las 8 esquinas: un triángulo.
	for sx: float in SIGNS:
		for sy: float in SIGNS:
			for sz: float in SIGNS:
				var corner: PackedVector3Array = PackedVector3Array([
					Vector3(sx * h.x, sy * (h.y - b), sz * (h.z - b)),
					Vector3(sx * (h.x - b), sy * h.y, sz * (h.z - b)),
					Vector3(sx * (h.x - b), sy * (h.y - b), sz * h.z),
				])
				_flat(corner, Vector3(sx, sy, sz).normalized())
	return self


## Cilindro a lo largo de Y, centrado en `pos`. `bevel` bisela el canto de
## las tapas; con `top_radius` es un tronco de cono; sin `caps`, un caño
## abierto.
func cylinder(radius: float, height: float, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, sides: int = 16, bevel: float = 0.0, top_radius: float = -1.0, caps: bool = true) -> KitMesh:
	var r0: float = radius
	var r1: float = radius if top_radius < 0.0 else top_radius
	var hh: float = height * 0.5
	var b: float = clampf(bevel, 0.0, minf(minf(r0, r1) * 0.5, hh * MAX_BEVEL))
	if b < MIN_BEVEL:
		b = 0.0
	# Perfil para lathe: cada esquina va repetida una vez (canto vivo).
	var profile: PackedVector2Array = PackedVector2Array()
	if caps:
		profile.append_array([Vector2(0.0, -hh), Vector2(r0 - b, -hh)])
	if b > 0.0:
		profile.append_array([Vector2(r0 - b, -hh), Vector2(r0, -hh + b), Vector2(r0, -hh + b),
			Vector2(r1, hh - b), Vector2(r1, hh - b), Vector2(r1 - b, hh)])
	else:
		profile.append_array([Vector2(r0, -hh), Vector2(r1, hh)])
	if caps:
		profile.append_array([Vector2(r1 - b, hh), Vector2(0.0, hh)])
	return lathe(profile, pos, rot_deg, sides)


## Sólido de revolución alrededor de Y, con la base en `pos`. `profile`:
## puntos (radio, alto) de abajo hacia arriba. Las normales se suavizan entre
## tramos; un punto repetido deja un canto vivo. Si empieza o termina en
## radio 0, queda cerrado.
func lathe(profile: PackedVector2Array, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, sides: int = 16) -> KitMesh:
	_place(pos, rot_deg)
	if profile.size() < 2:
		return self
	var around: int = _count(sides, MIN_AROUND)
	var dirs: PackedVector3Array = _ring_directions(around)
	var base: int = _positions.size()
	for j: int in profile.size():
		var n2: Vector2 = _profile_normal(profile, j)
		for d: Vector3 in dirs:
			_vertex(d * profile[j].x + Vector3.UP * profile[j].y, d * n2.x + Vector3.UP * n2.y)
	_grid(base, around, profile.size() - 1)
	return self


## Forma redonda (superelipsoide) centrada en `pos`, de medias medidas
## `half`. `e_ring` (alrededor) y `e_lat` (de arriba a abajo): 1 es un
## elipsoide; 0,3–0,5, una caja muy redondeada. `taper` achica X y Z de
## abajo (x) hacia arriba (y): mechones, gotas, cojines.
func blob(half: Vector3, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, e_ring: float = 1.0, e_lat: float = 1.0, taper: Vector2 = Vector2.ONE, segs: Vector2i = Vector2i(16, 10)) -> KitMesh:
	_place(pos, rot_deg)
	var nu: int = _count(segs.x, MIN_AROUND)
	var nv: int = _count(segs.y, MIN_ROWS)
	# Las potencias van por columna (alrededor) y por fila (de abajo a
	# arriba), con sus derivadas: cada vértice es solo una cuenta.
	var ring: PackedVector4Array = PackedVector4Array()
	for i: int in nu + 1:
		ring.append(_superellipse(TAU * i / nu, e_ring))
	var lat: PackedVector4Array = PackedVector4Array()
	for j: int in nv + 1:
		lat.append(_superellipse(lerpf(-PI / 2.0, PI / 2.0, float(j) / nv), e_lat))
	var slope: float = (taper.y - taper.x) * 0.5
	var base: int = _positions.size()
	for j: int in nv + 1:
		# lat: (cos, sin, d cos, d sin) con potencia; k: el estrechamiento.
		var l: Vector4 = lat[j]
		var k: float = lerpf(taper.x, taper.y, (l.y + 1.0) * 0.5)
		var dk: float = slope * l.w
		for i: int in nu + 1:
			var r: Vector4 = ring[i]
			var p: Vector3 = Vector3(l.x * r.x * half.x * k, l.y * half.y, l.x * r.y * half.z * k)
			var du: Vector3 = Vector3(l.x * r.z * half.x * k, 0.0, l.x * r.w * half.z * k)
			var dv: Vector3 = Vector3((l.z * k + l.x * dk) * r.x * half.x, l.w * half.y, (l.z * k + l.x * dk) * r.y * half.z)
			var n: Vector3 = dv.cross(du)
			if n.length_squared() < 1e-18:
				n = Vector3(0.0, signf(l.y), 0.0)
			elif n.dot(p) < 0.0:
				n = -n
			_vertex(p, n)
	_grid(base, nu, nv)
	return self


## Cápsula a lo largo de +Y desde `pos` (piernas, brazos, cuello): radio
## `r0` abajo y `r1` arriba, puntas redondeadas y algo achatadas, mide
## `length` de punta a punta. `squash_z` la aplana de adelante hacia atrás.
func capsule(r0: float, r1: float, length: float, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, squash_z: float = 1.0, segs: Vector2i = Vector2i(14, 8)) -> KitMesh:
	_place(pos, rot_deg)
	var nu: int = _count(segs.x, MIN_AROUND)
	var nv: int = _count(segs.y, MIN_ROWS)
	var dirs: PackedVector3Array = _ring_directions(nu)
	var base: int = _positions.size()
	for j: int in nv + 1:
		var t: float = float(j) / nv
		# Perfil (radio, alto) y hacia dónde avanza. La normal de una forma de
		# revolución aplastada en Z: (s·cos·y', −s·r', sin·y').
		var at: Vector2 = _capsule_profile(t, r0, r1, length)
		var ahead: Vector2 = _capsule_profile(minf(t + NORMAL_STEP, 1.0), r0, r1, length) - _capsule_profile(maxf(t - NORMAL_STEP, 0.0), r0, r1, length)
		for d: Vector3 in dirs:
			var n: Vector3 = Vector3(squash_z * d.x * ahead.y, -squash_z * ahead.x, d.z * ahead.y)
			if n.length_squared() < 1e-18:
				n = Vector3.DOWN if t < 0.5 else Vector3.UP
			_vertex(Vector3(d.x * at.x, at.y, d.z * at.x * squash_z), n)
	_grid(base, nu, nv)
	return self


## Tubo redondo que sigue una curva suave por `points` (cables, el tubo del
## filamento, cordones, espaguetis): Catmull-Rom con `steps` tramos entre
## cada par de puntos, y el giro de cada anillo por transporte paralelo (no
## se retuerce en las curvas). Con `caps` se cierran las puntas.
func tube(points: PackedVector3Array, radius: float, sides: int = 6, steps: int = 4, caps: bool = true) -> KitMesh:
	_place(Vector3.ZERO, Vector3.ZERO)
	var path: PackedVector3Array = smooth_path(points, steps)
	if path.size() < 2:
		return self
	var around: int = _count(sides, MIN_ROWS)
	var tangents: PackedVector3Array = PackedVector3Array()
	for k: int in path.size():
		tangents.append((path[mini(k + 1, path.size() - 1)] - path[maxi(k - 1, 0)]).normalized())
	var sides_dirs: PackedVector3Array = _transported_frames(path, tangents)
	var base: int = _positions.size()
	for k: int in path.size():
		var side: Vector3 = sides_dirs[k]
		var up: Vector3 = tangents[k].cross(side)
		for i: int in around + 1:
			var a: float = TAU * i / around
			var d: Vector3 = side * cos(a) + up * sin(a)
			_vertex(path[k] + d * radius, d)
	_grid(base, around, path.size() - 1)
	if caps:
		for end: int in [0, path.size() - 1]:
			var ring: PackedVector3Array = PackedVector3Array()
			var side: Vector3 = sides_dirs[end]
			var up: Vector3 = tangents[end].cross(side)
			for i: int in around:
				var a: float = TAU * i / around
				ring.append(path[end] + (side * cos(a) + up * sin(a)) * radius)
			_fan(path[end], ring, -tangents[end] if end == 0 else tangents[end])
	return self


## Toroide acostado en el plano XZ, centrado en `pos` (puños, rollos, aros):
## `ring` son los radios del anillo en X y en Z, `tube_radius` su grosor.
## Con `arc` < TAU es un arco centrado hacia +Z, con las puntas cerradas.
func torus(ring: Vector2, tube_radius: float, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, arc: float = TAU, segs: Vector2i = Vector2i(20, 8)) -> KitMesh:
	_place(pos, rot_deg)
	var nu: int = _count(segs.x, MIN_AROUND)
	var nv: int = _count(segs.y, MIN_ROWS)
	var full: bool = arc >= TAU - 0.0001
	var span: float = minf(arc, TAU)
	var base: int = _positions.size()
	for j: int in nv + 1:
		var v: float = TAU * j / nv
		for i: int in nu + 1:
			var u: float = PI / 2.0 - span / 2.0 + span * i / nu
			var n: Vector3 = _torus_normal(ring, u, v)
			_vertex(_torus_center(ring, u) + n * tube_radius, n)
	_grid(base, nu, nv)
	if not full:
		for i: int in [0, nu]:
			var u: float = PI / 2.0 - span / 2.0 + span * i / nu
			var center: Vector3 = _torus_center(ring, u)
			var ahead: Vector3 = (_torus_center(ring, u + NORMAL_STEP) - _torus_center(ring, u - NORMAL_STEP)).normalized()
			var cap: PackedVector3Array = PackedVector3Array()
			for k: int in nv:
				cap.append(center + _torus_normal(ring, u, TAU * k / nv) * tube_radius)
			_fan(center, cap, -ahead if i == 0 else ahead)
	return self


## Círculo plano centrado en `pos` que mira hacia +Z.
func disc(radius: float, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, sides: int = 20) -> KitMesh:
	_place(pos, rot_deg)
	var around: int = _count(sides, MIN_AROUND)
	var ring: PackedVector3Array = PackedVector3Array()
	for i: int in around:
		var a: float = TAU * i / around
		ring.append(Vector3(cos(a), sin(a), 0.0) * radius)
	_fan(Vector3.ZERO, ring, Vector3.BACK)
	return self


## Rectángulo plano centrado en `pos` que mira hacia +Z (pósters, papeles,
## alfombras acostadas con rot_deg).
func quad(size: Vector2, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> KitMesh:
	_place(pos, rot_deg)
	var h: Vector2 = size * 0.5
	var face: PackedVector3Array = PackedVector3Array()
	for c: Vector2 in SQUARE:
		face.append(Vector3(c.x * h.x, c.y * h.y, 0.0))
	_flat(face, Vector3.BACK)
	return self


## Triángulo plano por tres puntos (banderines, flechas). Su frente mira
## hacia (b − a) × (c − a); con `two_sided` se ve de los dos lados.
func triangle(a: Vector3, b: Vector3, c: Vector3, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO, two_sided: bool = true) -> KitMesh:
	_place(pos, rot_deg)
	var n: Vector3 = (b - a).cross(c - a)
	if n.length_squared() < 4.0 * MIN_AREA * MIN_AREA:
		return self
	_flat(PackedVector3Array([a, b, c]), n.normalized())
	if two_sided:
		_flat(PackedVector3Array([a, c, b]), -n.normalized())
	return self


# --- Resultado -----------------------------------------------------------------

func is_empty() -> bool:
	return _indices.is_empty()


func triangle_count() -> int:
	return _indices.size() / 3


## La malla con todo lo agregado (vacía si no se agregó nada). Se puede
## seguir agregando y volver a cerrarla.
func commit() -> ArrayMesh:
	var mesh: ArrayMesh = ArrayMesh.new()
	if _indices.is_empty():
		return mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _positions
	arrays[Mesh.ARRAY_NORMAL] = _normals
	arrays[Mesh.ARRAY_COLOR] = _colors
	arrays[Mesh.ARRAY_TEX_UV] = _uvs
	arrays[Mesh.ARRAY_TEX_UV2] = _uv2s
	arrays[Mesh.ARRAY_INDEX] = _indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Suaviza una línea de puntos con Catmull-Rom: `steps` tramos entre cada
## par (1 = la misma línea). Pasa por todos los puntos. Los puntos
## repetidos seguidos se saltean.
static func smooth_path(points: PackedVector3Array, steps: int) -> PackedVector3Array:
	var clean: PackedVector3Array = PackedVector3Array()
	for p: Vector3 in points:
		if clean.is_empty() or not clean[clean.size() - 1].is_equal_approx(p):
			clean.append(p)
	var count: int = clean.size()
	if count < 2 or steps <= 1:
		return clean
	var out: PackedVector3Array = PackedVector3Array()
	for i: int in count - 1:
		var before: Vector3 = clean[maxi(i - 1, 0)]
		var after: Vector3 = clean[mini(i + 2, count - 1)]
		for k: int in steps:
			out.append(clean[i].cubic_interpolate(clean[i + 1], before, after, float(k) / steps))
	out.append(clean[count - 1])
	return out


# --- Interno ---------------------------------------------------------------------

func _place(pos: Vector3, rot_deg: Vector3) -> void:
	var rotation: Basis = Basis.from_euler(Vector3(deg_to_rad(rot_deg.x), deg_to_rad(rot_deg.y), deg_to_rad(rot_deg.z)))
	_place_xform = origin * Transform3D(rotation, pos)
	_normal_basis = _place_xform.basis.inverse().transposed()


## Lados de una forma redonda con el `detail` de la malla.
func _count(sides: int, minimum: int) -> int:
	return maxi(minimum, roundi(sides * detail))


## Agrega un vértice (en el espacio de la forma) con lo que se está pintando
## y devuelve su índice.
func _vertex(p: Vector3, n: Vector3) -> int:
	var at: Vector3 = _place_xform * p
	var normal: Vector3 = (_normal_basis * n).normalized()
	var ao: float = 1.0
	if ao_enabled:
		ao = lerpf(CONTACT_AO, 1.0, smoothstep(ao_base, ao_base + CONTACT_FADE, at.y))
	ao *= 1.0 - DOWN_AO * maxf(-normal.y, 0.0)
	_positions.append(at)
	_normals.append(normal)
	_colors.append(Color(color.r, color.g, color.b, ao))
	_uvs.append(Vector2(float(surface) + gloss, sway))
	_uv2s.append(Vector2(layer, emit))
	return _positions.size() - 1


## Agrega un triángulo con la cara del frente hacia donde apuntan sus
## normales (Godot dibuja el frente con los vértices en sentido horario). Los
## degenerados no se agregan.
func _tri(a: int, b: int, c: int) -> void:
	var pa: Vector3 = _positions[a]
	var geo: Vector3 = (_positions[b] - pa).cross(_positions[c] - pa)
	if geo.length_squared() <= 4.0 * MIN_AREA * MIN_AREA:
		return
	_indices.append(a)
	if geo.dot(_normals[a] + _normals[b] + _normals[c]) > 0.0:
		_indices.append(c)
		_indices.append(b)
	else:
		_indices.append(b)
		_indices.append(c)


## Polígono plano y convexo con una sola normal (caras y biseles de cajas).
func _flat(points: PackedVector3Array, n: Vector3) -> void:
	var first: int = _positions.size()
	for p: Vector3 in points:
		_vertex(p, n)
	for k: int in range(1, points.size() - 1):
		_tri(first, first + k, first + k + 1)


## Abanico plano desde `center` por un anillo cerrado de puntos (tapas).
func _fan(center: Vector3, ring: PackedVector3Array, n: Vector3) -> void:
	var middle: int = _vertex(center, n)
	var first: int = _positions.size()
	for p: Vector3 in ring:
		_vertex(p, n)
	for k: int in ring.size():
		_tri(middle, first + k, first + (k + 1) % ring.size())


## Triángulos de una grilla de (nu + 1) × (nv + 1) vértices ya agregados,
## fila por fila desde `base`.
func _grid(base: int, nu: int, nv: int) -> void:
	for j: int in nv:
		for i: int in nu:
			var a: int = base + j * (nu + 1) + i
			var c: int = a + nu + 1
			_tri(a, c, a + 1)
			_tri(a + 1, c, c + 1)


## Normal (radial, alto) de un punto del perfil de lathe: el promedio de sus
## dos tramos, o solo el suyo si el punto está repetido (canto vivo).
static func _profile_normal(profile: PackedVector2Array, j: int) -> Vector2:
	var along: Vector2 = Vector2.ZERO
	if j > 0 and not profile[j].is_equal_approx(profile[j - 1]):
		along += (profile[j] - profile[j - 1]).normalized()
	if j < profile.size() - 1 and not profile[j + 1].is_equal_approx(profile[j]):
		along += (profile[j + 1] - profile[j]).normalized()
	if along.length_squared() < 1e-12:
		return Vector2(1.0, 0.0)
	along = along.normalized()
	return Vector2(along.y, -along.x)


## Lado de cada anillo de un tubo, girado lo mínimo de uno al otro
## (transporte paralelo por doble reflexión, Wang y otros, 2008).
static func _transported_frames(path: PackedVector3Array, tangents: PackedVector3Array) -> PackedVector3Array:
	var first: Vector3 = tangents[0]
	var side: Vector3 = first.cross(Vector3.UP if absf(first.y) < 0.9 else Vector3.RIGHT).normalized()
	var frames: PackedVector3Array = PackedVector3Array([side])
	for k: int in path.size() - 1:
		var v1: Vector3 = path[k + 1] - path[k]
		var c1: float = v1.dot(v1)
		if c1 < 1e-12:
			frames.append(side)
			continue
		var side_l: Vector3 = side - v1 * (2.0 / c1 * v1.dot(side))
		var tangent_l: Vector3 = tangents[k] - v1 * (2.0 / c1 * v1.dot(tangents[k]))
		var v2: Vector3 = tangents[k + 1] - tangent_l
		var c2: float = v2.dot(v2)
		side = side_l if c2 < 1e-12 else side_l - v2 * (2.0 / c2 * v2.dot(side_l))
		# Sin errores acumulados: exactamente perpendicular a la tangente.
		side = (side - tangents[k + 1] * side.dot(tangents[k + 1])).normalized()
		frames.append(side)
	return frames


## Direcciones (cos, 0, sin) de un anillo de `around` lados, con la primera
## repetida al final (la costura).
static func _ring_directions(around: int) -> PackedVector3Array:
	var dirs: PackedVector3Array = PackedVector3Array()
	for i: int in around + 1:
		var a: float = TAU * i / around
		dirs.append(Vector3(cos(a), 0.0, sin(a)))
	return dirs


## x elevado a `e` con su signo. Lo que es casi 0 (cos 90°) queda en 0: así
## los polos de las formas redondas se cierran en un punto.
static func _signed_pow(x: float, e: float) -> float:
	if absf(x) < 1e-9:
		return 0.0
	return signf(x) * pow(absf(x), e)


## Superelipse en el ángulo `a`: (cos, sin) elevados a `e` con su signo, y
## sus derivadas (por diferencias, para que no se vayan al infinito).
static func _superellipse(a: float, e: float) -> Vector4:
	var c: float = _signed_pow(cos(a), e)
	var s: float = _signed_pow(sin(a), e)
	var dc: float = (_signed_pow(cos(a + NORMAL_STEP), e) - _signed_pow(cos(a - NORMAL_STEP), e)) / (2.0 * NORMAL_STEP)
	var ds: float = (_signed_pow(sin(a + NORMAL_STEP), e) - _signed_pow(sin(a - NORMAL_STEP), e)) / (2.0 * NORMAL_STEP)
	return Vector4(c, s, dc, ds)


## Perfil (radio, alto) de la cápsula en `t` (0 abajo, 1 arriba): puntas de
## un cuarto de círculo achatadas al 60 %.
static func _capsule_profile(t: float, r0: float, r1: float, length: float) -> Vector2:
	if t < 0.2:
		var a: float = t / 0.2 * PI / 2.0
		return Vector2(r0 * sin(a), r0 * (1.0 - cos(a)) * 0.6)
	if t > 0.8:
		var b: float = (1.0 - t) / 0.2 * PI / 2.0
		return Vector2(r1 * sin(b), length - r1 * (1.0 - cos(b)) * 0.6)
	var m: float = (t - 0.2) / 0.6
	return Vector2(lerpf(r0, r1, m), lerpf(r0 * 0.6, length - r1 * 0.6, m))


## Centro del tubo de un toroide (elipse de radios ring.x, ring.y).
static func _torus_center(ring: Vector2, u: float) -> Vector3:
	return Vector3(cos(u) * ring.x, 0.0, sin(u) * ring.y)


## Normal del toroide: hacia afuera de la elipse (perpendicular a ella) y
## girada `v` alrededor del tubo.
static func _torus_normal(ring: Vector2, u: float, v: float) -> Vector3:
	var out: Vector3 = Vector3(cos(u) * ring.y, 0.0, sin(u) * ring.x).normalized()
	return out * cos(v) + Vector3.UP * sin(v)

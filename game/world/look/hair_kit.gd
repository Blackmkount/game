class_name HairKit
extends RefCounted
## El pelo del protagonista como UNA superficie continua (biblia de arte §7.6,
## idea del pelo de "Pixel HD"): un casquete deformado en 14 mechones
## redondos que bajan desde la coronilla (6 grandes atrás, uno sobre cada
## oreja, uno en cada sien y las 4 lenguas redondeadas del flequillo, barrido
## hacia un lado), patillas y nuca, y 3 mechoncitos sueltos en la coronilla.
## Al ser una sola superficie, el contorno del personaje dibuja solo la
## silueta (nada de "piedras" ni "coliflor") y el pliegue entre dos mechones
## es un surco suave, no un borde.
##
## El color va por vértice: el café de base, el brillo pintado en lo alto de
## cada mechón, los pliegues oscuros y el borde de abajo en sombra.
##
## Coordenadas de la cabeza: +Z es la cara, +Y arriba. `u` da la vuelta
## alrededor (0 es el frente, crece hacia +X) y `v` va del borde del pelo (0)
## a la coronilla (1). Las latitudes van en radianes (0 = el ecuador).

## Línea del borde (latitud) al frente (entre las lenguas del flequillo), a
## los lados (sobre las orejas) y en la nuca.
const FRONT_LINE: float = 0.38
const SIDE_LINE: float = 0.04
const BACK_LINE: float = -0.78
## Ángulos (desde el frente) donde el borde pasa del flequillo a los lados y
## de los lados a la nuca.
const FRONT_EDGE: Vector2 = Vector2(0.75, 1.0)
const BACK_EDGE: Vector2 = Vector2(1.6, 2.3)
## Mechones alrededor de la cabeza, de un lado al otro pasando por el frente:
## dónde empieza cada uno (ángulo desde el frente, el último cierra la
## vuelta) y lo que baja su punta (radianes de latitud): atrás, 6 mechones
## (3 por lado, de anchos distintos para que la espalda no se vea pareja);
## sobre cada oreja, uno; en cada sien, otro; y al frente, las 4 lenguas del
## flequillo.
const LOCK_EDGES: Array[float] = [
	-3.1416, -2.58, -2.16, -1.7638, -1.3, -0.82, -0.4, 0.02, 0.43, 0.82, 1.3, 1.7638, 2.3, 2.74, 3.1416,
]
const LOCK_DEPTHS: Array[float] = [0.14, 0.1, 0.13, 0.06, 0.04, 0.16, 0.23, 0.25, 0.2, 0.04, 0.06, 0.11, 0.15, 0.1]
## Las lenguas se tuercen hacia un lado (barridas): exponente de su forma.
const SKEW: float = 0.72
## Patillas: delante de las orejas, cuánto bajan y su ancho.
const SIDEBURN_AT: float = 1.36
const SIDEBURN_DEPTH: float = 0.26
const SIDEBURN_WIDTH: float = 0.08
## Cuánto se abomba cada mechón (fracción del radio) y cuánto se enrosca
## hacia un lado al subir (radianes alrededor por radián de latitud).
const RIDGE: float = 0.055
const SWIRL: float = 0.2
## Latitudes donde los mechones (lomo y pliegue) se apagan hacia la
## coronilla: arriba queda un casco liso con brillo, sin remolino marcado.
const CROWN_FADE: Vector2 = Vector2(0.6, 1.1)
## El borde se mete hacia la cabeza (la línea del pelo queda limpia).
const EDGE_TUCK: float = 0.9
## Grilla: columnas alrededor y filas (con `detail` 1,0). Las columnas se
## juntan al frente, donde están las lenguas del flequillo.
const COLUMNS: int = 68
const ROWS: int = 14
const FRONT_DENSITY: float = 0.36
## Brillo del pelo.
const GLOSS: float = 0.3


## Agrega el pelo a `kit` (con su `detail`): un casquete de centro `center`
## y radios `radii` (un poco más grande que el cráneo).
static func add_to(kit: KitMesh, center: Vector3, radii: Vector3) -> void:
	var nu: int = maxi(24, roundi(COLUMNS * kit.detail))
	var nv: int = maxi(6, roundi(ROWS * kit.detail))
	var points: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	var base: Color = Color(LookPalette.HAIR)
	var mid: Color = Color(LookPalette.HAIR_MID)
	var fold: Color = Color(LookPalette.HAIR_FOLD)
	var shine: Color = Color(LookPalette.HAIR_SHINE)
	for j: int in nv + 1:
		var v: float = float(j) / nv
		for i: int in nu + 1:
			var u: float = _column_angle(float(i) / nu)
			var line: float = hairline(u)
			var lat: float = lerpf(line, PI / 2.0, pow(v, 1.4))
			var ridge: float = _ridge(u, lat)
			# Los mechones se abomban hacia afuera, menos cerca de la coronilla.
			var crown: float = 1.0 - smoothstep(CROWN_FADE.x, CROWN_FADE.y, lat)
			var r: float = 1.0 + RIDGE * (ridge - 0.5) * crown
			r *= lerpf(EDGE_TUCK, 1.0, smoothstep(0.0, 0.16, v))
			points.append(center + _direction(u, lat) * radii * r)
			# Color: pliegue entre mechones, brillo arriba de cada uno, borde de
			# abajo en sombra.
			var color: Color = base.lerp(fold, (1.0 - smoothstep(0.1, 0.55, ridge)) * crown * 0.85)
			var band: float = smoothstep(0.45, 0.75, lat) * crown
			color = color.lerp(mid, smoothstep(0.55, 0.85, ridge) * band)
			color = color.lerp(shine, smoothstep(0.82, 0.97, ridge) * band * 0.85)
			color = color.lerp(fold, (1.0 - smoothstep(0.0, 0.2, v)) * 0.7)
			colors.append(color)
	kit.paint(LookPalette.HAIR, WorldPalette.Surface.HAIR, GLOSS)
	kit.sheet(points, _normals(points, nu, nv, center), colors, nu, nv)
	_add_tufts(kit, center, radii)


## Latitud del borde del pelo en el ángulo `u`: el flequillo en lenguas al
## frente, las patillas, la línea sobre las orejas y los mechones de la nuca.
static func hairline(u: float) -> float:
	var a: float = absf(wrapf(u, -PI, PI))
	var front: float = 1.0 - smoothstep(FRONT_EDGE.x, FRONT_EDGE.y, a)
	var back: float = smoothstep(BACK_EDGE.x, BACK_EDGE.y, a)
	var line: float = lerpf(lerpf(SIDE_LINE, FRONT_LINE, front), BACK_LINE, back)
	line -= SIDEBURN_DEPTH * exp(-pow((a - SIDEBURN_AT) / SIDEBURN_WIDTH, 2.0))
	var lock: Vector2 = _lock_at(u)
	return line - LOCK_DEPTHS[int(lock.x)] * pow(sin(PI * lock.y), 0.6)


## Mechón en el ángulo `u` y dónde cae dentro de él (0–1, torcido hacia un
## lado): (índice, posición).
static func _lock_at(u: float) -> Vector2:
	var a: float = wrapf(u, -PI, PI)
	var index: int = LOCK_EDGES.size() - 2
	for k: int in LOCK_EDGES.size() - 1:
		if a < LOCK_EDGES[k + 1]:
			index = k
			break
	var t: float = clampf((a - LOCK_EDGES[index]) / (LOCK_EDGES[index + 1] - LOCK_EDGES[index]), 0.0, 1.0)
	return Vector2(index, pow(t, SKEW))


## Cuánto se abomba el mechón en (u, lat), 0 en el pliegue y 1 en el lomo.
## Los mechones se enroscan un poco al subir hacia la coronilla.
static func _ridge(u: float, lat: float) -> float:
	var lock: Vector2 = _lock_at(u + SWIRL * (lat - hairline(u)))
	return pow(sin(PI * lock.y), 1.2)


## Ángulo de la columna `s` (0–1): más columnas al frente.
static func _column_angle(s: float) -> float:
	return TAU * s - FRONT_DENSITY * sin(TAU * s)


static func _direction(u: float, lat: float) -> Vector3:
	return Vector3(sin(u) * cos(lat), sin(lat), cos(u) * cos(lat))


## Normales de la grilla por diferencias (la costura da la vuelta), hacia
## afuera. En la coronilla, todas las columnas se juntan: hacia arriba.
static func _normals(points: PackedVector3Array, nu: int, nv: int, center: Vector3) -> PackedVector3Array:
	var normals: PackedVector3Array = PackedVector3Array()
	var width: int = nu + 1
	for j: int in nv + 1:
		for i: int in nu + 1:
			var left: int = (i - 1 + nu) % nu
			var right: int = (i + 1) % nu
			var along: Vector3 = points[j * width + right] - points[j * width + left]
			var up: Vector3 = points[mini(j + 1, nv) * width + i] - points[maxi(j - 1, 0) * width + i]
			var n: Vector3 = along.cross(up)
			if n.length_squared() < 1e-14:
				n = Vector3.UP
			n = n.normalized()
			if n.dot(points[j * width + i] - center) < 0.0:
				n = -n
			normals.append(n)
	return normals


## Tres mechoncitos sueltos en la coronilla: mechones finos que nacen
## adentro del pelo, siguen el remolino hacia la nuca y levantan apenas la
## punta (no una corona de puntas): (ángulo alrededor, latitud, tamaño).
const TUFTS: Array[Vector3] = [Vector3(PI - 1.15, 1.02, 0.75), Vector3(PI + 0.05, 1.32, 1.0), Vector3(PI + 0.95, 1.08, 0.62)]
const TUFT_HALF: Vector3 = Vector3(0.027, 0.056, 0.013)
## Cuánto se levanta la punta (0 = acostada sobre el pelo) y cuánto del
## mechón queda hundido en el pelo (fracción de su largo).
const TUFT_LIFT: float = 0.24
const TUFT_SUNK: float = 0.3


static func _add_tufts(kit: KitMesh, center: Vector3, radii: Vector3) -> void:
	kit.paint(LookPalette.HAIR, WorldPalette.Surface.HAIR, GLOSS)
	var saved: Transform3D = kit.origin
	for tuft: Vector3 in TUFTS:
		var out: Vector3 = _direction(tuft.x, tuft.y)
		var root: Vector3 = center + out * radii
		# Hacia la nuca por la superficie (girado como el remolino), con la
		# punta un poco levantada.
		var along: Vector3 = (_direction(tuft.x + SWIRL * 0.3, tuft.y - 0.3) - out).normalized()
		var up: Vector3 = (along + out * TUFT_LIFT).normalized()
		var half: Vector3 = TUFT_HALF * tuft.z
		kit.origin = saved * Transform3D(_basis_up(up, out), root)
		kit.blob(half, Vector3(0.0, half.y * (1.0 - 2.0 * TUFT_SUNK), 0.0), Vector3.ZERO, 1.0, 1.0, Vector2(1.0, 0.6), Vector2i(8, 6))
	kit.origin = saved


## Base que lleva +Y hacia `up` y +Z hacia afuera (`out`).
static func _basis_up(up: Vector3, out: Vector3) -> Basis:
	var side: Vector3 = up.cross(out).normalized()
	return Basis(side, up, side.cross(up).normalized())

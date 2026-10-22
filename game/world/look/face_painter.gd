class_name FacePainter
extends RefCounted
## La cara del protagonista dibujada por código (biblia de arte §7.5), sin
## archivos de imagen: un atlas de 8 expresiones en celdas de 128 × 128 que
## kit_head.gdshader proyecta sobre la cabeza (proyección cilíndrica alrededor
## de su eje vertical). Ojos grandes con dos brillos, cejas gruesas y amables,
## nariz apenas marcada, boca chica y rubor (idea de la cara de "Juguete").
##
## Cada celda mide SPAN (un ángulo alrededor de la cabeza) por HEIGHT metros;
## las formas se dibujan en metros sobre la cara, con el borde suavizado por
## cuenta (cobertura según la distancia al borde): mismo resultado que pintar
## más grande y achicar, mucho más barato. El fondo de cada celda es el color
## de la piel (el shader lo pone encima de la piel sin que se note el borde).
## El canal alfa es la máscara de los ojos abiertos: ahí adentro el shader
## corre el iris y la pupila hacia donde mira (`gaze`).

## Expresiones: columna de cada una en el atlas.
enum Face { NEUTRAL, BLINK, HAPPY, WORRIED, TALK_A, TALK_B, FOCUSED, SURPRISE }

const CELL: int = 128
const CELLS: int = 8
## Lo que cubre una celda sobre la cabeza: el ángulo alrededor de su eje y el
## alto (m). El ancho en metros es el de ese arco con el radio de la cara.
const SPAN: float = deg_to_rad(120.0)
const HEIGHT: float = 0.30
const RADIUS: float = 0.18
const WIDTH: float = SPAN * RADIUS

## Medidas de la cara (m), desde el centro de la línea de los ojos, con y
## hacia abajo. Cada ojo mide 13 % × 20 % de la celda (≈ 4,9 × 6,0 cm).
const EYE_X: float = 0.062
const EYE_HALF: Vector2 = Vector2(0.0245, 0.030)
const IRIS_SCALE: float = 0.8
const PUPIL_SCALE: float = 0.42
const LINE: float = 0.0045
const BROW_Y: float = -0.052
const BROW_INNER: float = 0.038
const BROW_OUTER: float = 0.088
const BROW_THICK: float = 0.0105
const NOSE_Y: float = 0.040
const MOUTH_Y: float = 0.074
const BLUSH_X: float = 0.090
const BLUSH_Y: float = 0.040
const BLUSH_HALF: Vector2 = Vector2(0.021, 0.0115)

static var _atlas: ImageTexture


## El atlas (se pinta una vez y queda en caché).
static func atlas() -> ImageTexture:
	if _atlas != null:
		return _atlas
	var image: Image = Image.create(CELL * CELLS, CELL, false, Image.FORMAT_RGBA8)
	var skin: Color = Color(LookPalette.SKIN)
	image.fill(Color(skin.r, skin.g, skin.b, 0.0))
	for expression: int in CELLS:
		_paint(image, expression as Face)
	image.generate_mipmaps()
	_atlas = ImageTexture.create_from_image(image)
	return _atlas


static func _paint(image: Image, expression: Face) -> void:
	var cell: FaceCell = FaceCell.new(image, int(expression) * CELL)
	# Rubor y nariz, abajo de todo.
	var blush: Color = Color(LookPalette.BLUSH)
	blush.a = LookPalette.BLUSH_ALPHA
	for side: float in [-1.0, 1.0]:
		cell.ellipse(Vector2(BLUSH_X * side, BLUSH_Y), BLUSH_HALF, blush, 0.008)
	var shade: Color = Color(LookPalette.SKIN_SHADE)
	cell.ellipse(Vector2(0.0, NOSE_Y), Vector2(0.0085, 0.0055), shade, 0.004)

	var ink: Color = Color(LookPalette.EYE_LINE)
	var brow: Color = Color(LookPalette.BROWS)
	var mouth: Color = Color(LookPalette.MOUTH)
	for side: float in [-1.0, 1.0]:
		var eye: Vector2 = Vector2(EYE_X * side, 0.0)
		match expression:
			Face.BLINK:
				# Párpados cerrados: una curva suave hacia abajo.
				cell.arc(eye + Vector2(0.0, 0.004), Vector2(EYE_HALF.x * 0.95, 0.010), LINE * 1.2, ink, false)
			Face.HAPPY:
				# Ojos felices "^ ^".
				cell.arc(eye + Vector2(0.0, 0.008), Vector2(EYE_HALF.x * 0.9, 0.017), LINE * 1.3, ink, true)
			Face.WORRIED:
				cell.eye(eye, EYE_HALF * 0.9, side, 0.0)
			Face.FOCUSED:
				# Un poco entrecerrados: el párpado de arriba baja recto.
				cell.eye(eye + Vector2(0.0, 0.002), EYE_HALF, side, 0.34)
			Face.SURPRISE:
				cell.eye(eye + Vector2(0.0, -0.002), EYE_HALF * 1.12, side, 0.0)
			_:
				cell.eye(eye, EYE_HALF, side, 0.0)
		# Cejas: gruesas, de puntas redondas y un poco arqueadas.
		var lift: float = 0.0
		var tilt: float = 0.0
		match expression:
			Face.HAPPY:
				lift = -0.006
			Face.WORRIED:
				lift = -0.004
				tilt = -0.012
			Face.FOCUSED:
				lift = 0.004
				tilt = 0.006
			Face.SURPRISE:
				lift = -0.014
		var inner: Vector2 = Vector2(BROW_INNER * side, BROW_Y + lift + tilt)
		var outer: Vector2 = Vector2(BROW_OUTER * side, BROW_Y + lift - tilt * 0.4 + 0.004)
		var middle: Vector2 = (inner + outer) * 0.5 + Vector2(0.0, -0.0045)
		cell.stroke(PackedVector2Array([inner, middle, outer]), BROW_THICK, brow)

	match expression:
		Face.HAPPY:
			cell.open_mouth(Vector2(0.0, MOUTH_Y - 0.008), Vector2(0.026, 0.024))
		Face.SURPRISE:
			cell.open_mouth(Vector2(0.0, MOUTH_Y - 0.009), Vector2(0.030, 0.029))
		Face.WORRIED:
			cell.ellipse(Vector2(0.0, MOUTH_Y + 0.003), Vector2(0.0085, 0.0105), mouth, 0.0)
		Face.TALK_A:
			cell.ellipse(Vector2(0.0, MOUTH_Y + 0.001), Vector2(0.015, 0.013), mouth, 0.0)
			cell.ellipse(Vector2(0.0, MOUTH_Y + 0.008), Vector2(0.009, 0.005), Color(LookPalette.BLUSH), 0.0)
		Face.TALK_B:
			cell.ellipse(Vector2(0.0, MOUTH_Y), Vector2(0.019, 0.0065), mouth, 0.0)
		Face.FOCUSED:
			cell.stroke(PackedVector2Array([Vector2(-0.015, MOUTH_Y), Vector2(0.015, MOUTH_Y + 0.001)]), LINE * 1.1, mouth)
		_:
			# Sonrisa chica.
			cell.arc(Vector2(0.0, MOUTH_Y - 0.004), Vector2(0.016, 0.009), LINE * 1.15, mouth, false)


## Pinta formas en una celda del atlas, en metros sobre la cara (centro de la
## línea de los ojos, y hacia abajo), con el borde suavizado por cuenta.
class FaceCell:
	var image: Image
	var left: int
	## Metros por píxel de la celda en x y en y, y su promedio (para el borde).
	var meters: Vector2 = Vector2(FacePainter.WIDTH, FacePainter.HEIGHT) / FacePainter.CELL
	var soft: float = (meters.x + meters.y) * 0.5

	func _init(p_image: Image, p_left: int) -> void:
		image = p_image
		left = p_left

	## Ojo abierto: contorno de tinta, iris que se aclara hacia abajo, pupila
	## y dos brillos. `lid` baja el párpado de arriba (0 = abierto). Marca la
	## máscara del ojo en el alfa.
	func eye(center: Vector2, half: Vector2, side: float, lid: float) -> void:
		var lid_y: float = center.y - half.y + lid * 2.0 * half.y
		var box: Rect2i = _box(center, half + Vector2(0.01, 0.01))
		var ink: Color = Color(LookPalette.EYE_LINE)
		var iris_top: Color = Color(LookPalette.IRIS_TOP)
		var iris_bottom: Color = Color(LookPalette.IRIS_BOTTOM)
		var pupil: Color = Color(LookPalette.PUPIL)
		var shine: Color = Color(LookPalette.EYE_SHINE)
		var iris_half: Vector2 = half * FacePainter.IRIS_SCALE
		var iris_center: Vector2 = center + Vector2(0.0, half.y * 0.06)
		var pupil_half: Vector2 = half * FacePainter.PUPIL_SCALE
		var big_shine: Vector2 = center + Vector2(-half.x * 0.30, -half.y * 0.34)
		var small_shine: Vector2 = center + Vector2(half.x * 0.36, half.y * 0.40)
		for y: int in range(box.position.y, box.end.y):
			for x: int in range(box.position.x, box.end.x):
				var p: Vector2 = _at(x, y)
				# Párpado: corta la parte de arriba con una línea recta.
				var lid_cut: float = clampf((p.y - lid_y) / soft + 0.5, 0.0, 1.0) if lid > 0.0 else 1.0
				var outline: float = _ellipse_cover(p, center, half) * lid_cut
				if outline <= 0.0:
					continue
				var color: Color = ink
				var t: float = clampf((p.y - (iris_center.y - iris_half.y)) / (2.0 * iris_half.y), 0.0, 1.0)
				color = color.lerp(iris_top.lerp(iris_bottom, t * t), _ellipse_cover(p, iris_center, iris_half))
				color = color.lerp(pupil, _ellipse_cover(p, iris_center, pupil_half))
				if lid > 0.0:
					# Bajo el párpado, una franja de tinta (la línea de las pestañas).
					color = color.lerp(ink, 1.0 - clampf((p.y - lid_y - FacePainter.LINE * 1.4) / soft + 0.5, 0.0, 1.0))
				color = color.lerp(shine, _ellipse_cover(p, big_shine, half * Vector2(0.36, 0.28)))
				color = color.lerp(shine, _ellipse_cover(p, small_shine, half * Vector2(0.16, 0.12)) * 0.9)
				_blend(x, y, color, outline)
				var under: Color = image.get_pixel(x, y)
				under.a = maxf(under.a, outline)
				image.set_pixel(x, y, under)
		# La línea de arriba más gruesa y una pestaña afuera.
		if lid <= 0.0:
			arc(center + Vector2(0.0, half.y * 0.25), Vector2(half.x * 1.06, half.y * 1.2), FacePainter.LINE * 1.5, ink, true)
		stroke(PackedVector2Array([
			center + Vector2(side * half.x * 0.80, lid_y + half.y * 0.18),
			center + Vector2(side * half.x * 1.30, lid_y - half.y * 0.10),
		]), FacePainter.LINE * 1.1, ink)

	## Elipse llena; con `feather` el borde se difumina esos metros.
	func ellipse(center: Vector2, half: Vector2, color: Color, feather: float) -> void:
		var box: Rect2i = _box(center, half + Vector2(feather, feather) + Vector2(0.005, 0.005))
		for y: int in range(box.position.y, box.end.y):
			for x: int in range(box.position.x, box.end.x):
				var p: Vector2 = _at(x, y)
				var cover: float
				if feather > 0.0:
					var d: float = ((p - center) / half).length()
					cover = 1.0 - smoothstep(1.0 - feather / minf(half.x, half.y), 1.0 + feather / minf(half.x, half.y), d)
				else:
					cover = _ellipse_cover(p, center, half)
				if cover > 0.0:
					_blend(x, y, color, cover * color.a)

	## Media elipse como línea (`width` metros): con `up` es un arco "∩", si no
	## "∪" (sonrisa, párpados cerrados).
	func arc(center: Vector2, half: Vector2, width: float, color: Color, up: bool) -> void:
		var steps: int = 14
		var points: PackedVector2Array = PackedVector2Array()
		for i: int in steps + 1:
			var a: float = PI * float(i) / steps
			points.append(center + Vector2(-cos(a) * half.x, (-sin(a) if up else sin(a)) * half.y))
		stroke(points, width, color)

	## Línea gruesa de puntas redondas por varios puntos.
	func stroke(points: PackedVector2Array, width: float, color: Color) -> void:
		var low: Vector2 = points[0]
		var high: Vector2 = points[0]
		for p: Vector2 in points:
			low = low.min(p)
			high = high.max(p)
		var box: Rect2i = _box((low + high) * 0.5, (high - low) * 0.5 + Vector2(width, width) + Vector2(0.004, 0.004))
		var radius: float = width * 0.5
		for y: int in range(box.position.y, box.end.y):
			for x: int in range(box.position.x, box.end.x):
				var p: Vector2 = _at(x, y)
				var d: float = INF
				for k: int in points.size() - 1:
					d = minf(d, _segment_distance(p, points[k], points[k + 1]))
				var cover: float = clampf((radius - d) / soft + 0.5, 0.0, 1.0)
				if cover > 0.0:
					_blend(x, y, color, cover * color.a)

	## Boca abierta y feliz: media elipse con el borde recto arriba y la lengua.
	func open_mouth(center: Vector2, half: Vector2) -> void:
		var box: Rect2i = _box(center + Vector2(0.0, half.y * 0.5), half + Vector2(0.005, 0.005))
		var mouth: Color = Color(LookPalette.MOUTH)
		var tongue: Color = Color(LookPalette.BLUSH)
		var tongue_center: Vector2 = center + Vector2(0.0, half.y * 0.78)
		var tongue_half: Vector2 = half * Vector2(0.55, 0.32)
		for y: int in range(box.position.y, box.end.y):
			for x: int in range(box.position.x, box.end.x):
				var p: Vector2 = _at(x, y)
				var cover: float = _ellipse_cover(p, center, half) * clampf((p.y - center.y) / soft + 0.5, 0.0, 1.0)
				if cover <= 0.0:
					continue
				var color: Color = mouth.lerp(tongue, _ellipse_cover(p, tongue_center, tongue_half))
				_blend(x, y, color, cover)

	## Centro del píxel (x, y) de la imagen, en metros sobre la cara.
	func _at(x: int, y: int) -> Vector2:
		return Vector2((float(x - left) + 0.5) * meters.x - FacePainter.WIDTH * 0.5, (float(y) + 0.5) * meters.y - FacePainter.HEIGHT * 0.5)

	## Píxeles de la celda que tocan el rectángulo de centro y medias medidas
	## dados (m).
	func _box(center: Vector2, half: Vector2) -> Rect2i:
		var x0: int = clampi(floori((center.x - half.x + FacePainter.WIDTH * 0.5) / meters.x), 0, FacePainter.CELL)
		var x1: int = clampi(ceili((center.x + half.x + FacePainter.WIDTH * 0.5) / meters.x), 0, FacePainter.CELL)
		var y0: int = clampi(floori((center.y - half.y + FacePainter.HEIGHT * 0.5) / meters.y), 0, FacePainter.CELL)
		var y1: int = clampi(ceili((center.y + half.y + FacePainter.HEIGHT * 0.5) / meters.y), 0, FacePainter.CELL)
		return Rect2i(left + x0, y0, x1 - x0, y1 - y0)

	## Cuánto del píxel en `p` cae dentro de la elipse (0–1), por la distancia
	## aproximada a su borde.
	func _ellipse_cover(p: Vector2, center: Vector2, half: Vector2) -> float:
		var q: Vector2 = (p - center) / half
		var length: float = q.length()
		var edge: float = (1.0 - length) * minf(half.x, half.y)
		return clampf(edge / soft + 0.5, 0.0, 1.0)

	func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
		var ab: Vector2 = b - a
		var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-12), 0.0, 1.0)
		return (p - (a + ab * t)).length()

	## Pone `color` encima del píxel con esa cobertura; no toca el alfa (la
	## máscara de los ojos).
	func _blend(x: int, y: int, color: Color, cover: float) -> void:
		var under: Color = image.get_pixel(x, y)
		var mixed: Color = under.lerp(color, clampf(cover, 0.0, 1.0))
		mixed.a = under.a
		image.set_pixel(x, y, mixed)

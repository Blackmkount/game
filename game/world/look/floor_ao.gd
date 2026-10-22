class_name FloorAO
extends RefCounted
## Mapa de oclusión del piso (biblia de arte §3.5): una textura chica del piso
## entero con una mancha suave bajo cada mueble, impresora y rincón (los
## obstáculos del piso). Se pinta una vez por distribución del cuarto y el
## sombreador del mundo la lee (cc_floor_ao en world_light.gdshaderinc): no
## agrega llamadas de dibujo ni transparencias.

## Texeles por lado (el cuarto de 6 m: 6,25 cm por texel).
const TEXELS: int = 96
## Ancho del borde suave, centrado en el borde de cada obstáculo (m).
const SOFT_EDGE: float = 0.2
## Cuánto oscurece bajo un obstáculo (−45 %).
const STRENGTH: float = 0.45


## Pinta el mapa del piso `room` (rectángulo en x, z) con los obstáculos
## `obstacles` y lo publica para los sombreadores. Devuelve la textura.
static func publish(room: Rect2, obstacles: Array[Rect2]) -> ImageTexture:
	# Una textura nueva cada vez (9 KB, una vez por distribución): la anterior
	# se libera cuando ya nadie la usa.
	var texture: ImageTexture = ImageTexture.create_from_image(paint(room, obstacles))
	RenderingServer.global_shader_parameter_set(&"cc_floor_ao", texture)
	return texture


## El mapa: TEXELS × TEXELS en escala de grises, la columna i es x y la fila
## j es z (como lo lee el sombreador). 1 = nada; 1 − STRENGTH bajo un
## obstáculo. Cada obstáculo pinta solo los texeles que alcanza su mancha;
## donde dos se tocan queda la más oscura (no se suman).
static func paint(room: Rect2, obstacles: Array[Rect2]) -> Image:
	var light: PackedByteArray = PackedByteArray()
	light.resize(TEXELS * TEXELS)
	light.fill(255)
	var texel: Vector2 = room.size / TEXELS
	var half_edge: float = SOFT_EDGE * 0.5
	for obstacle: Rect2 in obstacles:
		var reach: Rect2 = obstacle.grow(half_edge)
		var first: Vector2i = Vector2i(((reach.position - room.position) / texel).floor())
		var last: Vector2i = Vector2i(((reach.end - room.position) / texel).ceil())
		var center: Vector2 = obstacle.get_center()
		var half_size: Vector2 = obstacle.size * 0.5
		for j: int in range(clampi(first.y, 0, TEXELS), clampi(last.y, 0, TEXELS)):
			for i: int in range(clampi(first.x, 0, TEXELS), clampi(last.x, 0, TEXELS)):
				var point: Vector2 = room.position + (Vector2(i, j) + Vector2(0.5, 0.5)) * texel
				var q: Vector2 = (point - center).abs() - half_size
				var outside: float = q.max(Vector2.ZERO).length() + minf(maxf(q.x, q.y), 0.0)
				var dark: float = STRENGTH * (1.0 - smoothstep(-half_edge, half_edge, outside))
				var index: int = j * TEXELS + i
				light[index] = mini(light[index], roundi((1.0 - dark) * 255.0))
	return Image.create_from_data(TEXELS, TEXELS, false, Image.FORMAT_L8, light)

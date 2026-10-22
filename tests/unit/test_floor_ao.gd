extends GutTest
## Mapa de oclusión del piso (FloorAO, biblia de arte §3.5): 96 × 96, más
## oscuro bajo los obstáculos, con el borde suave, sin sumar manchas, y la
## textura que leen los sombreadores lleva lo último que se pintó.

const ROOM: Rect2 = Rect2(-3.0, -3.0, 6.0, 6.0)
## El mapa guarda 8 bits por texel.
const BYTE: float = 1.5 / 255.0
const DESK: Rect2 = Rect2(-2.9, -1.9, 1.2, 1.3)


func test_the_map_is_96_by_96_and_white_without_obstacles() -> void:
	var image: Image = FloorAO.paint(ROOM, [] as Array[Rect2])
	assert_eq(image.get_size(), Vector2i(96, 96))
	assert_eq(FloorAO.TEXELS, 96)
	assert_eq(image.get_format(), Image.FORMAT_L8, "Un canal: barato y sin transparencia")
	assert_almost_eq(_darkest(image), 1.0, BYTE, "Sin obstáculos no oscurece nada")


func test_a_texel_under_an_obstacle_is_darker_than_a_free_one() -> void:
	var image: Image = FloorAO.paint(ROOM, [DESK] as Array[Rect2])
	var under: float = _light(image, DESK.get_center())
	var free: float = _light(image, Vector2(1.5, 1.5))
	assert_lt(under, free, "Bajo el mueble es más oscuro")
	assert_almost_eq(under, 1.0 - FloorAO.STRENGTH, BYTE, "Con toda la fuerza en el medio")
	assert_almost_eq(free, 1.0, BYTE, "Lejos de todo, nada")


func test_the_edge_is_soft_and_centered_on_the_obstacle_border() -> void:
	var image: Image = FloorAO.paint(ROOM, [DESK] as Array[Rect2])
	var half_edge: float = FloorAO.SOFT_EDGE / 2.0
	var z: float = DESK.get_center().y
	var texel: float = ROOM.size.x / FloorAO.TEXELS
	assert_almost_eq(_light(image, Vector2(DESK.end.x - half_edge - texel, z)), 1.0 - FloorAO.STRENGTH, BYTE, "Adentro, toda la fuerza")
	assert_almost_eq(_light(image, Vector2(DESK.end.x + half_edge + texel, z)), 1.0, BYTE, "Afuera del borde suave, nada")
	var previous: float = 0.0
	for i: int in 12:
		var x: float = DESK.end.x - half_edge - texel + i * texel / 2.0
		var light: float = _light(image, Vector2(x, z))
		assert_true(light >= previous - BYTE, "Se aclara hacia afuera sin saltos atrás (x = %.3f)" % x)
		previous = light
	var border: float = _light(image, Vector2(DESK.end.x, z))
	assert_between(border, 1.0 - FloorAO.STRENGTH * 0.75, 1.0 - FloorAO.STRENGTH * 0.25, "En el borde, a medias")


func test_overlapping_obstacles_do_not_add_up() -> void:
	var one: Image = FloorAO.paint(ROOM, [DESK] as Array[Rect2])
	var printer_on_desk: Rect2 = Rect2(DESK.position + Vector2(0.2, 0.2), Vector2(0.5, 0.5))
	var two: Image = FloorAO.paint(ROOM, [DESK, printer_on_desk] as Array[Rect2])
	assert_eq(two.get_data(), one.get_data(), "Una impresora sobre un mueble no oscurece el doble")


func test_obstacles_outside_the_room_are_clipped() -> void:
	var outside: Rect2 = Rect2(2.8, 2.8, 1.0, 1.0)
	var image: Image = FloorAO.paint(ROOM, [outside, Rect2(-10.0, -10.0, 1.0, 1.0)] as Array[Rect2])
	assert_almost_eq(_light(image, Vector2(2.95, 2.95)), 1.0 - FloorAO.STRENGTH, BYTE, "Lo que cae adentro se pinta")
	assert_almost_eq(_light(image, Vector2(0.0, 0.0)), 1.0, BYTE)


func test_publish_gives_the_texture_of_the_last_paint() -> void:
	var first: ImageTexture = FloorAO.publish(ROOM, [DESK] as Array[Rect2])
	assert_eq(first.get_image().get_data(), FloorAO.paint(ROOM, [DESK] as Array[Rect2]).get_data())
	var corner: Rect2 = Rect2(1.0, 1.0, 0.8, 0.4)
	var second: ImageTexture = FloorAO.publish(ROOM, [corner] as Array[Rect2])
	assert_eq(second.get_image().get_data(), FloorAO.paint(ROOM, [corner] as Array[Rect2]).get_data(), "Con lo último que se pintó")
	assert_eq(second.get_size(), Vector2(FloorAO.TEXELS, FloorAO.TEXELS))


func _light(image: Image, point: Vector2) -> float:
	var texel: Vector2i = Vector2i(((point - ROOM.position) / ROOM.size * FloorAO.TEXELS).floor())
	return image.get_pixelv(texel).r


func _darkest(image: Image) -> float:
	var darkest: float = 1.0
	for j: int in image.get_height():
		for i: int in image.get_width():
			darkest = minf(darkest, image.get_pixel(i, j).r)
	return darkest

class_name PixelTextures
extends RefCounted
## Texturas pixel art generadas por código: madera, ladrillo, ventana,
## pantallas... Así no hacen falta archivos de imagen y todas siguen la misma
## paleta. Se generan una sola vez y se guardan en caché.

static var _cache: Dictionary[String, Texture2D] = {}


static func get_texture(texture_name: String) -> Texture2D:
	if not _cache.has(texture_name):
		var image: Image
		match texture_name:
			"floor_planks":
				image = _floor_planks()
			"brick_wall":
				image = _brick_wall()
			"window_view":
				image = _window_view()
			"crt_screen":
				image = _crt_screen()
			"printer_display":
				image = _printer_display()
			"cardboard":
				image = _cardboard()
			_:
				push_error("Textura desconocida: " + texture_name)
				image = Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
		_cache[texture_name] = ImageTexture.create_from_image(image)
	return _cache[texture_name]


static func _new_image(width: int, height: int, fill: String) -> Image:
	var image: Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(fill))
	return image


static func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## Tablas de madera de 6 píxeles de ancho, con juntas escalonadas y vetas.
static func _floor_planks() -> Image:
	var colors: Array[String] = ["a86d43", "9c643c", "b3764a", "a26940"]
	var image: Image = _new_image(32, 30, colors[0])
	var rng: RandomNumberGenerator = _rng(11)
	for row: int in 5:
		var offset: int = (row * 11) % 16
		for x: int in 32:
			var plank: int = int(floor(float(x + offset) / 16.0))
			var base: Color = Color(colors[(row + plank) % colors.size()])
			for y: int in range(row * 6, row * 6 + 6):
				var color: Color = base
				if y == row * 6 + 5:
					color = Color("6a3f22")
				elif (x + offset) % 16 == 0:
					color = Color("7a4a2a")
				elif rng.randf() < 0.06:
					color = base.darkened(0.12)
				image.set_pixel(x, y, color)
	return image


## Ladrillos oscuros de 16x7 píxeles con mortero de 1 píxel.
static func _brick_wall() -> Image:
	var colors: Array[String] = ["4b4150", "52475a", "463c4c", "4f4555"]
	var image: Image = _new_image(32, 32, "2c2532")
	var rng: RandomNumberGenerator = _rng(23)
	for row: int in 4:
		var offset: int = 0 if row % 2 == 0 else 8
		for x: int in 32:
			var brick: int = int(floor(float(x + offset) / 16.0))
			var base: Color = Color(colors[(row * 3 + brick) % colors.size()])
			if (x + offset) % 16 == 15:
				continue
			for y: int in range(row * 8, row * 8 + 7):
				var color: Color = base
				if y == row * 8:
					color = base.lightened(0.08)
				elif rng.randf() < 0.05:
					color = base.darkened(0.1)
				image.set_pixel(x, y, color)
	return image


## Vista por la ventana: cielo, nubes, cerros y una ciudad cálida.
static func _window_view() -> Image:
	var width: int = 48
	var height: int = 32
	var image: Image = _new_image(width, height, "8fd3f5")
	var rng: RandomNumberGenerator = _rng(5)
	for y: int in height:
		var sky: Color = Color("7cc6f2").lerp(Color("d6f0fb"), float(y) / 20.0)
		for x: int in width:
			image.set_pixel(x, y, sky)
	for cloud: Vector2i in [Vector2i(8, 5), Vector2i(30, 3), Vector2i(40, 9)]:
		for dx: int in range(-4, 5):
			for dy: int in range(-1, 2):
				if absi(dx) + absi(dy) * 3 < 6:
					image.set_pixel(clampi(cloud.x + dx, 0, width - 1), clampi(cloud.y + dy, 0, height - 1), Color("ffffff"))
	for x: int in width:
		var hill: int = 18 + int(3.0 * sin(float(x) * 0.25)) + int(2.0 * sin(float(x) * 0.6))
		for y: int in range(hill, height):
			image.set_pixel(x, y, Color("5f9e6e") if y < hill + 2 else Color("4f8a5f"))
	var building_colors: Array[String] = ["e0a86a", "c98a5c", "e8c39e", "b8765a", "d99a6c"]
	var x_pos: int = 0
	while x_pos < width:
		var w: int = rng.randi_range(4, 7)
		var top: int = rng.randi_range(17, 25)
		var color: Color = Color(building_colors[rng.randi_range(0, building_colors.size() - 1)])
		for x: int in range(x_pos, mini(x_pos + w, width)):
			for y: int in range(top, height):
				var lit: bool = (x - x_pos) % 2 == 1 and (y - top) % 3 == 1 and x < x_pos + w - 1
				image.set_pixel(x, y, Color("fff2b3") if lit and rng.randf() < 0.5 else color)
		x_pos += w + rng.randi_range(0, 1)
	return image


## Pantalla de computador viejo: fondo oscuro, líneas de barrido y texto.
static func _crt_screen() -> Image:
	var image: Image = _new_image(16, 12, "16302b")
	var rng: RandomNumberGenerator = _rng(3)
	for y: int in 12:
		for x: int in 16:
			if y % 2 == 1:
				image.set_pixel(x, y, Color("12241f"))
			elif y >= 2 and y <= 9 and x >= 2 and x < 2 + rng.randi_range(4, 12):
				image.set_pixel(x, y, Color("7fe0a0"))
	return image


## Pantallita de la impresora.
static func _printer_display() -> Image:
	var image: Image = _new_image(8, 6, "2f6fd6")
	for x: int in range(1, 6):
		image.set_pixel(x, 1, Color("bfe0ff"))
	for x: int in range(1, 4):
		image.set_pixel(x, 3, Color("bfe0ff"))
	return image


## Caja de cartón con cinta.
static func _cardboard() -> Image:
	var image: Image = _new_image(16, 16, "c89a5e")
	var rng: RandomNumberGenerator = _rng(9)
	for y: int in 16:
		for x: int in 16:
			if x == 7 or x == 8:
				image.set_pixel(x, y, Color("e6d3a3"))
			elif rng.randf() < 0.08:
				image.set_pixel(x, y, Color("b88a50"))
	return image

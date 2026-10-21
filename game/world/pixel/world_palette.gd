class_name WorldPalette
extends RefCounted
## Colores y materiales compartidos del mundo 3D (ver docs/ESTILO.md).
##
## Todos los objetos usan estos materiales para que el estilo sea igual en
## todo el juego y para reutilizar materiales (mejor rendimiento en móvil).

## Tamaño aproximado de un píxel de pantalla en metros del mundo. Las
## texturas usan esta escala para que un píxel de textura sea un píxel en
## pantalla.
const PIXEL_WORLD_SIZE: float = 0.028

const OUTLINE: String = "1a1320"
const BACKGROUND: String = "141b2d"
const WOOD_LIGHT: String = "c98b4f"
const WOOD_MID: String = "a86b3c"
const WOOD_DARK: String = "6e4426"
const METAL_DARK: String = "2b2f3a"
const METAL_MID: String = "4a5163"
const PLASTIC_BLACK: String = "23242b"
const PLASTIC_BEIGE: String = "d8ccb0"
const PLASTIC_BEIGE_DARK: String = "b3a585"
const ACCENT_BLUE: String = "3a7bd5"
const SKIN: String = "f1c9a5"
const HAIR: String = "6b3f22"
const HAIR_LIGHT: String = "8a5530"
const HOODIE: String = "25262e"
const JEANS: String = "2f3a57"
const SHOES: String = "ecebe6"
const EYES: String = "1a1320"
const SLOT_MARK: String = "38d6ff"

const OUTLINE_SHADER: Shader = preload("res://game/world/pixel/outline.gdshader")

static var _cache: Dictionary[String, Material] = {}
static var _outline: ShaderMaterial


## Material de color liso con sombreado por bandas y contorno.
static func solid(hex: String) -> StandardMaterial3D:
	var key: String = "solid:" + hex
	if not _cache.has(key):
		var material: StandardMaterial3D = _toon_base()
		material.albedo_color = Color(hex)
		_cache[key] = material
	return _cache[key]


## Material con una textura pixel art de PixelTextures, proyectada según la
## posición en el mundo para que el tamaño del píxel sea el mismo en todas
## partes.
static func textured(texture_name: String) -> StandardMaterial3D:
	var key: String = "textured:" + texture_name
	if not _cache.has(key):
		var material: StandardMaterial3D = _toon_base()
		var texture: Texture2D = PixelTextures.get_texture(texture_name)
		material.albedo_texture = texture
		material.uv1_triplanar = true
		material.uv1_world_triplanar = true
		material.uv1_triplanar_sharpness = 64.0
		var scale: float = 1.0 / (texture.get_width() * PIXEL_WORLD_SIZE)
		material.uv1_scale = Vector3(scale, scale, scale)
		_cache[key] = material
	return _cache[key]


## Material que brilla con luz propia (pantallas, ventanas, marcas): no
## recibe sombras ni lleva contorno.
static func glow(hex: String, texture_name: String = "") -> StandardMaterial3D:
	var key: String = "glow:%s:%s" % [hex, texture_name]
	if not _cache.has(key):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(hex)
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		if not texture_name.is_empty():
			material.albedo_texture = PixelTextures.get_texture(texture_name)
		_cache[key] = material
	return _cache[key]


## Material semitransparente que brilla (marcas de lugares libres).
static func glow_transparent(hex: String, alpha: float) -> StandardMaterial3D:
	var key: String = "glow_alpha:%s:%s" % [hex, alpha]
	if not _cache.has(key):
		var material: StandardMaterial3D = glow(hex).duplicate() as StandardMaterial3D
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = alpha
		_cache[key] = material
	return _cache[key]


static func _toon_base() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.roughness = 1.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.next_pass = _outline_material()
	return material


static func _outline_material() -> ShaderMaterial:
	if _outline == null:
		_outline = ShaderMaterial.new()
		_outline.shader = OUTLINE_SHADER
		_outline.set_shader_parameter("outline_color", Color(OUTLINE))
	return _outline

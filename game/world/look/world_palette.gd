class_name WorldPalette
extends RefCounted
## Materiales compartidos del mundo 3D, estilo "Mundo Impreso" (biblia de
## arte §3): luces calculadas en el sombreador, colores en el espacio de la
## pantalla y sin contorno.
##
## Los materiales se guardan en caché: el mismo pedido devuelve el mismo
## material (las pruebas lo comparan) y se reutilizan (mejor en móvil). Las
## mallas del kit usan kit(), un solo material con todo en los vértices; los
## modelos de cajas de antes usan las variantes por uniform.

## Colores con nombre que usan los modelos (salen de LookPalette).
const BACKGROUND: String = LookPalette.BACKGROUND
const WOOD_LIGHT: String = LookPalette.WOOD_LIGHT
const WOOD_MID: String = LookPalette.WOOD_MID
const WOOD_DARK: String = LookPalette.WOOD_DARK
const METAL_DARK: String = LookPalette.METAL_DARK
const METAL_MID: String = LookPalette.METAL_MID
const PLASTIC_BLACK: String = LookPalette.CUBE_FRAME
const PLASTIC_BEIGE: String = LookPalette.COMPUTER_BEIGE
const PLASTIC_BEIGE_DARK: String = LookPalette.COMPUTER_BEIGE_WORN
const ACCENT_BLUE: String = LookPalette.CUBE_ACCENT
const SKIN: String = LookPalette.SKIN
const HAIR: String = LookPalette.HAIR
const HAIR_LIGHT: String = LookPalette.HAIR_MID
const HOODIE: String = LookPalette.HOODIE
const JEANS: String = LookPalette.JEANS
const SHOES: String = LookPalette.SHOES
const EYES: String = LookPalette.PUPIL
const SLOT_MARK: String = LookPalette.INTERACTION
## Cama de las impresoras abiertas: lámina PEI dorada texturizada.
const PRINT_BED: String = LookPalette.PEI_BED
## Cinta de embalar (rollo y paquetes del rincón de despacho).
const TAPE: String = LookPalette.TAPE
## Pieza que falló: plástico quemado y opaco.
const FAILED_PIECE: String = LookPalette.FAILED_PIECE

## Superficies del kit (UV.x entero, biblia §3.3).
enum Surface { SMOOTH, TILE, WOOD, PAINT, FABRIC, CARDBOARD, METAL, PEI }

const KIT_SHADER: Shader = preload("res://game/world/look/kit.gdshader")
const TINTED_SHADER: Shader = preload("res://game/world/look/kit_tinted.gdshader")
const PRINTING_SHADER: Shader = preload("res://game/world/look/kit_printing.gdshader")
const SCREEN_SHADER: Shader = preload("res://game/world/look/screen.gdshader")
const WINDOW_VIEW_SHADER: Shader = preload("res://game/world/look/window_view.gdshader")
const MARKER_SHADER: Shader = preload("res://game/world/look/marker.gdshader")
const HALO_SHADER: Shader = preload("res://game/world/look/halo.gdshader")
const WINDOW_SHAFT_SHADER: Shader = preload("res://game/world/look/window_shaft.gdshader")

## Lo que muestra cada pantalla (screen.gdshader, uniform `mode`).
const SCREEN_MODES: Dictionary[String, int] = {
	"crt_screen": 0,
	"crt_modeling": 1,
	"printer_display": 2,
	"printer_display_busy": 3,
	"printer_display_done": 4,
	"printer_display_error": 5,
}
## La vista del barrio por la ventana (window_view.gdshader).
const WINDOW_VIEW: String = "window_view"
## Color y superficie de cada nombre de textured(): [hex, Surface, brillo].
## (El piso y las paredes ya son del kit: RoomShell.)
const TEXTURES: Dictionary[String, Array] = {
	"cardboard": [LookPalette.CARDBOARD, Surface.CARDBOARD, 0.0],
}
## Brillo satinado del plástico impreso.
const PRINTED_GLOSS: float = 0.25
## Luz propia de glow(hex): se ve encendido aun a la sombra.
const GLOW_EMIT: float = 1.0

static var _cache: Dictionary[String, Material] = {}


## Material de las mallas del kit: color, superficie, capas y luz propia en
## los vértices (ver kit_body.gdshaderinc).
static func kit() -> ShaderMaterial:
	if not _cache.has("kit"):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = KIT_SHADER
		_cache["kit"] = material
	return _cache["kit"]


## Plástico impreso de un color (la pieza, la bandeja, el filamento): capas
## de 1 cm y brillo satinado.
static func solid(hex: String) -> ShaderMaterial:
	var key: String = "solid:" + hex
	if not _cache.has(key):
		_cache[key] = _tinted(hex, Surface.SMOOTH, PRINTED_GLOSS, PieceModel.LAYER_STEP, 0.0)
	return _cache[key]


## Como solid(), con la capa caliente arriba: la pieza mientras se imprime.
## El alto de la capa lo pone PieceModel.set_shape (instance uniform
## "hot_top"). Solo para piezas: cada instancia le cuesta al búfer de globales
## (ver kit_body.gdshaderinc).
static func printing(hex: String) -> ShaderMaterial:
	var key: String = "printing:" + hex
	if not _cache.has(key):
		_cache[key] = _tinted(hex, Surface.SMOOTH, PRINTED_GLOSS, PieceModel.LAYER_STEP, 0.0, PRINTING_SHADER)
	return _cache[key]


## Un color que no fue impreso (pintura, tela, metal...), con su superficie y
## su brillo.
static func paint(hex: String, surface: Surface = Surface.SMOOTH, gloss: float = 0.0) -> ShaderMaterial:
	var key: String = "paint:%s:%d:%s" % [hex, surface, gloss]
	if not _cache.has(key):
		_cache[key] = _tinted(hex, surface, gloss, 0.0, 0.0)
	return _cache[key]


## Superficie con nombre (TEXTURES): el cartón de los modelos de cajas.
static func textured(texture_name: String) -> ShaderMaterial:
	var key: String = "textured:" + texture_name
	if not _cache.has(key):
		var look: Array = TEXTURES[texture_name]
		_cache[key] = _tinted(look[0], look[1], look[2], 0.0, 0.0)
	return _cache[key]


## Algo que brilla con luz propia. Con `texture_name` es una pantalla
## (SCREEN_MODES, dibujada en el sombreador y animada) o la vista de la
## ventana; sin él, un color liso del kit encendido (un LED, un interior
## iluminado).
static func glow(hex: String, texture_name: String = "") -> ShaderMaterial:
	var key: String = "glow:%s:%s" % [hex, texture_name]
	if not _cache.has(key):
		var material: ShaderMaterial
		if texture_name.is_empty():
			material = _tinted(hex, Surface.SMOOTH, 0.0, 0.0, GLOW_EMIT)
		elif texture_name == WINDOW_VIEW:
			material = ShaderMaterial.new()
			material.shader = WINDOW_VIEW_SHADER
		else:
			material = ShaderMaterial.new()
			material.shader = SCREEN_SHADER
			material.set_shader_parameter("mode", SCREEN_MODES[texture_name])
			material.set_shader_parameter("tint", Color(hex))
		_cache[key] = material
	return _cache[key]


## Marca semitransparente del piso (lugares libres, marco de cercanía,
## destino). Con `period` > 0 late entre `alpha` y `alpha_low` en ese
## periodo (segundos), animada por el sombreador (marker.gdshader).
static func glow_transparent(hex: String, alpha: float, alpha_low: float = -1.0, period: float = 0.0) -> ShaderMaterial:
	var key: String = "glow_alpha:%s:%s:%s:%s" % [hex, alpha, alpha_low, period]
	if not _cache.has(key):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = MARKER_SHADER
		material.set_shader_parameter("color", Color(hex))
		material.set_shader_parameter("alpha", alpha)
		material.set_shader_parameter("alpha_low", alpha_low if period > 0.0 else alpha)
		material.set_shader_parameter("period", period)
		_cache[key] = material
	return _cache[key]


## Haz de luz de la ventana (uno para todo el juego; DayCycle le pone la
## fuerza según la hora).
static func window_shaft() -> ShaderMaterial:
	if not _cache.has("window_shaft"):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = WINDOW_SHAFT_SHADER
		_cache["window_shaft"] = material
	return _cache["window_shaft"]


## Halo de luz que suma (lámpara, pantalla, tira LED con `aspect` > 1,
## destellos con más `intensity`).
static func halo(hex: String, aspect: float = 1.0, intensity: float = 1.0) -> ShaderMaterial:
	var key: String = "halo:%s:%s:%s" % [hex, snappedf(aspect, 0.01), snappedf(intensity, 0.01)]
	if not _cache.has(key):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = HALO_SHADER
		material.set_shader_parameter("color", Color(hex))
		material.set_shader_parameter("aspect", aspect)
		material.set_shader_parameter("intensity", intensity)
		_cache[key] = material
	return _cache[key]


static func _tinted(hex: String, surface: Surface, gloss: float, layer: float, emit: float, shader: Shader = TINTED_SHADER) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("albedo", Color(hex))
	material.set_shader_parameter("surface", surface)
	material.set_shader_parameter("gloss", gloss)
	material.set_shader_parameter("layer", layer)
	material.set_shader_parameter("emit", emit)
	return material

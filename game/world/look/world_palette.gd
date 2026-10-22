class_name WorldPalette
extends RefCounted
## Materiales compartidos del mundo 3D, estilo "Mundo Impreso" (biblia de
## arte §3): luces calculadas en el sombreador, colores en el espacio de la
## pantalla y sin contorno.
##
## Los materiales se guardan en caché: el mismo pedido devuelve el mismo
## material (las pruebas lo comparan) y se reutilizan (mejor en móvil). Las
## mallas del kit usan kit(), un solo material con todo en los vértices; lo
## que cambia de color (la pieza, el filamento, la luz de adentro de las
## impresoras cerradas) y los modelos de cajas que quedan usan las variantes
## por uniform.

## Colores con nombre que usan los modelos (salen de LookPalette).
const BACKGROUND: String = LookPalette.BACKGROUND
const WOOD_MID: String = LookPalette.WOOD_MID
const PLASTIC_BEIGE: String = LookPalette.COMPUTER_BEIGE
const SLOT_MARK: String = LookPalette.INTERACTION
## Pieza que falló: plástico quemado y opaco.
const FAILED_PIECE: String = LookPalette.FAILED_PIECE

## Superficies del kit (UV.x entero, biblia §3.3). SKIN y HAIR son del
## personaje: en la piel de la cabeza se pinta la cara y el pelo lleva el
## contorno café.
enum Surface { SMOOTH, TILE, WOOD, PAINT, FABRIC, CARDBOARD, METAL, PEI, SKIN, HAIR }

const KIT_SHADER: Shader = preload("res://game/world/look/kit.gdshader")
const TINTED_SHADER: Shader = preload("res://game/world/look/kit_tinted.gdshader")
const PRINTING_SHADER: Shader = preload("res://game/world/look/kit_printing.gdshader")
const GLASS_SHADER: Shader = preload("res://game/world/look/kit_glass.gdshader")
const CHARACTER_SHADER: Shader = preload("res://game/world/look/kit_character.gdshader")
const HEAD_SHADER: Shader = preload("res://game/world/look/kit_head.gdshader")
const OUTLINE_SHADER: Shader = preload("res://game/world/look/outline_character.gdshader")
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
## Brillo satinado del plástico impreso.
const PRINTED_GLOSS: float = 0.25
## Luz propia de glow(hex): se ve encendido aun a la sombra.
const GLOW_EMIT: float = 1.0
## El personaje (biblia §3.4): terminador más marcado y más luz de borde que
## el resto del mundo.
const CHARACTER_TOON: float = 0.8
const CHARACTER_RIM: float = 0.35

static var _cache: Dictionary[String, Material] = {}


## Material de las mallas del kit: color, superficie, capas y luz propia en
## los vértices (ver kit_body.gdshaderinc).
static func kit() -> ShaderMaterial:
	if not _cache.has("kit"):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = KIT_SHADER
		_cache["kit"] = material
	return _cache["kit"]


## El cuerpo del personaje: como kit(), con el terminador marcado, más
## relleno de cámara y la luz de estudio de los retratos
## (kit_character.gdshader).
static func kit_character() -> ShaderMaterial:
	if not _cache.has("kit_character"):
		_cache["kit_character"] = _character_material(CHARACTER_SHADER)
	return _cache["kit_character"]


## La cabeza del personaje: kit_character() con la cara pintada
## (FacePainter) alrededor del eje de la cara de CharacterModel.
static func kit_head() -> ShaderMaterial:
	if not _cache.has("kit_head"):
		var material: ShaderMaterial = _character_material(HEAD_SHADER)
		material.set_shader_parameter("face_atlas", FacePainter.atlas())
		material.set_shader_parameter("face_cells", FacePainter.CELLS)
		material.set_shader_parameter("face_axis", CharacterModel.FACE_AXIS)
		material.set_shader_parameter("face_span", FacePainter.SPAN)
		material.set_shader_parameter("face_height", FacePainter.HEIGHT)
		material.set_shader_parameter("eye_ink", Color(LookPalette.EYE_LINE))
		_cache["kit_head"] = material
	return _cache["kit_head"]


## Contorno fino del personaje (outline_character.gdshader): tinta índigo y
## café oscuro en el pelo.
static func outline_character() -> ShaderMaterial:
	if not _cache.has("outline_character"):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = OUTLINE_SHADER
		material.set_shader_parameter("ink", Color(LookPalette.OUTLINE))
		material.set_shader_parameter("hair_ink", Color(LookPalette.OUTLINE_HAIR))
		_cache["outline_character"] = material
	return _cache["outline_character"]


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


## Plástico transparente de un color con su opacidad `alpha`, visto de los
## dos lados (la tapa ámbar de la impresora de resina). No da sombra.
static func glass(hex: String, alpha: float) -> ShaderMaterial:
	var key: String = "glass:%s:%s" % [hex, alpha]
	if not _cache.has(key):
		var material: ShaderMaterial = _tinted(hex, Surface.SMOOTH, 0.7, 0.0, 0.0, GLASS_SHADER)
		material.set_shader_parameter("alpha", alpha)
		_cache[key] = material
	return _cache[key]


## Un color que no fue impreso (pintura, tela, metal...), con su superficie y
## su brillo.
static func paint(hex: String, surface: Surface = Surface.SMOOTH, gloss: float = 0.0) -> ShaderMaterial:
	var key: String = "paint:%s:%d:%s" % [hex, surface, gloss]
	if not _cache.has(key):
		_cache[key] = _tinted(hex, surface, gloss, 0.0, 0.0)
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


static func _character_material(shader: Shader) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("toon", CHARACTER_TOON)
	material.set_shader_parameter("rim", CHARACTER_RIM)
	return material


static func _tinted(hex: String, surface: Surface, gloss: float, layer: float, emit: float, shader: Shader = TINTED_SHADER) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("albedo", Color(hex))
	material.set_shader_parameter("surface", surface)
	material.set_shader_parameter("gloss", gloss)
	material.set_shader_parameter("layer", layer)
	material.set_shader_parameter("emit", emit)
	return material

class_name HaloField
extends MultiMeshInstance3D
## Los halos de noche (biblia de arte §9.2 y §5.3): una mancha de luz bajo
## cada impresora, del color de su estado (imprimiendo cálido, lista verde,
## falla rojo; sin trabajo, apagada), y las de la decoración (los focos de la
## guirnalda en la pared, el gatito que brilla, el celular, la lámpara de la
## cama). Así el taller lleno se lee de noche. Todos son UN MultiMesh: una
## llamada de dibujo para todos.
##
## Cada impresora pide su halo con add() y le cambia el color con
## set_color(); la decoración y el escritorio ponen los suyos con
## add_glow(). Cuando cambia lo que hay en el cuarto, RoomView los quita
## todos (clear) y los vuelve a pedir en el mismo orden: impresoras,
## escritorio, decoración. El sombreador (halo_field.gdshader) los multiplica por
## cc_night; de día, además, el nodo se esconde (set_night): no cuesta nada.
## Los de la guirnalda parpadean suave (biblia §8.9), cada uno a su ritmo y
## al mismo que su foco (cc_twinkle): el alfa de la copia lo marca.

## Copias que se reservan de una vez (se agranda si hace falta).
const START_CAPACITY: int = 16
## El halo es más grande que la huella de la impresora y apenas se separa del
## piso (o de la tabla en que está).
const SPREAD: float = 1.9
const LIFT: float = 0.004
const INTENSITY: float = 3.0
## Color de una copia apagada (no suma nada).
const OFF: Color = Color(0.0, 0.0, 0.0)
## Alfa de la copia (lo lee el sombreador): fija o que parpadea.
const STEADY_ALPHA: float = 1.0
const TWINKLE_ALPHA: float = 0.0

var _transforms: Array[Transform3D] = []
var _colors: Array[Color] = []
var _twinkles: Array[bool] = []
var _night: float = 0.0


func _init() -> void:
	name = "Halos"
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2.ONE
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = plane
	multimesh.instance_count = START_CAPACITY
	multimesh.visible_instance_count = 0
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = preload("res://game/world/look/halo_field.gdshader")
	material.set_shader_parameter("intensity", INTENSITY)
	material_override = material
	visible = false


## Agrega un halo apagado bajo una impresora: `base` es su lugar en el
## espacio del padre de este nodo (la base, en el piso o en la tabla) y
## `footprint` el ancho y fondo de su huella. Devuelve su número.
func add(base: Transform3D, footprint: Vector2) -> int:
	return add_glow(base * Transform3D(Basis.IDENTITY, Vector3(0.0, LIFT, 0.0)), footprint * SPREAD, OFF)


## Agrega un halo de `size` (ancho y fondo) en el plano de `at` (en el
## espacio del padre: su +Y mira hacia afuera de la superficie) y de ese
## color; con `twinkle`, parpadea como un foco de la guirnalda. Devuelve su
## número.
func add_glow(at: Transform3D, size: Vector2, color: Color, twinkle: bool = false) -> int:
	var placed: Transform3D = at * Transform3D(Basis.from_scale(Vector3(size.x, 1.0, size.y)), Vector3.ZERO)
	_transforms.append(placed)
	_colors.append(color)
	_twinkles.append(twinkle)
	var index: int = _transforms.size() - 1
	if index >= multimesh.instance_count:
		_grow()
	else:
		multimesh.set_instance_transform(index, placed)
		multimesh.set_instance_color(index, _instance_color(index))
	multimesh.visible_instance_count = _transforms.size()
	_refresh()
	return index


## Quita todos los halos (RoomView los vuelve a poner, en orden, cuando cambia
## lo que hay en el cuarto). Las copias reservadas quedan para los nuevos.
func clear() -> void:
	_transforms.clear()
	_colors.clear()
	_twinkles.clear()
	multimesh.visible_instance_count = 0
	_refresh()


## Color del halo `index` (Color(0, 0, 0) = apagado).
func set_color(index: int, color: Color) -> void:
	_colors[index] = color
	multimesh.set_instance_color(index, _instance_color(index))


func color_of(index: int) -> Color:
	return _colors[index]


## Dónde está el halo `index` (en el espacio del padre).
func transform_of(index: int) -> Transform3D:
	return _transforms[index]


## Cuánta noche es (0 de día, 1 de noche): de día no se dibuja.
func set_night(night: float) -> void:
	_night = night
	_refresh()


func count() -> int:
	return _transforms.size()


## Si el halo `index` parpadea.
func twinkles(index: int) -> bool:
	return _twinkles[index]


func _refresh() -> void:
	visible = _night > 0.0 and not _transforms.is_empty()


## Más lugar: cambiar instance_count borra las copias, se vuelven a poner.
func _grow() -> void:
	multimesh.instance_count = maxi(multimesh.instance_count * 2, _transforms.size())
	for i: int in _transforms.size():
		multimesh.set_instance_transform(i, _transforms[i])
		multimesh.set_instance_color(i, _instance_color(i))


## Lo que recibe el sombreador: el color de la copia y, en el alfa, si
## parpadea.
func _instance_color(index: int) -> Color:
	var color: Color = _colors[index]
	return Color(color.r, color.g, color.b, TWINKLE_ALPHA if _twinkles[index] else STEADY_ALPHA)

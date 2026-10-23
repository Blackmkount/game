class_name RoomDecor
extends Node3D
## La decoración del dormitorio (biblia de arte §8.8–8.9): lo que hace que
## el cuarto sea el de un joven maker de una ciudad de valle, lleno de
## historia y sin quitar piso para crecer. Es el nodo Room/Decor: no se toca
## (no es WorldInteractable), nada se llama Printer*, Furniture* ni FreeSlot*
## y no está dentro de ningún objeto que se toca (no agranda su zona de
## toque, biblia §5.4).
##
## Mallas, todas con el material del kit (biblia §5.2: ≤ 7 llamadas y ≤ 9.000
## triángulos en total):
## - FloorN: lo sólido del piso (DecorItems), con sombra: 2 llamadas.
## - WallN: lo de las paredes y los estantes (DecorWall), sin sombra: 1.
## - Flat: lo plano del piso (≤ 4 mm), sin sombra: 1.
## - Dust: el polvo del haz de la ventana (DustField), solo de día: 1.
## Más la baldosa de la impresora del piso ("Paver", PaverModel), que pone
## RoomView. Sus halos de noche van en Room/Halos, el MultiMesh de todos los
## halos (add_night_lights), detrás de los de las impresoras.
##
## Crece con el nivel (tier_for): Floor y Wall tienen una variante por nivel
## de decoración (FloorN y WallN, N = 0, 1, 2). Las tres se arman y se ponen
## de una vez al armar el cuarto (lo que no cambia se arma una sola vez y se
## copia: KitMesh.copy); subir de nivel solo cambia cuál se ve, sin armar
## nada ni pedir memoria. Lo escondido no se dibuja. Los obstáculos (la
## grilla de caminar) son los mismos en todos los niveles.

## La decoración es la del dormitorio (el espacio "habitacion" de
## data/spaces.json); el garaje de la Fase 4 tendrá la suya.
const SPACE_ID: String = "habitacion"
## Detalle de lo redondo de la decoración (biblia §5.1) y biseles que no se
## hacen por chicos.
const DETAIL: float = 0.6
const BEVEL_CUTOFF: float = 0.004
## Desde qué nivel del juego se ve cada nivel de decoración (biblia §8.8:
## 1–2 "recién empiezo", 3–4 "ya vendo", 5+ "taller"). Son números de
## presentación, no de balance: no cambian nada del juego.
const TIER_LEVELS: Array[int] = [1, 3, 5]
## Semilla del polvo: el mismo polvo en cada partida y en cada captura.
const DUST_SEED: int = 7
## Lo sólido del piso: el rectángulo (x, z) que ocupa entero (con sus hojas y
## lo que cuelga) y su alto (m). Es obstáculo para caminar (agrandado
## OBSTACLE_MARGIN, como los muebles) y deja su mancha en el piso (FloorAO).
## Solo en zonas libres: a ≥ 0,15 m de la huella de todos los lugares de
## muebles (≥ 0,30 m si mide más de 0,6 m), fuera del paso de la puerta y
## lejos de los puntos que usan las pruebas (test_room_decor.gd).
const FLOOR: Dictionary[String, Dictionary] = {
	"bookcase": {"rect": Rect2(-2.96, -3.0, 0.54, 0.39), "height": 1.96},
	"monstera": {"rect": Rect2(-2.98, -2.625, 0.56, 0.465), "height": 1.4},
	"fail_bin": {"rect": Rect2(-2.94, -0.39, 0.28, 0.28), "height": 0.5},
	"filament_boxes": {"rect": Rect2(2.755, -2.965, 0.24, 0.25), "height": 0.45},
	"bed": {"rect": Rect2(1.935, -1.885, 0.985, 2.055), "height": 0.95},
	"pouf": {"rect": Rect2(2.17, 0.42, 0.66, 0.88), "height": 0.55},
}
## Lo del piso que cambia con el nivel (el basurero se llena, se apilan las
## cajas de filamento): va en las variantes; lo demás, en lo compartido.
const TIERED: Array[String] = ["fail_bin", "filament_boxes"]
const OBSTACLE_MARGIN: float = 0.05
## La caja de la cama que tapa el parche de sol de la ventana (biblia §6.3,
## cc_occ_b): el colchón con la cobija.
const BED_BOX: AABB = AABB(Vector3(1.95, 0.0, -1.85), Vector3(0.97, 0.5, 2.02))

## Nivel de decoración que se ve (0, 1 o 2).
var tier: int = -1
## El polvo del haz (DayCycle le pone la fuerza de la hora).
var dust: DustField

## Las variantes de cada nivel (se ve solo la del nivel actual).
var _floors: Array[MeshInstance3D] = []
var _walls: Array[MeshInstance3D] = []
## Los halos de noche de la decoración (DecorWall.night_lights) y su número
## en el MultiMesh de los halos.
var _halos: HaloField
var _lights: Array[Dictionary] = []
var _light_index: PackedInt32Array = PackedInt32Array()


## Arma la decoración como hijo "Decor" de `room` para el nivel del juego
## `level`, y registra lo sólido del piso como obstáculos de `grid` (hay que
## llamarla antes de grid.build()).
static func build(room: Node3D, grid: WalkGrid, level: int) -> RoomDecor:
	var decor: RoomDecor = RoomDecor.new()
	decor.name = "Decor"
	room.add_child(decor)
	for rect: Rect2 in obstacles():
		grid.add_obstacle(rect)
	var floors: Array[ArrayMesh] = _variants("floor")
	var walls: Array[ArrayMesh] = _variants("wall")
	for t: int in TIER_LEVELS.size():
		decor._floors.append(PropBuilder.kit(decor, "Floor%d" % t, floors[t]))
		var wall: MeshInstance3D = PropBuilder.kit(decor, "Wall%d" % t, walls[t])
		wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		decor._walls.append(wall)
	var flat: MeshInstance3D = PropBuilder.kit(decor, "Flat", KitMesh.cached("decor:flat", func() -> ArrayMesh:
		var kit: KitMesh = _kit()
		DecorItems.add_flat(kit)
		return kit.commit()))
	flat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	decor.dust = DustField.new(DUST_SEED)
	decor.add_child(decor.dust)
	decor.set_level(level)
	return decor


## Los obstáculos de la decoración (los rectángulos de FLOOR agrandados):
## iguales en todos los niveles.
static func obstacles() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for id: String in FLOOR:
		rects.append((FLOOR[id]["rect"] as Rect2).grow(OBSTACLE_MARGIN))
	return rects


## Nivel de decoración para el nivel del juego `level`.
static func tier_for(level: int) -> int:
	var result: int = 0
	for i: int in TIER_LEVELS.size():
		if level >= TIER_LEVELS[i]:
			result = i
	return result


## Muestra la decoración del nivel del juego `level`: solo cambia cuál de
## las variantes ya puestas se ve y el color de los halos (sin memoria
## nueva).
func set_level(level: int) -> void:
	tier = tier_for(level)
	for t: int in _floors.size():
		_floors[t].visible = t == tier
		_walls[t].visible = t == tier
	_color_lights()


## Si la tira LED del taller está puesta (DayCycle solo la enciende así).
func has_led_strip() -> bool:
	return tier >= DecorWall.WORKSHOP_TIER


## Pone las luces de noche de la decoración (DecorWall.night_lights) en el
## MultiMesh de los halos; las del nivel que no se ve, apagadas. Se llama de
## nuevo cada vez que RoomView vuelve a poner todos los halos.
func add_night_lights(halos: HaloField) -> void:
	_halos = halos
	_lights = DecorWall.night_lights()
	_light_index.clear()
	for light: Dictionary in _lights:
		_light_index.append(halos.add_glow(light["at"], light["size"], HaloField.OFF, light.get("twinkle", false)))
	_color_lights()


func _color_lights() -> void:
	if _halos == null:
		return
	for i: int in _lights.size():
		var light: Dictionary = _lights[i]
		_halos.set_color(_light_index[i], light["color"] if tier >= int(light["tier"]) else HaloField.OFF)


## Las mallas de un grupo ("floor" o "wall") para cada nivel de decoración,
## en caché. Lo que no cambia con el nivel se arma una vez y se copia.
static func _variants(group: String) -> Array[ArrayMesh]:
	var shared: Array[KitMesh] = []
	var meshes: Array[ArrayMesh] = []
	for t: int in TIER_LEVELS.size():
		meshes.append(KitMesh.cached("decor:%s:%d" % [group, t], func() -> ArrayMesh:
			if shared.is_empty():
				shared.append(_base(group))
			var kit: KitMesh = shared[0].copy()
			_add_tier(kit, group, t)
			return kit.commit()))
	return meshes


static func _base(group: String) -> KitMesh:
	var kit: KitMesh = _kit()
	if group == "floor":
		for id: String in FLOOR:
			if id not in TIERED:
				DecorItems.add_floor(kit, id, 0)
	else:
		DecorWall.add_static(kit)
	return kit


static func _add_tier(kit: KitMesh, group: String, t: int) -> void:
	if group == "floor":
		for id: String in TIERED:
			DecorItems.add_floor(kit, id, t)
	else:
		DecorWall.add_story(kit, t)


static func _kit() -> KitMesh:
	var kit: KitMesh = KitMesh.new()
	kit.detail = DETAIL
	kit.bevel_cutoff = BEVEL_CUTOFF
	return kit

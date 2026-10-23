extends GutTest
## La decoración del dormitorio (Arte 2.0, paso 12; biblia de arte §8.8–8.9 y
## §5.4): lo sólido del piso queda lejos de los lugares de muebles, del paso
## de la puerta y de los puntos que usan las pruebas y las capturas; nada de
## la decoración se toca; lo plano es plano; cambiar de nivel no cambia la
## grilla de caminar; el polvo sale de una semilla; y la cama tapa el parche
## de sol y lleva la lámpara de cc_pl2.

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
const SEED: int = 1234
## Distancia mínima de lo sólido a la huella de un lugar de muebles, y la de
## lo que mide más de TALL de alto (biblia §5.4).
const SLOT_GAP: float = 0.15
const SLOT_GAP_TALL: float = 0.3
const TALL: float = 0.6
## Lo que el rectángulo de cada cosa le perdona a su malla (m).
const RECT_TOLERANCE: float = 0.005
## Paso de la puerta y lugar donde llegan las cajas de la tienda: libres
## (understand_models §6.2).
const DOOR_WAY: Rect2 = Rect2(-2.95, 1.45, 0.95, 1.3)
## Los puntos del piso que usan las pruebas y las capturas: el lugar "lejos"
## de todo, el piso libre, donde posa el personaje para las capturas, el
## punto de partida, la esquina libre junto al escritorio, la llegada al
## rincón de despacho, la llegada de las cajas y el del cuarto lleno.
const TEST_POINTS: Array[Vector2] = [
	Vector2(0.8, 0.2), Vector2(1.0, 1.6), Vector2(0.3, 0.2), Vector2(-0.3, -0.25),
	Vector2(-1.2, -0.95), Vector2(-1.2, -1.2), Vector2(-1.45, 2.1), Vector2(-2.5, 2.1),
	Vector2(-0.6, 1.6),
]
## La caminata con el joystick de las capturas 04–05 (x = −1,1, de z 0,35 a
## −0,92).
const JOYSTICK_WALK: Array[Vector2] = [Vector2(-1.1, 0.35), Vector2(-1.1, -0.92)]
## Lo sólido de la decoración queda al menos a esto de esos puntos.
const POINT_GAP: float = 0.5
const FLAT_TOP: float = 0.004

var _main: Control
var _room: RoomView
var _previous_processing: bool


func before_each() -> void:
	_previous_processing = Game.is_processing()
	Game.set_process(false)
	Game.reset_game(SEED)
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	await wait_process_frames(2)
	_room = _main.get_node("WorldView/SubViewport/Room")


func after_each() -> void:
	Game.set_process(_previous_processing)


func test_floor_decor_keeps_clear_of_every_furniture_slot() -> void:
	var slots: Array[Rect2] = _slot_footprints()
	assert_eq(slots.size(), RoomLayout.for_space(Game.state.space_id).slots.size())
	for id: String in RoomDecor.FLOOR:
		var rect: Rect2 = RoomDecor.FLOOR[id]["rect"]
		var height: float = RoomDecor.FLOOR[id]["height"]
		for tier: int in RoomDecor.TIER_LEVELS.size():
			var kit: KitMesh = RoomDecor._kit()
			DecorItems.add_floor(kit, id, tier)
			assert_gt(kit.triangle_count(), 0, "%s se arma" % id)
			var box: AABB = kit.commit().get_aabb()
			var on_floor: Rect2 = Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
			assert_true(rect.grow(RECT_TOLERANCE).encloses(on_floor), "%s (nivel %d) cabe en su rectángulo: %s en %s" % [id, tier, on_floor, rect])
			assert_gte(box.position.y, -0.001, "%s no se mete bajo el piso" % id)
			assert_lte(box.end.y, height, "%s no pasa de su alto" % id)
		var gap: float = SLOT_GAP_TALL if height > TALL else SLOT_GAP
		for i: int in slots.size():
			assert_gte(_rect_distance(rect, slots[i]), gap - 0.0001, "%s queda a %.2f m o más del lugar %d" % [id, gap, i])


func test_floor_decor_leaves_the_door_way_and_the_test_points_free() -> void:
	var points: Array[Vector2] = TEST_POINTS.duplicate()
	for k: int in 6:
		points.append(JOYSTICK_WALK[0].lerp(JOYSTICK_WALK[1], k / 5.0))
	for id: String in RoomDecor.FLOOR:
		var rect: Rect2 = RoomDecor.FLOOR[id]["rect"]
		var blocked: Rect2 = rect.grow(RoomDecor.OBSTACLE_MARGIN + _room.grid.radius)
		assert_false(blocked.intersects(DOOR_WAY), "%s deja libre el paso de la puerta" % id)
		for point: Vector2 in points:
			assert_gte(WalkGrid.distance_to_rect(point, rect), POINT_GAP, "%s lejos de %s" % [id, point])
	for point: Vector2 in points:
		assert_true(_room.grid.is_free(point), "Se puede estar en %s" % point)


func test_the_decor_is_an_obstacle_registered_before_the_grid_is_built() -> void:
	var registered: Array[Rect2] = _room.grid.obstacles()
	var start: Vector2 = TEST_POINTS[0]
	for id: String in RoomDecor.FLOOR:
		var rect: Rect2 = RoomDecor.FLOOR[id]["rect"]
		assert_has(registered, rect.grow(RoomDecor.OBSTACLE_MARGIN), "%s es obstáculo" % id)
		assert_false(_room.grid.is_free(rect.get_center()), "No se camina sobre %s" % id)
		# El camino de A* no entra: la grilla se armó con la decoración.
		var path: PackedVector2Array = _room.grid.find_path(start, rect.get_center())
		assert_gt(path.size(), 0, "Hay camino hacia %s" % id)
		for point: Vector2 in path:
			assert_true(_room.grid.is_free(point), "El camino hacia %s no la atraviesa (%s)" % [id, point])


func test_nothing_of_the_decor_can_be_touched() -> void:
	var decor: Node = _room.get_node("Decor")
	assert_true(decor is RoomDecor)
	var names: Array[String] = []
	for node: Node in decor.find_children("*", "", true, false):
		names.append(node.name)
		for prefix: String in ["Printer", "Furniture", "FreeSlot"]:
			assert_false(node.name.begins_with(prefix), "Ningún nodo de la decoración se llama %s*: %s" % [prefix, node.name])
	for t: int in RoomDecor.TIER_LEVELS.size():
		assert_has(names, "Floor%d" % t)
		assert_has(names, "Wall%d" % t)
	assert_has(names, "Flat")
	assert_has(names, "Dust")
	# Lo que se toca en una partida nueva: la impresora, el escritorio, los 5
	# lugares libres, la puerta, el rincón de despacho y el personaje.
	assert_eq(_room.interactables.size(), 10, "La decoración no suma nada que se toque")
	assert_eq(_room.find_children("FreeSlot*", "", false, false).size(), 5)
	# Ningún objeto que se toca está donde está la decoración.
	for item: WorldInteractable in _room.interactables:
		for id: String in RoomDecor.FLOOR:
			assert_false((RoomDecor.FLOOR[id]["rect"] as Rect2).grow(-0.01).intersects(item.footprint()), "%s no se toca" % id)
	# Tocar la cama o el puf (lejos de todo) no abre nada.
	for id: String in ["bed", "pouf"]:
		var rect: Rect2 = RoomDecor.FLOOR[id]["rect"]
		var top: Vector3 = Vector3(rect.get_center().x, float(RoomDecor.FLOOR[id]["height"]) * 0.4, rect.get_center().y)
		assert_null(_room.pick(_room.camera.unproject_position(top), 0.0), "Tocar %s no abre nada" % id)


func test_flat_decor_is_flat_and_its_cable_crosses_no_free_slot() -> void:
	var flat: MeshInstance3D = _room.get_node("Decor/Flat")
	var box: AABB = flat.mesh.get_aabb()
	assert_gte(box.position.y, -0.0001, "Lo plano no se mete bajo el piso")
	assert_lte(box.end.y, FLAT_TOP + 0.0001, "Lo plano mide 4 mm o menos")
	assert_eq(flat.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	var slots: Array[Rect2] = _slot_footprints()
	var desk_slot: int = _desk_slot()
	var path: PackedVector3Array = KitMesh.smooth_path(DecorItems.desk_cable_floor(), 3)
	assert_gt(path.size(), 10)
	for point: Vector3 in path:
		assert_lte(point.y, FLAT_TOP, "El cable va pegado al piso")
		for i: int in slots.size():
			if i != desk_slot:
				assert_false(slots[i].has_point(Vector2(point.x, point.z)), "El cable no pisa el lugar %d (%s)" % [i, point])
	var wall_end: Vector3 = path[path.size() - 1]
	assert_almost_eq(wall_end.x, -RoomShell.SIZE / 2.0, 0.03, "Llega a la pared de la ventana, donde está el enchufe")


func test_changing_the_level_does_not_change_the_grid() -> void:
	var decor: RoomDecor = _room.decor
	var obstacles: Array[Rect2] = _room.grid.obstacles()
	assert_eq(decor.tier, 0, "Una partida nueva: recién empieza")
	assert_eq(_shown(decor, "Floor"), ["Floor0"] as Array[String], "Se ve solo la decoración del nivel")
	assert_false(_room.day_cycle.led_strip_on, "Sin tira LED")
	var floor_triangles: Array[int] = [_triangles(_visible_mesh(decor, "Floor"))]
	var wall_triangles: Array[int] = [_triangles(_visible_mesh(decor, "Wall"))]
	for level: int in [3, 5]:
		_level_up(level)
		var tier: int = RoomDecor.tier_for(level)
		assert_eq(decor.tier, tier, "Nivel %d" % level)
		assert_eq(_room.grid.obstacles(), obstacles, "La grilla de caminar no cambia (nivel %d)" % level)
		assert_eq(_room.find_children("FreeSlot*", "", false, false).size(), 5)
		assert_eq(_shown(decor, "Floor"), ["Floor%d" % tier] as Array[String])
		assert_eq(_shown(decor, "Wall"), ["Wall%d" % tier] as Array[String])
		floor_triangles.append(_triangles(_visible_mesh(decor, "Floor")))
		wall_triangles.append(_triangles(_visible_mesh(decor, "Wall")))
	assert_gt(floor_triangles[1], floor_triangles[0], "Ya vende: el basurero más lleno y otra caja")
	assert_gt(floor_triangles[2], floor_triangles[1], "Taller: la pila de cajas")
	assert_gt(wall_triangles[1], wall_triangles[0], "Ya vende: la repisa completa, más notas y el billete")
	assert_gt(wall_triangles[2], wall_triangles[1], "Taller: la placa y la tira LED")
	assert_true(_room.day_cycle.led_strip_on, "En el taller la tira LED alumbra de noche")


func test_showing_another_level_builds_nothing() -> void:
	var decor: RoomDecor = _room.decor
	var meshes: int = KitMesh._cache.size()
	var children: int = decor.get_child_count()
	# La lista va armada antes de medir (armarla pide memoria).
	var levels: Array[int] = [3, 5, 1, 5, 3, 1]
	var before: int = int(Performance.get_monitor(Performance.MEMORY_STATIC))
	for level: int in levels:
		decor.set_level(level)
	assert_eq(int(Performance.get_monitor(Performance.MEMORY_STATIC)) - before, 0, "Sin memoria nueva: las tres decoraciones ya están puestas")
	assert_eq(KitMesh._cache.size(), meshes, "No se arma ninguna malla")
	assert_eq(decor.get_child_count(), children, "Ni se agrega nada")


func test_the_dust_is_the_same_with_the_same_seed() -> void:
	var first: PackedColorArray = DustField.motes(RoomDecor.DUST_SEED)
	assert_eq(first.size(), DustField.COUNT)
	assert_eq(DustField.motes(RoomDecor.DUST_SEED), first, "La misma semilla, el mismo polvo")
	assert_ne(DustField.motes(RoomDecor.DUST_SEED + 1), first, "Otra semilla, otro polvo")
	for mote: Color in first:
		for value: float in [mote.r, mote.g, mote.b, mote.a]:
			assert_between(value, 0.0, 1.0, "Dentro del haz y con su fase")
	var dust: DustField = _room.get_node("Decor/Dust")
	assert_eq(dust.multimesh.instance_count, DustField.COUNT)
	assert_true(dust.visible, "De mañana se ve")
	assert_eq(dust.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	dust.set_strength(0.0)
	assert_false(dust.visible, "Sin luz de la ventana, no se dibuja")


func test_the_bed_shades_the_window_patch_and_holds_the_bed_lamp() -> void:
	var bed: Rect2 = RoomDecor.FLOOR["bed"]["rect"]
	assert_eq(_room.bed_occluder, RoomDecor.BED_BOX, "La cama tapa el parche de sol (cc_occ_b)")
	var shade: Rect2 = Rect2(RoomDecor.BED_BOX.position.x, RoomDecor.BED_BOX.position.z, RoomDecor.BED_BOX.size.x, RoomDecor.BED_BOX.size.z)
	assert_true(bed.grow(0.001).encloses(shade), "La caja va dentro de la cama")
	assert_almost_eq(RoomDecor.BED_BOX.end.y, DecorItems.BED_MATTRESS_TOP + 0.06, 0.03, "Del alto del colchón con la cobija")
	var lamp: Vector3 = DecorItems.BED_LAMP_BULB
	assert_eq(_room.day_cycle._light_positions.get("bed_lamp", Vector3.INF), lamp, "cc_pl2 sale de la lámpara de la cama")
	assert_true(bed.has_point(Vector2(lamp.x, lamp.z)), "La lámpara está en la cama")
	assert_gt(lamp.y, DecorItems.BED_HEADBOARD + DecorItems.BED_LEDGE.x, "Sobre la repisa de la cabecera")


## Huella de cada lugar de muebles: todo lo que puede ir ahí. En un lugar con
## un mueble que no se vende (el escritorio del lugar 0), solo ese; en los
## demás, cada mueble de la tienda (con su pared, como lo pone RoomView) y su
## marca de lugar libre.
func _slot_footprints() -> Array[Rect2]:
	var layout: RoomLayout = RoomLayout.for_space(Game.state.space_id)
	var fixed: Dictionary[int, String] = {}
	for item: OwnedFurniture in Game.state.furniture:
		if not bool(_furniture(item.furniture_id)["purchasable"]):
			fixed[item.slot] = item.furniture_id
	var holder: Node3D = Node3D.new()
	add_child_autofree(holder)
	var result: Array[Rect2] = []
	for slot: int in layout.slots.size():
		var ids: Array[String] = []
		if fixed.has(slot):
			ids.append(fixed[slot])
		else:
			for item: Dictionary in Game.catalog.files["furniture"]:
				if item["purchasable"]:
					ids.append(item["id"])
		var union: Rect2 = Rect2()
		for k: int in ids.size():
			var node: Node3D = FurnitureModel.build(holder, "Slot%d_%d" % [slot, k], ids[k], layout.wall_gaps[slot])
			node.transform = layout.slots[slot]
			var footprint: Rect2 = WorldInteractable.new(WorldInteractable.Kind.FURNITURE, 0, PropBounds.local_aabb(node), node.transform).footprint()
			union = footprint if k == 0 else union.merge(footprint)
		if not fixed.has(slot):
			var marker: Node3D = SlotMarker.build(holder, "Mark%d" % slot, WorldPalette.kit())
			marker.transform = layout.slots[slot]
			union = union.merge(WorldInteractable.new(WorldInteractable.Kind.SLOT, slot, PropBounds.local_aabb(marker), marker.transform).footprint())
		result.append(union)
	return result


func _desk_slot() -> int:
	for item: OwnedFurniture in Game.state.furniture:
		if item.furniture_id == DeskSheet.FURNITURE_ID:
			return item.slot
	return -1


func _furniture(id: String) -> Dictionary:
	for item: Dictionary in Game.catalog.files["furniture"]:
		if item["id"] == id:
			return item
	return {}


## Sube la partida al nivel `level` como lo haría el juego.
func _level_up(level: int) -> void:
	Game.state.xp = Game.rules.levels.thresholds[level - 1]
	Events.level_up.emit(level)


## Los hijos de la decoración que empiezan con `prefix` y se ven.
static func _shown(decor: RoomDecor, prefix: String) -> Array[String]:
	var names: Array[String] = []
	for child: Node in decor.get_children():
		if child.name.begins_with(prefix) and (child as Node3D).visible:
			names.append(String(child.name))
	return names


static func _visible_mesh(decor: RoomDecor, prefix: String) -> Mesh:
	return (decor.get_node(_shown(decor, prefix)[0]) as MeshInstance3D).mesh


static func _rect_distance(a: Rect2, b: Rect2) -> float:
	var dx: float = maxf(maxf(b.position.x - a.end.x, a.position.x - b.end.x), 0.0)
	var dy: float = maxf(maxf(b.position.y - a.end.y, a.position.y - b.end.y), 0.0)
	return Vector2(dx, dy).length()


static func _triangles(mesh: Mesh) -> int:
	return (mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3

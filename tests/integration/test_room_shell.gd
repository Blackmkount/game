extends GutTest
## El cuarto de Arte 2.0, paso 5 (biblia de arte §8.1–8.7 y §6.3): la cáscara
## (base impresa, paredes con el hueco de la ventana, puerta), las marcas del
## piso y lo que el parche de sol de la ventana necesita del cuarto.

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
const SceneBudget: GDScript = preload("res://tests/helpers/scene_budget.gd")
const SEED: int = 1234
## La zona de toque de la puerta (la de siempre): x, z, y.
const DOOR_X: Vector2 = Vector2(-3.0, -2.855)
const DOOR_Z: Vector2 = Vector2(1.6, 2.6)
const DOOR_Y: Vector2 = Vector2(0.0, 2.0)
## Biblia §5.2: la cáscara, la ventana, la puerta y la base.
const ROOM_MAX_TRIANGLES: int = 2500
const ROOM_MAX_DRAW_CALLS: int = 5
## Un punto a este tanto del borde del hueco ya es pared.
const OUTSIDE: float = 0.02

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


func test_the_door_keeps_its_touch_zone() -> void:
	assert_not_null(_room.get_node_or_null("RoomShell/Door"))
	var door: WorldInteractable = _room.item_for(WorldInteractable.Kind.DOOR, 0)
	var box: AABB = door.bounds
	assert_almost_eq(Vector2(box.position.x, box.end.x), DOOR_X, Vector2.ONE * 0.001, "La puerta, de x")
	assert_almost_eq(Vector2(box.position.z, box.end.z), DOOR_Z, Vector2.ONE * 0.001, "De z")
	assert_almost_eq(Vector2(box.position.y, box.end.y), DOOR_Y, Vector2.ONE * 0.001, "De alto")


func test_the_window_hole_is_where_the_window_spec_says() -> void:
	var walls: PackedVector3Array = _wall_triangles(LookPalette.WALL_WINDOW)
	assert_gt(walls.size(), 0, "La pared de la ventana está en la malla del cuarto")
	var z0: float = WindowSpec.HOLE_Z.x
	var z1: float = WindowSpec.HOLE_Z.y
	var y0: float = WindowSpec.HOLE_Y.x
	var y1: float = WindowSpec.HOLE_Y.y
	for i: int in 7:
		for j: int in 5:
			var z: float = lerpf(z0 + 0.01, z1 - 0.01, i / 6.0)
			var y: float = lerpf(y0 + 0.01, y1 - 0.01, j / 4.0)
			assert_false(_crosses_wall(walls, z, y), "Por el hueco no hay pared en z %.2f, y %.2f" % [z, y])
	for edge: Vector2 in [Vector2(z0 - OUTSIDE, (y0 + y1) / 2.0), Vector2(z1 + OUTSIDE, (y0 + y1) / 2.0), Vector2(WindowSpec.center_z(), y0 - OUTSIDE), Vector2(WindowSpec.center_z(), y1 + OUTSIDE)]:
		assert_true(_crosses_wall(walls, edge.x, edge.y), "Justo afuera del hueco hay pared (z %.2f, y %.2f)" % [edge.x, edge.y])
	# El parche del sombreador usa las mismas medidas (lo que publica
	# WindowSpec; sin pantalla el motor no deja leer los globales).
	var globals: Dictionary[StringName, Variant] = WindowSpec.globals()
	assert_eq(globals[&"cc_window_rect"], Vector4(z0, z1, y0, y1))
	assert_eq(globals[&"cc_window_x"], WindowSpec.WALL_X)
	assert_eq(globals[&"cc_window_bars"], Vector4(WindowSpec.BAR_SPACING, WindowSpec.BAR_HALF, WindowSpec.CROSSBAR_Y, WindowSpec.MULLION_HALF))
	assert_eq(globals[&"cc_window_sun"], Vector4(WindowSpec.center_z(), WindowSpec.SUN_Y, WindowSpec.SUN_OUTER, WindowSpec.SUN_INNER))
	# Las rejas de verdad están en el hueco, donde el sombreador las busca.
	var bar_meshes: int = 0
	for z: float in WindowSpec.bar_positions():
		bar_meshes += 1 if _has_bar_at(z) else 0
	assert_eq(bar_meshes, WindowSpec.bar_positions().size(), "Cada reja del parche está en la malla")


func test_the_bars_split_the_patch_into_stripes() -> void:
	var bars: PackedFloat32Array = WindowSpec.bar_positions()
	assert_gte(bars.size(), 6, "Al menos 6 rayas de reja en el parche")
	assert_almost_eq(bars[0] - WindowSpec.HOLE_Z.x, WindowSpec.BAR_SPACING / 2.0, 0.0001, "A media separación del borde")
	assert_almost_eq(WindowSpec.HOLE_Z.y - bars[bars.size() - 1], WindowSpec.BAR_SPACING / 2.0, 0.0001)
	for z: float in bars:
		assert_gt(absf(z - WindowSpec.center_z()), WindowSpec.MULLION_HALF + WindowSpec.BAR_HALF, "Ninguna reja tapa el parante")


func test_nothing_of_the_room_casts_a_shadow_and_it_fits_its_budget() -> void:
	var shell: Node3D = _room.get_node("RoomShell")
	var meshes: Array[Node] = shell.find_children("*", "MeshInstance3D", true, false)
	assert_gt(meshes.size(), 0)
	for mesh: Node in meshes:
		assert_eq((mesh as MeshInstance3D).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "%s no da sombra" % mesh.name)
	var budget: RefCounted = SceneBudget.measure(_room)
	var calls: int = budget.call("child_draw_calls", "RoomShell") + budget.call("child_draw_calls", "BaseShadow")
	var triangles: int = budget.call("child_triangles", "RoomShell") + budget.call("child_triangles", "BaseShadow")
	gut.p("Cuarto (cáscara, ventana, puerta, base y su sombra): %d llamadas, %d triángulos" % [calls, triangles])
	assert_lte(calls, ROOM_MAX_DRAW_CALLS, "Llamadas de dibujo del cuarto")
	assert_lte(triangles, ROOM_MAX_TRIANGLES, "Triángulos del cuarto")


func test_the_base_shadow_sits_under_the_printed_base() -> void:
	var shadow: Node3D = _room.get_node("BaseShadow")
	assert_lt(shadow.position.y, RoomShell.BASE_BOTTOM, "La sombra va debajo de la base, no adentro")


func test_the_five_free_slots_share_one_mesh_and_keep_their_touch_zone() -> void:
	var slots: Array[Node] = _room.find_children("FreeSlot*", "", false, false)
	assert_eq(slots.size(), 5)
	for slot: Node in slots:
		var mark: MeshInstance3D = slot.get_node("Mark")
		assert_same(mark.mesh, SlotMarker.mesh(), "%s usa la malla compartida" % slot.name)
		assert_eq(mark.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	for item: WorldInteractable in _room.interactables:
		if item.kind == WorldInteractable.Kind.SLOT:
			var size: Vector2 = item.footprint().size
			assert_almost_eq(Vector2(minf(size.x, size.y), maxf(size.x, size.y)), Vector2(0.6, 1.24), Vector2.ONE * 0.001, "Zona de toque del lugar %d" % item.ref)


func test_free_slots_light_up_near_the_character_and_with_the_shop_open() -> void:
	assert_eq(_lit_slots(), [] as Array[String], "Lejos de todo, las marcas laten suave")
	var slot_one: Node3D = _room.get_node("FreeSlot1")
	_room.character.floor_position = Vector2(slot_one.position.x + 0.9, slot_one.position.z)
	_room.step(1.0 / 60.0)
	assert_eq(_lit_slots(), ["FreeSlot1"] as Array[String], "La que está a menos de %.1f m se enciende" % RoomView.MARKER_NEAR)
	_room.character.floor_position = Vector2(0.3, 0.2)
	(_main.get_node("Hud") as Hud).open_screen("shop")
	_room.step(1.0 / 60.0)
	assert_eq(_lit_slots().size(), 5, "Con la tienda abierta se encienden todas")
	(_main.get_node("Hud") as Hud).open_screen("home")
	await wait_process_frames(1)
	_room.step(1.0 / 60.0)
	assert_false(_room.markers_emphasis)


func test_the_desk_under_the_window_shades_the_sun_patch() -> void:
	var desk: Node3D = _room.get_node("Furniture%d" % Game.state.furniture[0].uid)
	var table: AABB = desk.transform * ComputerDeskModel.table_box()
	var box: AABB = _room.window_occluder
	assert_almost_eq(box.position, table.position, Vector3.ONE * 0.001, "La caja del tablero del escritorio")
	assert_almost_eq(box.size, table.size, Vector3.ONE * 0.001)
	assert_almost_eq(box.end.y, ComputerDeskModel.TABLE_SIZE.y, 0.001, "Hasta arriba del tablero")
	var footprint: Rect2 = _room.item_for(WorldInteractable.Kind.FURNITURE, Game.state.furniture[0].uid).footprint()
	assert_true(footprint.encloses(Rect2(box.position.x, box.position.z, box.size.x, box.size.z).grow(-0.001)), "Dentro de la huella del escritorio")
	# El escritorio está bajo la ventana: tapa el parche junto a la pared.
	assert_lt(box.position.z, WindowSpec.HOLE_Z.y)
	assert_gt(box.end.z, WindowSpec.HOLE_Z.x)


func test_the_highlight_frame_hugs_the_object_with_corners() -> void:
	var printer: WorldInteractable = _room.item_for(WorldInteractable.Kind.PRINTER, Game.state.printers[0].uid)
	_room.set_highlight(printer)
	var frame: Node3D = _room.get_node("Highlight")
	assert_true(frame.visible)
	var mesh: Mesh = (frame.get_node("Frame") as MeshInstance3D).mesh
	var grown: Rect2 = printer.footprint().grow(HighlightFrame.MARGIN)
	assert_almost_eq(Vector2(mesh.get_aabb().size.x, mesh.get_aabb().size.z), grown.size, Vector2.ONE * 0.011, "Las esquinas marcan la huella + %.2f m" % HighlightFrame.MARGIN)
	_room.set_highlight(null)
	_room.set_highlight(printer)
	assert_same((frame.get_node("Frame") as MeshInstance3D).mesh, mesh, "La misma malla para el mismo tamaño")


## Triángulos de la malla del cuarto pintados de ese color (tres puntos por
## triángulo).
func _wall_triangles(hex: String) -> PackedVector3Array:
	var mesh: ArrayMesh = (_room.get_node("RoomShell/Shell") as MeshInstance3D).mesh
	var arrays: Array = mesh.surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var wanted: Color = Color(hex)
	var out: PackedVector3Array = PackedVector3Array()
	for k: int in range(0, indices.size(), 3):
		var color: Color = colors[indices[k]]
		if Vector3(color.r, color.g, color.b).distance_to(Vector3(wanted.r, wanted.g, wanted.b)) < 0.002:
			out.append_array(PackedVector3Array([positions[indices[k]], positions[indices[k + 1]], positions[indices[k + 2]]]))
	return out


## ¿Una línea que atraviesa la pared de la ventana a lo ancho (en x), a esa
## altura y en ese z, toca la pared?
func _crosses_wall(walls: PackedVector3Array, z: float, y: float) -> bool:
	var from: Vector3 = Vector3(WindowSpec.WALL_X + 0.1, y, z)
	var direction: Vector3 = Vector3.LEFT
	for k: int in range(0, walls.size(), 3):
		var hit: Variant = Geometry3D.ray_intersects_triangle(from, direction, walls[k], walls[k + 1], walls[k + 2])
		if hit != null and (hit as Vector3).x > WindowSpec.WALL_X - RoomShell.WALL_THICKNESS - 0.05:
			return true
	return false


## ¿Hay una reja (un cilindro vertical de hierro) en ese z, por fuera del
## hueco?
func _has_bar_at(z: float) -> bool:
	var mesh: ArrayMesh = (_room.get_node("RoomShell/Shell") as MeshInstance3D).mesh
	var arrays: Array = mesh.surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var iron: Color = Color(LookPalette.WINDOW_BARS)
	for i: int in positions.size():
		var p: Vector3 = positions[i]
		if absf(p.z - z) <= WindowSpec.BAR_HALF + 0.0001 and p.x < WindowSpec.WALL_X - RoomShell.WALL_THICKNESS \
				and p.y > WindowSpec.HOLE_Y.y and Color(colors[i].r, colors[i].g, colors[i].b).is_equal_approx(iron):
			return true
	return false


func _lit_slots() -> Array[String]:
	var lit: ShaderMaterial = WorldPalette.glow_transparent(WorldPalette.SLOT_MARK, RoomView.MARKER_LIT_ALPHA, RoomView.MARKER_LIT_ALPHA_LOW, RoomView.MARKER_PULSE_PERIOD)
	var names: Array[String] = []
	for slot: Node in _room.find_children("FreeSlot*", "", false, false):
		if (slot.get_node("Mark") as MeshInstance3D).material_override == lit:
			names.append(String(slot.name))
	names.sort()
	return names

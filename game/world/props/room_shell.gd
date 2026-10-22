class_name RoomShell
extends RefCounted
## El cuarto como una maqueta impresa en 3D (biblia de arte §8.1–8.7): una base
## de plástico azul con sus capas a la vista y un borde de primera capa, el
## piso de baldosa, dos paredes pintadas (la de la ventana verde salvia, la del
## fondo crema) con los cortes de arriba y de las puntas impresos, zócalos, la
## ventana corrediza de aluminio con su alféizar, las rejas de afuera con un
## adorno de sol y la cortina mostaza recogida, el interruptor con su canaleta,
## el enchufe de la impresora y la puerta.
##
## Lo fijo es UNA malla del kit (una llamada de dibujo). Aparte van lo que usa
## otro material (la vista del barrio, recortada al hueco, y el haz de luz) y la
## puerta, que se toca. Nada de esto da sombra (biblia §2.6): la luz general
## pasa por arriba de las paredes y la ventana se lee por el parche de sol que
## calcula el sombreador con las mismas medidas (WindowSpec).

const SIZE: float = 6.0
const WALL_HEIGHT: float = 2.8
const WALL_THICKNESS: float = 0.2
## Base impresa: grosor bajo el piso, alto de sus capas y el borde de
## primera capa ("brim") que sobresale alrededor.
const BASE_DEPTH: float = 0.3
const BASE_LAYER: float = 0.024
const BRIM_WIDTH: float = 0.04
## Capas de los cortes de las paredes.
const CUT_LAYER: float = 0.012
## Piso: una losa fina de baldosa (su canto claro separa el piso de la base).
const FLOOR_THICKNESS: float = 0.02
## Lo más bajo de la base (con el brim): ahí abajo va su sombra.
const BASE_BOTTOM: float = -(FLOOR_THICKNESS + BASE_DEPTH)
## Zócalo de las paredes: alto y cuánto sobresale de la pared.
const BASEBOARD: Vector2 = Vector2(0.1, 0.018)
## Puerta: en la pared de la ventana, cerca del frente. Se toca: su caja (sin
## girar) va de x -0,03 a 0,115, de z -0,5 a 0,5 y de y 0 a 2,0.
const DOOR_POSITION: Vector3 = Vector3(-SIZE / 2.0 + 0.03, 0.0, 2.1)
const DOOR_HALF_WIDTH: float = 0.5
const DOOR_HEIGHT: float = 2.0
## La vista del barrio va detrás del hueco, así de lejos por la mirada de la
## cámara (un cuadro de este tamaño cubre el hueco visto desde la cámara).
const VIEW_DEPTH: float = 1.0
const VIEW_SIZE: Vector2 = Vector2(1.3, 1.6)
## Rejas por fuera de la pared (plano x).
const BARS_X: float = -SIZE / 2.0 - WALL_THICKNESS - 0.05
## Barra de la cortina (biblia §8.8): alto, de dónde a dónde (z) y a cuánto
## de la pared.
const CURTAIN_ROD_Y: float = 2.2
const CURTAIN_ROD_Z: Vector2 = Vector2(-2.0, -0.4)
const CURTAIN_GAP: float = 0.07
## Interruptor (entre los lugares 0 y 1 de la pared de la ventana) y enchufe
## de la impresora (pared del fondo, entre los lugares 2 y 3).
const SWITCH_Z: float = 0.0
const SWITCH_Y: float = 1.15
const OUTLET_X: float = -0.6
const OUTLET_Y: float = 0.3


static func build(parent: Node3D) -> Node3D:
	var shell: Node3D = PropBuilder.group(parent, "RoomShell")
	PropBuilder.kit(shell, "Shell", KitMesh.cached("room_shell", _shell_mesh))
	_window_view(shell)
	_window_shaft(shell)
	var door: Node3D = PropBuilder.group(shell, "Door", DOOR_POSITION)
	PropBuilder.kit(door, "Body", KitMesh.cached("room_door", _door_mesh))
	for mesh: Node in shell.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return shell


## Hacia dónde mira la cámara (fija): la vista del barrio se recorta al hueco
## con ella.
static func view_direction() -> Vector3:
	return Basis.from_euler(Vector3(deg_to_rad(CameraRig.PITCH), deg_to_rad(CameraRig.YAW), 0.0)) * Vector3.FORWARD


## El barrio por la ventana: un cuadro de frente a la cámara, detrás del
## hueco. El sombreador descarta lo que no se ve por el hueco.
static func _window_view(shell: Node3D) -> void:
	var material: ShaderMaterial = WorldPalette.glow("ffffff", WorldPalette.WINDOW_VIEW)
	material.set_shader_parameter("view_dir", view_direction())
	var center: Vector3 = Vector3(WindowSpec.WALL_X - WALL_THICKNESS / 2.0, (WindowSpec.HOLE_Y.x + WindowSpec.HOLE_Y.y) / 2.0, WindowSpec.center_z())
	var view: MeshInstance3D = PropBuilder.quad(shell, "WindowView", VIEW_SIZE, center + view_direction() * VIEW_DEPTH, material)
	view.basis = Basis.from_euler(Vector3(deg_to_rad(CameraRig.PITCH), deg_to_rad(CameraRig.YAW), 0.0))


## Haz de luz: dos hojas que salen de los bordes de arriba y de abajo del
## hueco; el sombreador las estira hasta el piso en la dirección de la luz.
static func _window_shaft(shell: Node3D) -> void:
	var mesh: ArrayMesh = KitMesh.cached("window_shaft", _shaft_mesh)
	var shaft: MeshInstance3D = PropBuilder.kit(shell, "WindowShaft", mesh, WorldPalette.window_shaft())
	shaft.sorting_offset = 1.0


static func _shaft_mesh() -> ArrayMesh:
	var x: float = WindowSpec.WALL_X
	var positions: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	for y: float in [WindowSpec.HOLE_Y.x, WindowSpec.HOLE_Y.y]:
		var first: int = positions.size()
		for along: float in [0.0, 1.0]:
			for z: float in [WindowSpec.HOLE_Z.x, WindowSpec.HOLE_Z.y]:
				positions.append(Vector3(x, y, z))
				uvs.append(Vector2(0.0, along))
				# La normal la pone el sombreador (depende de la hora).
				normals.append(Vector3.UP)
		indices.append_array(PackedInt32Array([first, first + 1, first + 2, first + 1, first + 3, first + 2]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# El sombreador mueve los vértices hasta el piso: la caja cubre el cuarto.
	mesh.custom_aabb = AABB(Vector3(-SIZE / 2.0, 0.0, -SIZE / 2.0), Vector3(SIZE, WALL_HEIGHT, SIZE))
	return mesh


static func _shell_mesh() -> ArrayMesh:
	var kit: KitMesh = KitMesh.new()
	kit.ao_enabled = false
	_base(kit)
	_walls(kit)
	_window(kit)
	_curtain(kit)
	_fittings(kit)
	return kit.commit()


## La base impresa, el borde de primera capa y la losa del piso.
static func _base(kit: KitMesh) -> void:
	var t: float = WALL_THICKNESS
	var span: float = SIZE + t
	var center: float = -t / 2.0
	kit.printed(LookPalette.BASE_PRINTED, BASE_LAYER, 0.3)
	kit.box(Vector3(span, BASE_DEPTH, span), Vector3(center, -FLOOR_THICKNESS - BASE_DEPTH / 2.0, center), 0.02)
	kit.printed(LookPalette.BASE_BRIM, BASE_LAYER, 0.0)
	var brim: float = span + BRIM_WIDTH * 2.0
	kit.box(Vector3(brim, BASE_LAYER, brim), Vector3(center, BASE_BOTTOM + BASE_LAYER / 2.0, center), 0.006)
	# La baldosa solo se dibuja arriba: el canto de la losa queda liso y claro.
	kit.paint(LookPalette.FLOOR_TILE, WorldPalette.Surface.TILE, 0.32)
	kit.box(Vector3(SIZE, FLOOR_THICKNESS, SIZE), Vector3(0.0, -FLOOR_THICKNESS / 2.0, 0.0), 0.0)


## Las dos paredes (la de la ventana con el hueco de verdad), los cortes
## impresos de arriba y de las puntas, y los zócalos.
static func _walls(kit: KitMesh) -> void:
	var half: float = SIZE / 2.0
	var t: float = WALL_THICKNESS
	var h: float = WALL_HEIGHT + FLOOR_THICKNESS
	var y_mid: float = WALL_HEIGHT - h / 2.0
	var lx: float = -half - t / 2.0
	var z0: float = WindowSpec.HOLE_Z.x
	var z1: float = WindowSpec.HOLE_Z.y
	var y0: float = WindowSpec.HOLE_Y.x
	var y1: float = WindowSpec.HOLE_Y.y
	kit.paint(LookPalette.WALL_WINDOW, WorldPalette.Surface.PAINT)
	kit.box(Vector3(t, h, z0 + half + t), Vector3(lx, y_mid, (-half - t + z0) / 2.0), 0.0)
	kit.box(Vector3(t, h, half - z1), Vector3(lx, y_mid, (z1 + half) / 2.0), 0.0)
	kit.box(Vector3(t, y0 + FLOOR_THICKNESS, z1 - z0), Vector3(lx, (y0 - FLOOR_THICKNESS) / 2.0, (z0 + z1) / 2.0), 0.0)
	kit.box(Vector3(t, WALL_HEIGHT - y1, z1 - z0), Vector3(lx, (y1 + WALL_HEIGHT) / 2.0, (z0 + z1) / 2.0), 0.0)
	kit.paint(LookPalette.WALL_BACK, WorldPalette.Surface.PAINT)
	kit.box(Vector3(SIZE, h, t), Vector3(0.0, y_mid, -half - t / 2.0), 0.0)

	# Cortes: el plástico impreso de la maqueta, con capas más finas.
	kit.printed(LookPalette.BASE_PRINTED, CUT_LAYER, 0.3)
	var cap: float = 0.05
	var lip: float = 0.015
	kit.box(Vector3(t + lip * 2.0, cap, SIZE + t + lip * 2.0), Vector3(lx, WALL_HEIGHT + cap / 2.0 - 0.005, -t / 2.0), 0.012)
	kit.box(Vector3(SIZE + lip, cap, t + lip * 2.0), Vector3(lip / 2.0, WALL_HEIGHT + cap / 2.0 - 0.005, -half - t / 2.0), 0.012)
	kit.box(Vector3(t + lip * 2.0, h, 0.03), Vector3(lx, y_mid, half + 0.012), 0.006)
	kit.box(Vector3(0.03, h, t + lip * 2.0), Vector3(half + 0.012, y_mid, -half - t / 2.0), 0.006)

	# Zócalos (en la pared de la ventana, cortados por la puerta).
	kit.paint(LookPalette.TRIM, WorldPalette.Surface.SMOOTH, 0.2)
	var board: Vector2 = BASEBOARD
	var door_z0: float = DOOR_POSITION.z - DOOR_HALF_WIDTH
	var door_z1: float = DOOR_POSITION.z + DOOR_HALF_WIDTH
	kit.box(Vector3(SIZE, board.x, board.y), Vector3(0.0, board.x / 2.0, -half + board.y / 2.0), 0.004)
	kit.box(Vector3(board.y, board.x, door_z0 + half), Vector3(-half + board.y / 2.0, board.x / 2.0, (door_z0 - half) / 2.0), 0.004)
	kit.box(Vector3(board.y, board.x, half - door_z1), Vector3(-half + board.y / 2.0, board.x / 2.0, (door_z1 + half) / 2.0), 0.004)


## Ventana corrediza de aluminio de dos hojas, alféizar de baldosa y, por
## fuera, las rejas de hierro con el travesaño y el adorno de sol.
static func _window(kit: KitMesh) -> void:
	var half: float = SIZE / 2.0
	var z0: float = WindowSpec.HOLE_Z.x
	var z1: float = WindowSpec.HOLE_Z.y
	var y0: float = WindowSpec.HOLE_Y.x
	var y1: float = WindowSpec.HOLE_Y.y
	var zc: float = WindowSpec.center_z()
	var w: float = z1 - z0
	# Alféizar: sobresale hacia el cuarto y a los lados.
	kit.paint(LookPalette.WINDOW_SILL, WorldPalette.Surface.TILE, 0.4)
	kit.box(Vector3(WALL_THICKNESS + 0.06, 0.035, w + 0.16), Vector3(-half - WALL_THICKNESS / 2.0 + 0.03, y0 - 0.0025, zc), 0.008)

	# Marco fijo a media pared y las dos hojas (una delante de la otra); donde
	# se cruzan queda el parante central.
	var fx: float = -half - WALL_THICKNESS / 2.0
	var rail: float = 0.045
	var sill_top: float = y0 + 0.015
	kit.paint(LookPalette.WINDOW_ALUMINIUM, WorldPalette.Surface.METAL, 0.5)
	kit.box(Vector3(0.06, rail, w), Vector3(fx, y1 - rail / 2.0, zc), 0.0)
	kit.box(Vector3(0.06, rail, w), Vector3(fx, sill_top + rail / 2.0, zc), 0.0)
	kit.box(Vector3(0.06, y1 - sill_top, rail), Vector3(fx, (y1 + sill_top) / 2.0, z0 + rail / 2.0), 0.0)
	kit.box(Vector3(0.06, y1 - sill_top, rail), Vector3(fx, (y1 + sill_top) / 2.0, z1 - rail / 2.0), 0.0)
	var sash_y0: float = sill_top + rail
	var sash_y1: float = y1 - rail
	var stile: float = 0.035
	var overlap: float = WindowSpec.MULLION_HALF
	_sash(kit, fx - 0.014, sash_y0, sash_y1, z0 + rail, zc + overlap, stile)
	_sash(kit, fx + 0.014, sash_y0, sash_y1, zc - overlap, z1 - rail, stile)

	# Rejas de hierro por fuera de la pared.
	kit.paint(LookPalette.WINDOW_BARS, WorldPalette.Surface.METAL, 0.3)
	var reach: float = 0.04
	for z: float in WindowSpec.bar_positions():
		kit.cylinder(WindowSpec.BAR_HALF, (y1 - y0) + reach * 2.0, Vector3(BARS_X, (y0 + y1) / 2.0, z), Vector3.ZERO, 6)
	var flat: float = WindowSpec.BAR_HALF * 2.0
	kit.box(Vector3(flat, flat, w + reach * 2.0), Vector3(BARS_X, WindowSpec.CROSSBAR_Y, zc), 0.0)
	for radius: float in [WindowSpec.SUN_OUTER, WindowSpec.SUN_INNER]:
		kit.torus(Vector2(radius, radius), WindowSpec.BAR_HALF, Vector3(BARS_X, WindowSpec.SUN_Y, zc), Vector3(0.0, 0.0, 90.0), TAU, Vector2i(18, 4))


## Una hoja corrediza: marco de aluminio de cuatro perfiles (sin vidrio).
static func _sash(kit: KitMesh, x: float, y0: float, y1: float, z0: float, z1: float, stile: float) -> void:
	var depth: float = 0.022
	var zc: float = (z0 + z1) / 2.0
	var yc: float = (y0 + y1) / 2.0
	kit.box(Vector3(depth, stile, z1 - z0), Vector3(x, y1 - stile / 2.0, zc), 0.0)
	kit.box(Vector3(depth, stile, z1 - z0), Vector3(x, y0 + stile / 2.0, zc), 0.0)
	kit.box(Vector3(depth, y1 - y0, stile), Vector3(x, yc, z0 + stile / 2.0), 0.0)
	kit.box(Vector3(depth, y1 - y0, stile), Vector3(x, yc, z1 - stile / 2.0), 0.0)


## Cortina mostaza recogida a los dos lados de la ventana, colgada de una
## barra; se balancea un poco más abajo que arriba.
static func _curtain(kit: KitMesh) -> void:
	var wall: float = -SIZE / 2.0
	var x: float = wall + CURTAIN_GAP
	var z_from: float = CURTAIN_ROD_Z.x
	var z_to: float = CURTAIN_ROD_Z.y
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.METAL, 0.4)
	kit.cylinder(0.011, z_to - z_from + 0.06, Vector3(x, CURTAIN_ROD_Y, (z_from + z_to) / 2.0), Vector3(90.0, 0.0, 0.0), 8)
	for z: float in [z_from - 0.03, z_to + 0.03]:
		kit.cylinder(0.018, 0.03, Vector3(x, CURTAIN_ROD_Y, z), Vector3(90.0, 0.0, 0.0), 8)
		kit.box(Vector3(CURTAIN_GAP, 0.02, 0.02), Vector3(wall + CURTAIN_GAP / 2.0, CURTAIN_ROD_Y, z), 0.0)
	# Tres pliegues por lado, del tono claro y el de los pliegues, alternados.
	var bottom: float = WindowSpec.HOLE_Y.x - 0.12
	var length: float = CURTAIN_ROD_Y - 0.01 - bottom
	var pleat: float = 0.034
	var sides: Array[float] = [z_from + pleat * 1.2, z_to - pleat * 3.0]
	for start: float in sides:
		for i: int in 3:
			kit.paint(LookPalette.CURTAIN if i % 2 == 0 else LookPalette.CURTAIN_FOLD, WorldPalette.Surface.FABRIC)
			kit.hanging(0.4, CURTAIN_ROD_Y, length)
			var bulge: float = 0.012 if i % 2 == 0 else 0.0
			kit.capsule(pleat + 0.004, pleat, length, Vector3(x + bulge, bottom, start + i * pleat * 0.9), Vector3.ZERO, 0.8, Vector2i(7, 5))


## Interruptor con su canaleta blanca que sube hasta el borde de la pared, y
## el enchufe de la impresora en la pared del fondo.
static func _fittings(kit: KitMesh) -> void:
	var wall: float = -SIZE / 2.0
	kit.paint(LookPalette.TRIM, WorldPalette.Surface.SMOOTH, 0.3)
	kit.box(Vector3(0.012, 0.11, 0.07), Vector3(wall + 0.006, SWITCH_Y, SWITCH_Z), 0.003)
	kit.box(Vector3(0.012, WALL_HEIGHT - SWITCH_Y - 0.055, 0.022), Vector3(wall + 0.006, (WALL_HEIGHT + SWITCH_Y + 0.055) / 2.0, SWITCH_Z), 0.003)
	kit.paint(LookPalette.COMPUTER_BEIGE, WorldPalette.Surface.SMOOTH, 0.3)
	kit.box(Vector3(0.008, 0.035, 0.02), Vector3(wall + 0.014, SWITCH_Y + 0.005, SWITCH_Z), 0.002)
	kit.paint(LookPalette.TRIM, WorldPalette.Surface.SMOOTH, 0.3)
	kit.box(Vector3(0.08, 0.08, 0.012), Vector3(OUTLET_X, OUTLET_Y, wall + 0.006), 0.003)
	kit.paint(LookPalette.METAL_DARK)
	for side: float in [-1.0, 1.0]:
		kit.box(Vector3(0.008, 0.016, 0.004), Vector3(OUTLET_X + side * 0.014, OUTLET_Y, wall + 0.013), 0.0)


## Puerta de madera de dos tableros, con marco crema y manija de latón. La
## caja es la de siempre (se toca): x -0,03..0,115, z ±0,5, alto 2,0.
static func _door_mesh() -> ArrayMesh:
	var kit: KitMesh = KitMesh.new()
	var half: float = DOOR_HALF_WIDTH
	var casing: float = 0.07
	kit.paint(LookPalette.TRIM, WorldPalette.Surface.SMOOTH, 0.2)
	for side: float in [-1.0, 1.0]:
		kit.box(Vector3(0.06, DOOR_HEIGHT, casing), Vector3(0.0, DOOR_HEIGHT / 2.0, side * (half - casing / 2.0)), 0.008)
	kit.box(Vector3(0.06, casing, half * 2.0), Vector3(0.0, DOOR_HEIGHT - casing / 2.0, 0.0), 0.008)
	var leaf_h: float = DOOR_HEIGHT - casing - 0.005
	kit.paint(LookPalette.DOOR, WorldPalette.Surface.WOOD, 0.15)
	kit.box(Vector3(0.04, leaf_h, (half - casing) * 2.0), Vector3(0.0, leaf_h / 2.0 + 0.005, 0.0), 0.006)
	kit.paint(LookPalette.DOOR_PANEL, WorldPalette.Surface.WOOD, 0.15)
	kit.box(Vector3(0.016, 0.62, 0.6), Vector3(0.026, 1.42, 0.0), 0.008)
	kit.box(Vector3(0.016, 0.72, 0.6), Vector3(0.026, 0.56, 0.0), 0.008)
	kit.paint(LookPalette.BRASS, WorldPalette.Surface.SMOOTH, 0.7)
	kit.box(Vector3(0.012, 0.16, 0.05), Vector3(0.026, 1.0, -0.34), 0.004)
	kit.box(Vector3(0.05, 0.02, 0.02), Vector3(0.06, 1.0, -0.34), 0.004)
	kit.box(Vector3(0.03, 0.022, 0.13), Vector3(0.1, 1.0, -0.3), 0.006)
	return kit.commit()

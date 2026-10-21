class_name RoomShell
extends RefCounted
## Piso, paredes, ventana y puerta de la habitación. Las paredes no dan
## sombra para que la luz "entre" por la ventana.

const SIZE: float = 6.0
const WALL_HEIGHT: float = 2.8
const WALL_THICKNESS: float = 0.2


static func build(parent: Node3D) -> Node3D:
	var shell: Node3D = PropBuilder.group(parent, "RoomShell")
	var half: float = SIZE / 2.0
	PropBuilder.box(shell, "Floor", Vector3(SIZE, 0.2, SIZE), Vector3(0.0, -0.1, 0.0), WorldPalette.textured("floor_planks"))

	var brick: StandardMaterial3D = WorldPalette.textured("brick_wall")
	var trim: StandardMaterial3D = WorldPalette.solid("3a2f3f")
	var base_board: StandardMaterial3D = WorldPalette.solid(WorldPalette.WOOD_DARK)
	var left_x: float = -half - WALL_THICKNESS / 2.0
	var back_z: float = -half - WALL_THICKNESS / 2.0
	_wall(shell, "LeftWall", Vector3(WALL_THICKNESS, WALL_HEIGHT, SIZE + WALL_THICKNESS), Vector3(left_x, WALL_HEIGHT / 2.0, -WALL_THICKNESS / 2.0), brick)
	_wall(shell, "BackWall", Vector3(SIZE, WALL_HEIGHT, WALL_THICKNESS), Vector3(0.0, WALL_HEIGHT / 2.0, back_z), brick)
	_wall(shell, "LeftCap", Vector3(WALL_THICKNESS + 0.06, 0.08, SIZE + WALL_THICKNESS + 0.06), Vector3(left_x, WALL_HEIGHT + 0.04, -WALL_THICKNESS / 2.0), trim)
	_wall(shell, "BackCap", Vector3(SIZE + 0.06, 0.08, WALL_THICKNESS + 0.06), Vector3(0.03, WALL_HEIGHT + 0.04, back_z), trim)
	PropBuilder.box(shell, "LeftBaseboard", Vector3(0.04, 0.12, SIZE), Vector3(-half + 0.02, 0.06, 0.0), base_board)
	PropBuilder.box(shell, "BackBaseboard", Vector3(SIZE, 0.12, 0.04), Vector3(0.0, 0.06, -half + 0.02), base_board)

	_window(shell, Vector3(-half + 0.01, 1.6, -1.2))
	_door(shell, Vector3(-half + 0.03, 0.0, 2.1))
	return shell


static func _wall(parent: Node3D, node_name: String, size: Vector3, position: Vector3, material: StandardMaterial3D) -> void:
	var wall: MeshInstance3D = PropBuilder.box(parent, node_name, size, position, material)
	wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Ventana en la pared izquierda, mirando hacia +X.
static func _window(parent: Node3D, center: Vector3) -> void:
	var window: Node3D = PropBuilder.group(parent, "Window", center)
	var frame: StandardMaterial3D = WorldPalette.solid(WorldPalette.WOOD_DARK)
	PropBuilder.quad(window, "View", Vector2(1.16, 0.86), Vector3(0.0, 0.0, 0.0), WorldPalette.glow("ffffff", "window_view"), Vector3(0.0, 90.0, 0.0))
	PropBuilder.box(window, "Top", Vector3(0.08, 0.08, 1.32), Vector3(0.0, 0.47, 0.0), frame)
	PropBuilder.box(window, "Bottom", Vector3(0.14, 0.06, 1.36), Vector3(0.03, -0.47, 0.0), frame)
	PropBuilder.box(window, "Left", Vector3(0.08, 0.86, 0.08), Vector3(0.0, 0.0, -0.62), frame)
	PropBuilder.box(window, "Right", Vector3(0.08, 0.86, 0.08), Vector3(0.0, 0.0, 0.62), frame)
	PropBuilder.box(window, "Middle", Vector3(0.05, 0.86, 0.04), Vector3(0.0, 0.0, 0.0), frame)


## Puerta en la pared izquierda, cerca del frente.
static func _door(parent: Node3D, base: Vector3) -> void:
	var door: Node3D = PropBuilder.group(parent, "Door", base)
	PropBuilder.box(door, "Frame", Vector3(0.06, 2.0, 1.0), Vector3(0.0, 1.0, 0.0), WorldPalette.solid("4a2f1c"))
	PropBuilder.box(door, "Panel", Vector3(0.05, 1.88, 0.86), Vector3(0.03, 0.94, 0.0), WorldPalette.solid("8a5a33"))
	PropBuilder.box(door, "PanelInset", Vector3(0.02, 0.7, 0.6), Vector3(0.06, 1.35, 0.0), WorldPalette.solid("7a4e2c"))
	PropBuilder.sphere(door, "Knob", 0.035, Vector3(0.08, 0.95, -0.32), WorldPalette.solid("f5cf3c"))

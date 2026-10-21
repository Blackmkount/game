class_name PrinterModel
extends RefCounted
## Modelo 3D de cada impresora, armado con formas básicas. Cada familia se
## ve distinta (GDD, sección 8). El frente mira hacia +Z y la base queda en
## y = 0.


static func build(parent: Node3D, node_name: String, printer_id: String, spool_color: String = "f2efe6") -> Node3D:
	var printer: Node3D = PropBuilder.group(parent, node_name)
	match printer_id:
		"cubo_uno":
			_open_frame(printer, WorldPalette.PLASTIC_BLACK, WorldPalette.ACCENT_BLUE, spool_color, 1.0)
		"rayo_mini":
			_open_frame(printer, "e6e8ee", "4cbf5a", spool_color, 0.82)
		"rayo_x1":
			_open_frame(printer, "e6e8ee", "4cbf5a", spool_color, 1.0)
		"prisma_mc":
			_open_frame(printer, "e6e8ee", "9b5de5", spool_color, 1.0)
			_color_box(printer, Vector3(0.0, 0.62, -0.05))
		"boveda_p1", "titan_pro":
			_enclosed(printer, printer_id == "titan_pro", spool_color)
		"gota_r1":
			_resin(printer)
		_:
			_open_frame(printer, WorldPalette.METAL_MID, WorldPalette.ACCENT_BLUE, spool_color, 1.0)
	return printer


## Impresora abierta de cama móvil (tipo "bedslinger"), como la Cubo Uno.
static func _open_frame(printer: Node3D, frame_hex: String, accent_hex: String, spool_color: String, size: float) -> void:
	var frame: StandardMaterial3D = WorldPalette.solid(frame_hex)
	var dark: StandardMaterial3D = WorldPalette.solid(WorldPalette.PLASTIC_BLACK)
	var metal: StandardMaterial3D = WorldPalette.solid(WorldPalette.METAL_MID)
	var s: float = size
	PropBuilder.box(printer, "Base", Vector3(0.44, 0.08, 0.42) * s, Vector3(0.0, 0.04, 0.0) * s, frame)
	PropBuilder.box(printer, "Bed", Vector3(0.28, 0.02, 0.28) * s, Vector3(0.0, 0.1, 0.03) * s, dark)
	PropBuilder.box(printer, "LeftPost", Vector3(0.035, 0.44, 0.04) * s, Vector3(-0.19, 0.3, -0.09) * s, frame)
	PropBuilder.box(printer, "RightPost", Vector3(0.035, 0.44, 0.04) * s, Vector3(0.19, 0.3, -0.09) * s, frame)
	PropBuilder.box(printer, "TopBar", Vector3(0.415, 0.035, 0.04) * s, Vector3(0.0, 0.535, -0.09) * s, frame)
	PropBuilder.box(printer, "Gantry", Vector3(0.38, 0.03, 0.03) * s, Vector3(0.0, 0.25, -0.06) * s, metal)
	var head: Node3D = PropBuilder.group(printer, "PrintHead", Vector3(-0.05, 0.25, -0.02) * s)
	PropBuilder.box(head, "Carriage", Vector3(0.07, 0.08, 0.05) * s, Vector3.ZERO, dark)
	PropBuilder.box(head, "Fan", Vector3(0.05, 0.05, 0.01) * s, Vector3(0.0, 0.0, 0.03) * s, WorldPalette.solid(accent_hex))
	PropBuilder.quad(printer, "Display", Vector2(0.1, 0.05) * s, Vector3(0.14, 0.05, 0.215) * s, WorldPalette.glow("ffffff", "printer_display"))
	PropBuilder.box(printer, "SpoolArm", Vector3(0.03, 0.08, 0.03) * s, Vector3(0.0, 0.59, -0.09) * s, frame)
	SpoolModel.build(printer, "Spool", Vector3(0.0, 0.64, -0.09) * s, spool_color, 0.09 * s)


## Impresora cerrada tipo caja (Bóveda P1, Titán Pro).
static func _enclosed(printer: Node3D, large: bool, spool_color: String) -> void:
	var s: float = 1.3 if large else 1.0
	var body: StandardMaterial3D = WorldPalette.solid(WorldPalette.PLASTIC_BLACK)
	PropBuilder.box(printer, "Body", Vector3(0.4, 0.46, 0.4) * s, Vector3(0.0, 0.23, 0.0) * s, body)
	PropBuilder.quad(printer, "Window", Vector2(0.3, 0.3) * s, Vector3(0.0, 0.25, 0.201) * s, WorldPalette.glow("ffcf7a"))
	PropBuilder.box(printer, "Part", Vector3(0.08, 0.1, 0.08) * s, Vector3(0.0, 0.16, 0.12) * s, WorldPalette.solid(spool_color))
	PropBuilder.quad(printer, "Display", Vector2(0.08, 0.05) * s, Vector3(-0.12, 0.06, 0.201) * s, WorldPalette.glow("ffffff", "printer_display"))
	if large:
		_color_box(printer, Vector3(0.0, 0.62, -0.02))


## Caja de colores para impresoras multicolor.
static func _color_box(printer: Node3D, position: Vector3) -> void:
	var box: Node3D = PropBuilder.group(printer, "ColorBox", position)
	PropBuilder.box(box, "Case", Vector3(0.38, 0.1, 0.16), Vector3.ZERO, WorldPalette.solid("e6e8ee"))
	var colors: Array[String] = ["e0453a", "f5cf3c", "3b7fe0", "4cbf5a"]
	for i: int in colors.size():
		PropBuilder.box(box, "Color%d" % i, Vector3(0.06, 0.04, 0.01), Vector3(-0.13 + i * 0.087, 0.0, 0.08), WorldPalette.solid(colors[i]))


## Impresora de resina: base y tapa ámbar.
static func _resin(printer: Node3D) -> void:
	PropBuilder.box(printer, "Base", Vector3(0.3, 0.14, 0.3), Vector3(0.0, 0.07, 0.0), WorldPalette.solid(WorldPalette.PLASTIC_BLACK))
	PropBuilder.box(printer, "Lid", Vector3(0.26, 0.3, 0.26), Vector3(0.0, 0.29, 0.0), WorldPalette.solid("f28c28"))
	PropBuilder.quad(printer, "Display", Vector2(0.1, 0.05), Vector3(0.0, 0.07, 0.151), WorldPalette.glow("ffffff", "printer_display"))

class_name RoomLights
extends RefCounted
## Las luces que salen de los muebles del cuarto y lo que el cuarto les
## cuenta a los sombreadores del mundo (biblia de arte §6.2–6.3): dónde van
## la lámpara y el monitor del escritorio (cc_pl0, cc_pl1) y el LED de la
## impresora del piso (cc_pl3), los halos de noche del escritorio, las cajas
## que tapan el parche de sol de la ventana (cc_occ_a, cc_occ_b) y dónde
## está el personaje (cc_char_pos). RoomView decide cuándo.

## Radio de la mancha de sombra suave bajo el personaje (biblia §3.5).
const CHARACTER_SHADOW_RADIUS: float = 0.36


## Las luces del escritorio: la lámpara en su ampolleta y el monitor delante
## de la pantalla, en los marcadores "LampBulb" y "ScreenGlow" del modelo.
static func place_desk(day_cycle: DayCycle, desk: Node3D) -> void:
	day_cycle.place_light("desk_lamp", (desk.get_node("LampBulb") as Node3D).global_position)
	day_cycle.place_light("monitor", (desk.get_node("ScreenGlow") as Node3D).global_position)


## Los halos de noche del escritorio (ComputerDeskModel.night_lights): la
## mancha de la lámpara sobre la mesa y el resplandor del monitor.
static func add_desk_halos(halos: HaloField, desk: Node3D) -> void:
	for light: Dictionary in ComputerDeskModel.night_lights():
		halos.add_glow(desk.transform * (light["at"] as Transform3D), light["size"], light["color"])


## La luz LED que alumbra la cama de la impresora del piso, en su marcador
## "BedLight".
static func place_printer_led(day_cycle: DayCycle, printer: Node3D) -> void:
	day_cycle.place_light("printer_led", (printer.get_node("BedLight") as Node3D).global_position)


## La caja que tapa el parche de sol bajo la ventana: la del mueble de ese
## lugar (del escritorio, su tablero); sin mueble, ninguna (AABB vacía).
static func window_box(under_window: Node3D, furniture_id: String) -> AABB:
	if under_window == null:
		return AABB()
	var local: AABB = ComputerDeskModel.table_box() if furniture_id == DeskSheet.FURNITURE_ID else PropBounds.local_aabb(under_window)
	return under_window.transform * local


## Publica las dos cajas que tapan el parche de sol: la de bajo la ventana
## (cc_occ_a) y la cama (cc_occ_b).
static func publish_occluders(window: AABB, bed: AABB) -> void:
	_publish_box(&"cc_occ_a_c", &"cc_occ_a_h", window)
	_publish_box(&"cc_occ_b_c", &"cc_occ_b_h", bed)


## Dónde están los pies del personaje (`feet`): su mancha en el piso y la
## cápsula que tapa el parche de la ventana.
static func publish_character(feet: Vector3) -> void:
	RenderingServer.global_shader_parameter_set(&"cc_char_pos", Vector4(feet.x, feet.y, feet.z, CHARACTER_SHADOW_RADIUS))


static func _publish_box(center_name: StringName, half_name: StringName, box: AABB) -> void:
	var center: Vector3 = box.get_center()
	var half: Vector3 = box.size / 2.0
	RenderingServer.global_shader_parameter_set(center_name, Vector4(center.x, center.y, center.z, 0.0))
	RenderingServer.global_shader_parameter_set(half_name, Vector4(half.x, half.y, half.z, 0.0))

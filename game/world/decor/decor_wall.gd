class_name DecorWall
extends RefCounted
## Lo que cuelga en las paredes del cuarto (biblia de arte §8.8): en la del
## fondo, tres pósters inventados, la guirnalda de focos, la bufanda de un
## club inventado, el reloj, el calendario de la tienda del barrio y el
## diploma; en la de la ventana, el corcho con la foto familiar encima, el
## plano de una impresora, la guitarra colgada, la repisa de las primeras
## impresiones, el banderín sobre la puerta y el enchufe con el cable del
## escritorio; y lo que hay en el alféizar.
##
## Lo que cambia con el nivel (add_story) es solo de pared y de estante, así
## la grilla de caminar nunca cambia: las piezas de la repisa, las notas del
## corcho, el billete enmarcado de la primera venta, la placa del taller y
## la tira LED.
##
## Coordenadas del cuarto; nada tiene texto legible ni marcas.

## Caras de adentro de la pared del fondo (z) y de la de la ventana (x).
const BACK: float = -3.0
const LEFT: float = -3.0
## Pósters (biblia: 0,42 × 0,58 en el friso, y 1,98–2,56): centro en x.
const POSTER_SIZE: Vector2 = Vector2(0.42, 0.58)
const POSTER_Y: float = 2.27
const POSTER_X: Array[float] = [-1.45, 0.25, 1.95]
## Guirnalda: clavos (x), su alto y los focos de cada tramo (14 en total).
const GARLAND_ANCHORS: Array[float] = [-2.1, -1.45, 0.25, 1.95, 2.6]
const GARLAND_Y: float = 2.66
const GARLAND_BULBS: Array[int] = [2, 5, 5, 2]
## Lo que cae cada tramo, por metro de largo.
const GARLAND_SAG: float = 0.05
## Tira LED del taller (nivel 5+): la misma que alumbra DayCycle.
const LED_STRIP_Y: float = 2.72
## Bufanda, reloj, calendario y diploma en la pared del fondo (centros).
const SCARF_CENTER: Vector2 = Vector2(1.1, 2.3)
const CLOCK_CENTER: Vector2 = Vector2(-0.6, 1.55)
const CLOCK_RADIUS: float = 0.13
const CALENDAR_CENTER: Vector2 = Vector2(1.1, 1.45)
const DIPLOMA_CENTER: Vector2 = Vector2(2.82, 1.55)
const PLAQUE_CENTER: Vector2 = Vector2(2.82, 1.95)
## Billete enmarcado de la primera venta (nivel 3+), sobre el librero.
const BILL_CENTER: Vector2 = Vector2(-2.7, 2.15)
## Pared de la ventana (z, y): corcho, foto familiar, plano, guitarra,
## banderín sobre la puerta.
const CORK_CENTER: Vector2 = Vector2(-2.3, 1.6)
const CORK_SIZE: Vector2 = Vector2(0.5, 0.5)
const PHOTO_CENTER: Vector2 = Vector2(-2.3, 2.27)
const BLUEPRINT_CENTER: Vector2 = Vector2(-1.2, 2.46)
const GUITAR_BASE: Vector2 = Vector2(-0.22, 1.0)
## Caja de la guitarra: (centro en y, radio) del círculo de abajo y del de
## arriba, la cintura (donde se juntan) y qué tan suave es la unión.
const GUITAR_LOWER: Vector2 = Vector2(0.16, 0.155)
const GUITAR_UPPER: Vector2 = Vector2(0.37, 0.12)
const GUITAR_WAIST: float = 0.288
const GUITAR_SMOOTH: float = 45.0
const PENNANT_CENTER: Vector2 = Vector2(2.1, 2.35)
## Repisa de las primeras impresiones sobre el lugar 1: centro (z), alto de
## su cara de arriba, largo y fondo (no choca con lo que va en el lugar 1).
const SHELF_Z: float = 0.7
const SHELF_TOP: float = 2.05
const SHELF_SIZE: Vector2 = Vector2(0.9, 0.14)
## Alféizar: alto de la cara de arriba y x de lo que hay encima.
const SILL_TOP: float = 1.165
const SILL_X: float = -3.01
## Niveles de decoración (RoomDecor.tier_for): desde el 1 se ven las
## primeras cinco piezas completas y desde el 2 la placa y la tira LED.
const FULL_SHELF_TIER: int = 1
const WORKSHOP_TIER: int = 2


## Lo de las paredes que no cambia con el nivel.
static func add_static(kit: KitMesh) -> void:
	kit.ao_enabled = false
	_posters(kit)
	_garland(kit)
	_scarf(kit)
	_clock(kit)
	_calendar(kit)
	_diploma(kit)
	_cork_board(kit)
	_family_photo(kit)
	_blueprint(kit)
	_guitar(kit)
	_shelf(kit)
	_pennant(kit)
	_outlet(kit)
	_sill(kit)
	kit.ao_enabled = true


## Lo que cambia con el nivel de decoración `tier` (0, 1 o 2).
static func add_story(kit: KitMesh, tier: int) -> void:
	kit.ao_enabled = false
	_first_prints(kit, tier)
	_cork_notes(kit, tier)
	if tier >= FULL_SHELF_TIER:
		_bill(kit)
	if tier >= WORKSHOP_TIER:
		_plaque(kit)
		_led_strip(kit)
	kit.ao_enabled = true


## Las luces de noche de la decoración (los halos de HaloField): dónde
## (un plano: su +Y mira afuera), de qué tamaño, de qué color, desde qué
## nivel de decoración se ven y si parpadean (los focos de la guirnalda).
static func night_lights() -> Array[Dictionary]:
	var lights: Array[Dictionary] = []
	var on_back: Basis = Basis(Vector3.RIGHT, PI / 2.0)
	for bulb: Vector3 in garland_bulbs():
		lights.append({"at": Transform3D(on_back, Vector3(bulb.x, bulb.y, BACK + 0.004)), "size": Vector2(0.24, 0.24), "color": Color(LookPalette.STRING_LIGHTS) * 0.44, "tier": 0, "twinkle": true})
	var on_left: Basis = Basis(Vector3.BACK, -PI / 2.0)
	lights.append({"at": Transform3D(on_left, Vector3(LEFT + 0.004, SHELF_TOP + 0.05, _shelf_world_z(0.02))), "size": Vector2(0.22, 0.22), "color": Color(LookPalette.GLOW_IN_DARK) * 0.51, "tier": FULL_SHELF_TIER})
	lights.append({"at": Transform3D(Basis.IDENTITY, DecorItems.PHONE_AT + Vector3(0.0, 0.012, 0.0)), "size": Vector2(0.22, 0.22), "color": Color(LookPalette.PHONE_SCREEN) * 0.33, "tier": 0})
	var lamp: Vector3 = DecorItems.BED_LAMP_BULB
	lights.append({"at": Transform3D(Basis.IDENTITY, Vector3(lamp.x, DecorItems.BED_HEADBOARD + DecorItems.BED_LEDGE.x + 0.002, lamp.z)), "size": Vector2(0.55, 0.4), "color": Color(LookPalette.LAMP_HALO) * 0.44, "tier": 0})
	return lights


## Dónde cuelga cada foco de la guirnalda.
static func garland_bulbs() -> PackedVector3Array:
	var bulbs: PackedVector3Array = PackedVector3Array()
	for span: int in GARLAND_BULBS.size():
		var count: int = GARLAND_BULBS[span]
		for i: int in count:
			bulbs.append(_garland_point(span, (i + 0.5) / count) + Vector3(0.0, -0.03, 0.006))
	return bulbs


## Punto del cable de la guirnalda en el tramo `span`, a la fracción `t`.
static func _garland_point(span: int, t: float) -> Vector3:
	var a: float = GARLAND_ANCHORS[span]
	var b: float = GARLAND_ANCHORS[span + 1]
	var sag: float = GARLAND_SAG * (b - a) * 4.0 * t * (1.0 - t)
	return Vector3(lerpf(a, b, t), GARLAND_Y - sag, BACK + 0.008 + 0.01 * 4.0 * t * (1.0 - t))


## Cuadro en la pared del fondo (mira a +Z) o en la de la ventana (mira a
## +X): `center` en (x o z, y).
static func _on_back(center: Vector2) -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(center.x, center.y, BACK))


static func _on_left(center: Vector2) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(LEFT, center.y, center.x))


## Un rectángulo plano en la pintura de `hex`, centrado en (x, y) del cuadro
## y `depth` delante de la pared.
static func _flat(kit: KitMesh, hex: String, size: Vector2, at: Vector2, depth: float, turn: float = 0.0) -> void:
	kit.paint(hex, WorldPalette.Surface.SMOOTH, 0.1)
	kit.quad(size, Vector3(at.x, at.y, depth), Vector3(0.0, 0.0, turn))


## Un triángulo plano del cuadro, que mira afuera de la pared.
static func _tri(kit: KitMesh, hex: String, a: Vector2, b: Vector2, c: Vector2, depth: float) -> void:
	kit.paint(hex, WorldPalette.Surface.SMOOTH, 0.1)
	DecorItems.facing(kit, Vector3(a.x, a.y, depth), Vector3(b.x, b.y, depth), Vector3(c.x, c.y, depth), Vector3.BACK)


# --- Pared del fondo -------------------------------------------------------------

static func _posters(kit: KitMesh) -> void:
	var paper: Vector2 = POSTER_SIZE
	var art: Vector2 = paper - Vector2(0.05, 0.07)
	var h: Vector2 = art / 2.0
	for i: int in POSTER_X.size():
		kit.origin = _on_back(Vector2(POSTER_X[i], POSTER_Y))
		_flat(kit, LookPalette.SHEET, paper, Vector2.ZERO, 0.001)
		for corner: Vector2 in KitMesh.SQUARE:
			_flat(kit, LookPalette.TAPE, Vector2(0.05, 0.016), corner * (paper / 2.0 - Vector2(0.01, 0.01)), 0.004, 45.0 * corner.x * corner.y)
	# Atardecer en los cerros.
	var sunset: Array[String] = LookPalette.POSTER_SUNSET
	kit.origin = _on_back(Vector2(POSTER_X[0], POSTER_Y))
	_flat(kit, sunset[1], Vector2(art.x, h.y), Vector2(0.0, h.y / 2.0), 0.002)
	_flat(kit, sunset[0], Vector2(art.x, h.y), Vector2(0.0, -h.y / 2.0), 0.002)
	kit.paint(LookPalette.SHEET, WorldPalette.Surface.SMOOTH, 0.1)
	kit.disc(0.075, Vector3(0.01, -0.02, 0.0025), Vector3.ZERO, 16)
	_tri(kit, sunset[1], Vector2(-h.x, -0.1), Vector2(-0.07, 0.03), Vector2(0.05, -0.1), 0.003)
	_tri(kit, sunset[1], Vector2(0.0, -0.1), Vector2(0.1, 0.0), Vector2(h.x, -0.1), 0.003)
	_tri(kit, sunset[2], Vector2(-h.x, -h.y), Vector2(-0.04, -0.06), Vector2(0.12, -h.y), 0.0035)
	_tri(kit, sunset[2], Vector2(0.0, -h.y), Vector2(0.13, -0.09), Vector2(h.x, -h.y), 0.0035)
	_flat(kit, sunset[2], Vector2(art.x, 0.04), Vector2(0.0, -h.y + 0.02), 0.0036)
	# Una boquilla imprimiendo un barquito, capa a capa.
	var nozzle: Array[String] = LookPalette.POSTER_NOZZLE
	kit.origin = _on_back(Vector2(POSTER_X[1], POSTER_Y))
	_flat(kit, nozzle[1], art, Vector2.ZERO, 0.002)
	_flat(kit, nozzle[0], Vector2(0.1, 0.055), Vector2(0.0, 0.17), 0.003)
	_tri(kit, nozzle[0], Vector2(-0.03, 0.143), Vector2(0.03, 0.143), Vector2(0.0, 0.1), 0.003)
	_flat(kit, nozzle[0], Vector2(0.006, 0.05), Vector2(0.0, 0.07), 0.003)
	_tri(kit, nozzle[0], Vector2(-0.12, -0.09), Vector2(0.12, -0.09), Vector2(0.09, -0.17), 0.003)
	_tri(kit, nozzle[0], Vector2(-0.12, -0.09), Vector2(0.09, -0.17), Vector2(-0.1, -0.17), 0.003)
	_flat(kit, nozzle[0], Vector2(0.09, 0.06), Vector2(-0.02, -0.06), 0.003)
	_flat(kit, nozzle[0], Vector2(0.02, 0.035), Vector2(0.03, -0.015), 0.003)
	for k: int in 5:
		_flat(kit, nozzle[1], Vector2(0.26, 0.004), Vector2(0.0, -0.163 + k * 0.022), 0.0034)
	_flat(kit, nozzle[0], Vector2(0.3, 0.008), Vector2(0.0, -0.19), 0.003)
	# Teleférico sobre el valle.
	var cable_car: Array[String] = LookPalette.POSTER_CABLE_CAR
	kit.origin = _on_back(Vector2(POSTER_X[2], POSTER_Y))
	_flat(kit, cable_car[2], art, Vector2.ZERO, 0.002)
	kit.paint(cable_car[0], WorldPalette.Surface.SMOOTH, 0.1)
	kit.disc(0.04, Vector3(0.11, 0.17, 0.0025), Vector3.ZERO, 14)
	_tri(kit, LookPalette.PLANTS[2], Vector2(-h.x, -h.y), Vector2(-0.07, 0.0), Vector2(0.09, -h.y), 0.003)
	_tri(kit, cable_car[1], Vector2(-0.03, -h.y), Vector2(0.11, -0.05), Vector2(h.x, -h.y), 0.0033)
	_flat(kit, cable_car[1], Vector2(art.x, 0.05), Vector2(0.0, -h.y + 0.025), 0.0035)
	var from: Vector2 = Vector2(-h.x, 0.15)
	var to: Vector2 = Vector2(h.x, 0.01)
	_flat(kit, LookPalette.RUG_PATTERN[2], Vector2(from.distance_to(to), 0.004), (from + to) / 2.0, 0.0036, rad_to_deg((to - from).angle()))
	var car: Vector2 = from.lerp(to, 0.55)
	_flat(kit, LookPalette.RUG_PATTERN[2], Vector2(0.004, 0.035), car + Vector2(0.0, -0.017), 0.0036)
	_flat(kit, cable_car[0], Vector2(0.075, 0.05), car + Vector2(0.0, -0.058), 0.0037)
	_flat(kit, cable_car[2], Vector2(0.05, 0.016), car + Vector2(0.0, -0.05), 0.0039)
	kit.origin = Transform3D.IDENTITY


## Guirnalda de focos entre cinco clavos, sobre los pósters. Los focos
## brillan de noche y parpadean suave (y dejan su halo en la pared, que
## parpadea con ellos: night_lights).
static func _garland(kit: KitMesh) -> void:
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.METAL, 0.4)
	for x: float in GARLAND_ANCHORS:
		kit.box(Vector3(0.012, 0.012, 0.012), Vector3(x, GARLAND_Y, BACK + 0.006), 0.0)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.3)
	for span: int in GARLAND_BULBS.size():
		var wire: PackedVector3Array = PackedVector3Array()
		for k: int in 9:
			wire.append(_garland_point(span, k / 8.0))
		kit.tube(wire, 0.0022, 4, 1, false)
	for bulb: Vector3 in garland_bulbs():
		kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.3)
		kit.box(Vector3(0.008, 0.01, 0.008), bulb + Vector3(0.0, 0.021, 0.0), 0.0)
		kit.night_glow(LookPalette.STRING_LIGHTS, 1.3, true)
		kit.cylinder(0.016, 0.032, bulb, Vector3.ZERO, 8, 0.0, 0.007)


## Bufanda de un club de fútbol inventado, colgada de dos clavos: franjas
## verde azulado y crema, un escudo redondo y flecos en las puntas.
static func _scarf(kit: KitMesh) -> void:
	kit.origin = _on_back(SCARF_CENTER)
	var blocks: int = 5
	var block: Vector2 = Vector2(0.18, 0.16)
	for i: int in blocks:
		var x: float = (i - (blocks - 1) / 2.0) * block.x
		var sag: float = -0.025 * (1.0 - pow(x / 0.45, 2.0))
		kit.paint(LookPalette.RUG_PATTERN[0] if i % 2 == 0 else LookPalette.SHEET, WorldPalette.Surface.FABRIC, 0.05)
		kit.box(Vector3(block.x + 0.002, block.y, 0.006), Vector3(x, sag, 0.004), 0.0, Vector3(0.0, 0.0, 2.5 * (1.0 if i % 2 == 0 else -1.0)))
	kit.paint(LookPalette.RUG_PATTERN[3], WorldPalette.Surface.FABRIC, 0.1)
	kit.disc(0.05, Vector3(0.0, -0.025, 0.0075), Vector3.ZERO, 14)
	kit.paint(LookPalette.RUG_PATTERN[2], WorldPalette.Surface.FABRIC, 0.1)
	kit.disc(0.032, Vector3(0.0, -0.025, 0.008), Vector3.ZERO, 12)
	kit.paint(LookPalette.RUG_PATTERN[0], WorldPalette.Surface.FABRIC, 0.05)
	for side: float in KitMesh.SIGNS:
		for k: int in 4:
			kit.quad(Vector2(0.012, 0.05), Vector3(side * (0.45 + 0.012), -0.06 + k * 0.035, 0.004), Vector3(0.0, 0.0, side * 80.0))
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.METAL, 0.4)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(0.01, 0.01, 0.012), Vector3(side * 0.4, 0.075, 0.008), 0.0)
	kit.origin = Transform3D.IDENTITY


## Reloj de pared verde azulado (entre los lugares 2 y 3).
static func _clock(kit: KitMesh) -> void:
	var saved: float = kit.detail
	kit.detail = 1.0
	kit.origin = _on_back(CLOCK_CENTER)
	kit.paint(LookPalette.RUG_PATTERN[0], WorldPalette.Surface.SMOOTH, 0.45)
	kit.cylinder(CLOCK_RADIUS, 0.035, Vector3(0.0, 0.0, 0.0175), Vector3(90.0, 0.0, 0.0), 24, 0.008)
	kit.paint(LookPalette.SHEET, WorldPalette.Surface.SMOOTH, 0.3)
	kit.disc(CLOCK_RADIUS - 0.018, Vector3(0.0, 0.0, 0.0355), Vector3.ZERO, 24)
	for i: int in 12:
		var a: float = i * TAU / 12.0
		var long: bool = i % 3 == 0
		_flat(kit, LookPalette.RUG_PATTERN[2], Vector2(0.006, 0.02 if long else 0.01), Vector2(sin(a), cos(a)) * 0.09, 0.036, -rad_to_deg(a))
	for hand: Vector2 in [Vector2(-60.0, 0.05), Vector2(60.0, 0.08)]:
		var a: float = deg_to_rad(hand.x)
		_flat(kit, LookPalette.RUG_PATTERN[2], Vector2(0.007, hand.y), Vector2(sin(a), cos(a)) * hand.y / 2.0, 0.037, -hand.x)
	kit.paint(LookPalette.RUG_PATTERN[1], WorldPalette.Surface.SMOOTH, 0.3)
	kit.disc(0.008, Vector3(0.0, 0.0, 0.038), Vector3.ZERO, 8)
	kit.origin = Transform3D.IDENTITY
	kit.detail = saved


## Calendario de la tienda del barrio (entre los lugares 3 y 4): la foto de
## la tienda arriba, la grilla de días abajo y un día marcado.
static func _calendar(kit: KitMesh) -> void:
	kit.origin = _on_back(CALENDAR_CENTER)
	_flat(kit, LookPalette.SHEET, Vector2(0.24, 0.34), Vector2.ZERO, 0.001)
	_flat(kit, LookPalette.RUG_PATTERN[1], Vector2(0.24, 0.035), Vector2(0.0, 0.1525), 0.0015)
	_flat(kit, LookPalette.PILLOW, Vector2(0.2, 0.1), Vector2(0.0, 0.08), 0.0015)
	_tri(kit, LookPalette.PLANTS[0], Vector2(-0.1, 0.03), Vector2(-0.02, 0.09), Vector2(0.06, 0.03), 0.002)
	_flat(kit, LookPalette.CRATE, Vector2(0.06, 0.04), Vector2(0.05, 0.05), 0.0022)
	_tri(kit, LookPalette.RUG_PATTERN[1], Vector2(0.015, 0.07), Vector2(0.085, 0.07), Vector2(0.05, 0.095), 0.0022)
	for row: int in 4:
		for col: int in 5:
			var hex: String = LookPalette.FILAMENT_RED if row == 1 and col == 3 else LookPalette.MELAMINE_SHADE
			_flat(kit, hex, Vector2(0.032, 0.024), Vector2(-0.084 + col * 0.042, -0.02 - row * 0.034), 0.0015)
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.METAL, 0.4)
	kit.box(Vector3(0.06, 0.012, 0.006), Vector3(0.0, 0.17, 0.004), 0.0)
	kit.origin = Transform3D.IDENTITY


## Diploma enmarcado en la punta derecha.
static func _diploma(kit: KitMesh) -> void:
	kit.origin = _on_back(DIPLOMA_CENTER)
	_frame(kit, Vector2(0.3, 0.23), LookPalette.WOOD_DARK)
	_flat(kit, LookPalette.SHEET, Vector2(0.25, 0.18), Vector2.ZERO, 0.0205)
	_flat(kit, LookPalette.RUG_PATTERN[2], Vector2(0.15, 0.012), Vector2(0.0, 0.055), 0.021)
	for k: int in 3:
		_flat(kit, LookPalette.CONCRETE_GRAIN, Vector2(0.18 - k * 0.04, 0.006), Vector2(0.0, 0.02 - k * 0.022), 0.021)
	_tri(kit, LookPalette.RUG_PATTERN[1], Vector2(0.06, -0.05), Vector2(0.075, -0.085), Vector2(0.088, -0.05), 0.021)
	kit.paint(LookPalette.METAL_BRASS, WorldPalette.Surface.METAL, 0.5)
	kit.disc(0.022, Vector3(0.075, -0.045, 0.0215), Vector3.ZERO, 12)
	kit.origin = Transform3D.IDENTITY


## Marco de madera de `size` (por fuera), contra la pared del cuadro.
static func _frame(kit: KitMesh, size: Vector2, hex: String) -> void:
	kit.paint(hex, WorldPalette.Surface.WOOD, 0.3)
	kit.box(Vector3(size.x, size.y, 0.02), Vector3(0.0, 0.0, 0.01), 0.005)


# --- Pared de la ventana ---------------------------------------------------------

## Corcho con su marco (las notas y fotos cambian con el nivel: _cork_notes).
static func _cork_board(kit: KitMesh) -> void:
	kit.origin = _on_left(CORK_CENTER)
	_frame(kit, CORK_SIZE + Vector2(0.03, 0.03), LookPalette.WOOD_MID)
	kit.paint(LookPalette.CARDBOARD, WorldPalette.Surface.FABRIC, 0.0)
	kit.quad(CORK_SIZE - Vector2(0.02, 0.02), Vector3(0.0, 0.0, 0.0205))
	kit.origin = Transform3D.IDENTITY


## Foto familiar enmarcada encima del corcho: cielo, pasto y tres personas.
static func _family_photo(kit: KitMesh) -> void:
	kit.origin = _on_left(PHOTO_CENTER)
	_frame(kit, Vector2(0.28, 0.34), LookPalette.WOOD_DARK)
	_flat(kit, LookPalette.SHEET, Vector2(0.24, 0.3), Vector2.ZERO, 0.0205)
	_flat(kit, LookPalette.PILLOW, Vector2(0.2, 0.14), Vector2(0.0, 0.06), 0.021)
	_flat(kit, LookPalette.PLANTS[1], Vector2(0.2, 0.12), Vector2(0.0, -0.07), 0.021)
	var people: Array[Array] = [[-0.05, 0.0, LookPalette.RUG_PATTERN[1]], [0.05, 0.005, LookPalette.RUG_PATTERN[2]], [0.0, -0.03, LookPalette.RUG_PATTERN[3]]]
	for person: Array in people:
		var x: float = person[0]
		var y: float = person[1]
		_flat(kit, person[2], Vector2(0.045, 0.07), Vector2(x, y - 0.035), 0.0215)
		kit.paint(LookPalette.SKIN, WorldPalette.Surface.SMOOTH, 0.1)
		kit.disc(0.017, Vector3(x, y + 0.02, 0.022), Vector3.ZERO, 8)
	kit.origin = Transform3D.IDENTITY


## El plano de una impresora (dibujo técnico) sobre la barra de la cortina.
static func _blueprint(kit: KitMesh) -> void:
	kit.origin = _on_left(BLUEPRINT_CENTER)
	var line: String = LookPalette.PILLOW
	_flat(kit, LookPalette.RUG_PATTERN[2], Vector2(0.7, 0.3), Vector2.ZERO, 0.001)
	for x: float in [-0.12, 0.08]:
		_flat(kit, line, Vector2(0.006, 0.2), Vector2(x, 0.0), 0.0015)
	_flat(kit, line, Vector2(0.206, 0.006), Vector2(-0.02, 0.1), 0.0015)
	_flat(kit, line, Vector2(0.16, 0.01), Vector2(-0.02, -0.05), 0.0015)
	_flat(kit, line, Vector2(0.05, 0.03), Vector2(-0.03, 0.05), 0.0015)
	_tri(kit, line, Vector2(-0.045, 0.035), Vector2(-0.015, 0.035), Vector2(-0.03, 0.015), 0.0015)
	_flat(kit, line, Vector2(0.24, 0.004), Vector2(-0.02, -0.12), 0.0015)
	for x: float in [-0.14, 0.1]:
		_flat(kit, line, Vector2(0.004, 0.02), Vector2(x, -0.12), 0.0015)
	kit.paint(line, WorldPalette.Surface.SMOOTH, 0.1)
	kit.disc(0.05, Vector3(0.22, 0.04, 0.0015), Vector3.ZERO, 16)
	kit.paint(LookPalette.RUG_PATTERN[2], WorldPalette.Surface.SMOOTH, 0.1)
	kit.disc(0.042, Vector3(0.22, 0.04, 0.002), Vector3.ZERO, 16)
	kit.paint(line, WorldPalette.Surface.SMOOTH, 0.1)
	kit.disc(0.012, Vector3(0.22, 0.04, 0.0025), Vector3.ZERO, 8)
	for corner: Vector2 in KitMesh.SQUARE:
		_flat(kit, LookPalette.TAPE, Vector2(0.045, 0.014), corner * Vector2(0.34, 0.14), 0.003, 45.0 * corner.x * corner.y)
	kit.origin = Transform3D.IDENTITY


## Guitarra acústica colgada de un gancho, entre los lugares 0 y 1: caja de
## madera oscura con la tapa clara, boca con su roseta, puente, mástil,
## clavijero y seis cuerdas.
static func _guitar(kit: KitMesh) -> void:
	kit.origin = _on_left(GUITAR_BASE)
	var face: float = 0.09
	var outline: PackedVector2Array = _guitar_outline()
	var waist: Vector3 = Vector3(0.0, GUITAR_WAIST, face)
	# Aros de madera oscura alrededor y la tapa clara (un abanico desde la
	# cintura: el contorno se ve entero desde ahí).
	kit.paint(LookPalette.WOOD_DARK, WorldPalette.Surface.WOOD, 0.45)
	for i: int in outline.size():
		var a: Vector2 = outline[i]
		var b: Vector2 = outline[(i + 1) % outline.size()]
		var out: Vector3 = Vector3(b.y - a.y, a.x - b.x, 0.0)
		DecorItems.facing(kit, Vector3(a.x, a.y, 0.004), Vector3(b.x, b.y, 0.004), Vector3(b.x, b.y, face), out)
		DecorItems.facing(kit, Vector3(a.x, a.y, 0.004), Vector3(b.x, b.y, face), Vector3(a.x, a.y, face), out)
	kit.paint(LookPalette.WOOD_LIGHT, WorldPalette.Surface.WOOD, 0.55)
	for i: int in outline.size():
		var a: Vector2 = outline[i]
		var b: Vector2 = outline[(i + 1) % outline.size()]
		DecorItems.facing(kit, waist, Vector3(a.x, a.y, face), Vector3(b.x, b.y, face), Vector3.BACK)
	kit.paint(LookPalette.WOOD_DARK, WorldPalette.Surface.SMOOTH, 0.3)
	kit.disc(0.05, Vector3(0.0, 0.34, face + 0.0035), Vector3.ZERO, 14)
	kit.paint(LookPalette.OUTLINE_HAIR, WorldPalette.Surface.SMOOTH, 0.1)
	kit.disc(0.043, Vector3(0.0, 0.34, face + 0.004), Vector3.ZERO, 14)
	kit.paint(LookPalette.WOOD_DARK, WorldPalette.Surface.WOOD, 0.4)
	kit.box(Vector3(0.1, 0.02, 0.012), Vector3(0.0, 0.11, face + 0.006), 0.003)
	kit.paint(LookPalette.WOOD_MID, WorldPalette.Surface.WOOD, 0.4)
	kit.box(Vector3(0.048, 0.42, 0.026), Vector3(0.0, 0.69, face - 0.01), 0.006)
	kit.paint(LookPalette.WOOD_DARK, WorldPalette.Surface.WOOD, 0.3)
	kit.box(Vector3(0.044, 0.4, 0.006), Vector3(0.0, 0.68, face + 0.005), 0.0)
	kit.box(Vector3(0.07, 0.14, 0.02), Vector3(0.0, 0.96, face - 0.014), 0.005, Vector3(-8.0, 0.0, 0.0))
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.7)
	for side: float in KitMesh.SIGNS:
		for k: int in 3:
			kit.box(Vector3(0.016, 0.01, 0.01), Vector3(side * 0.042, 0.92 + k * 0.035, face - 0.01), 0.0)
	for k: int in 6:
		kit.box(Vector3(0.0016, 0.78, 0.0016), Vector3(-0.0125 + k * 0.005, 0.5, face + 0.01), 0.0)
	# El colgador: una placa en la pared y dos brazos bajo el clavijero.
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.4)
	kit.box(Vector3(0.08, 0.03, 0.012), Vector3(0.0, 0.875, 0.006), 0.0)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(0.01, 0.01, 0.07), Vector3(side * 0.031, 0.885, 0.045), 0.0)
	kit.origin = Transform3D.IDENTITY


## Contorno de la caja de la guitarra (x, y), contra reloj vista de frente:
## la unión suave de dos círculos (abajo el grande, arriba el chico).
static func _guitar_outline() -> PackedVector2Array:
	var bottom: float = GUITAR_LOWER.x - GUITAR_LOWER.y
	var top: float = GUITAR_UPPER.x + GUITAR_UPPER.y
	var steps: int = 14
	var right: PackedVector2Array = PackedVector2Array()
	for k: int in steps + 1:
		var y: float = lerpf(bottom, top, 0.5 - 0.5 * cos(PI * k / steps))
		var w1: float = sqrt(maxf(GUITAR_LOWER.y * GUITAR_LOWER.y - pow(y - GUITAR_LOWER.x, 2.0), 0.0))
		var w2: float = sqrt(maxf(GUITAR_UPPER.y * GUITAR_UPPER.y - pow(y - GUITAR_UPPER.x, 2.0), 0.0))
		# Unión suave: la cintura queda curva, no en punta.
		var w: float = log(exp(w1 * GUITAR_SMOOTH) + exp(w2 * GUITAR_SMOOTH) - 1.0) / GUITAR_SMOOTH
		right.append(Vector2(w, y))
	var outline: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in right:
		outline.append(p)
	for k: int in range(right.size() - 2, 0, -1):
		outline.append(Vector2(-right[k].x, right[k].y))
	return outline


## La repisa de las primeras impresiones con sus escuadras impresas (lo que
## hay encima cambia con el nivel: _first_prints).
static func _shelf(kit: KitMesh) -> void:
	kit.origin = _shelf_frame()
	kit.paint(LookPalette.WOOD_LIGHT, WorldPalette.Surface.WOOD, 0.3)
	kit.box(Vector3(SHELF_SIZE.x, 0.025, SHELF_SIZE.y), Vector3(0.0, -0.0125, SHELF_SIZE.y / 2.0), 0.005)
	for x: float in [-0.33, 0.33]:
		FurnitureParts.bracket(kit, x, -0.025, 0.0, SHELF_SIZE.y)
	kit.origin = Transform3D.IDENTITY


## La repisa vista desde el cuarto: x a lo largo (hacia −z del cuarto), y
## arriba desde su cara de arriba, z hacia afuera de la pared.
static func _shelf_frame() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(LEFT, SHELF_TOP, SHELF_Z))


## z del cuarto de un punto de la repisa a `x` de su centro.
static func _shelf_world_z(x: float) -> float:
	return (_shelf_frame() * Vector3(x, 0.0, 0.0)).z


## Banderín de un club inventado sobre la puerta.
static func _pennant(kit: KitMesh) -> void:
	kit.origin = _on_left(PENNANT_CENTER)
	kit.paint(LookPalette.TRIM, WorldPalette.Surface.SMOOTH, 0.3)
	kit.box(Vector3(0.012, 0.3, 0.012), Vector3(0.26, 0.0, 0.008), 0.0)
	_tri(kit, LookPalette.RUG_PATTERN[2], Vector2(0.255, 0.13), Vector2(0.255, -0.13), Vector2(-0.3, 0.0), 0.004)
	_tri(kit, LookPalette.RUG_PATTERN[3], Vector2(0.255, 0.05), Vector2(0.255, -0.05), Vector2(-0.1, 0.0), 0.005)
	kit.paint(LookPalette.SHEET, WorldPalette.Surface.SMOOTH, 0.2)
	kit.disc(0.035, Vector3(0.17, 0.0, 0.006), Vector3.ZERO, 12)
	kit.origin = Transform3D.IDENTITY


## Enchufe de F5 bajo el interruptor, con la clavija del cable del
## escritorio: el tramo que baja de la regleta al piso y el que sube por la
## pared (el del piso es plano: DecorItems.add_flat).
static func _outlet(kit: KitMesh) -> void:
	var o: Vector3 = DecorItems.OUTLET
	kit.paint(LookPalette.TRIM, WorldPalette.Surface.SMOOTH, 0.3)
	kit.box(Vector3(0.012, 0.08, 0.08), o, 0.003)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.3)
	kit.box(Vector3(0.024, 0.03, 0.034), o + Vector3(0.012, -0.01, 0.0), 0.004)
	var r: float = DecorItems.CABLE_RADIUS
	var floor_path: PackedVector3Array = DecorItems.desk_cable_floor()
	var start: Vector3 = DecorItems.desk_cable_start()
	var first: Vector3 = floor_path[0]
	kit.tube(PackedVector3Array([start, start.lerp(first, 0.5) + Vector3(0.0, 0.002, 0.0), first]), r, 6, 3)
	var last: Vector3 = floor_path[floor_path.size() - 1]
	var wall: float = LEFT + RoomShell.BASEBOARD.y
	kit.tube(PackedVector3Array([
		last,
		Vector3(last.x, 0.05, o.z - 0.012),
		Vector3(wall + r, RoomShell.BASEBOARD.x + 0.01, o.z - 0.004),
		Vector3(LEFT + r + 0.001, RoomShell.BASEBOARD.x + 0.04, o.z),
		Vector3(o.x + 0.004, o.y - 0.04, o.z),
	]), r, 6, 3)


## En el alféizar: una suculenta en una lata, una maceta impresa con un
## cactus, el barquito de prueba naranja y una alcancía de monedas.
static func _sill(kit: KitMesh) -> void:
	var y: float = SILL_TOP
	var can: Vector3 = Vector3(SILL_X, y, -1.68)
	kit.paint(LookPalette.TIN_CAN, WorldPalette.Surface.METAL, 0.6)
	kit.cylinder(0.034, 0.07, can + Vector3(0.0, 0.035, 0.0), Vector3.ZERO, 12)
	for i: int in 6:
		var a: float = i * TAU / 6.0
		kit.paint(LookPalette.PLANTS[i % 3] if i < 5 else LookPalette.PLANT_SPROUT, WorldPalette.Surface.SMOOTH, 0.4)
		kit.blob(Vector3(0.014, 0.03, 0.014), can + Vector3(cos(a) * 0.016, 0.085, sin(a) * 0.016), Vector3(rad_to_deg(sin(a)) * 0.5, 0.0, -rad_to_deg(cos(a)) * 0.5), 1.0, 1.0, Vector2(1.0, 0.5), Vector2i(6, 4))
	var pot: Vector3 = Vector3(SILL_X, y, -1.52)
	kit.printed(LookPalette.FILAMENT_WHITE, 0.004)
	kit.cylinder(0.032, 0.055, pot + Vector3(0.0, 0.0275, 0.0), Vector3.ZERO, 10, 0.0, 0.04)
	kit.paint(LookPalette.PLANTS[0], WorldPalette.Surface.SMOOTH, 0.3)
	kit.capsule(0.02, 0.016, 0.08, pot + Vector3(0.0, 0.05, 0.0), Vector3.ZERO, 1.0, Vector2i(8, 6))
	benchy(kit, Transform3D(Basis(Vector3.UP, deg_to_rad(70.0)), Vector3(SILL_X, y, -0.82)), LookPalette.FILAMENT_ORANGE)
	var jar: Vector3 = Vector3(SILL_X, y, -0.69)
	kit.paint(LookPalette.PILLOW, WorldPalette.Surface.SMOOTH, 0.9)
	kit.cylinder(0.03, 0.07, jar + Vector3(0.0, 0.035, 0.0), Vector3.ZERO, 12)
	kit.paint(LookPalette.METAL_BRASS, WorldPalette.Surface.METAL, 0.7)
	kit.cylinder(0.031, 0.01, jar + Vector3(0.0, 0.075, 0.0), Vector3.ZERO, 12)
	for k: int in 3:
		kit.cylinder(0.012, 0.004, jar + Vector3(0.0, 0.002 + k * 0.004, 0.05), Vector3.ZERO, 8)


## El barquito de prueba (homenaje al primer modelo que se imprime, sin
## marca): casco, cabina, techo y chimenea, con sus capas. `at`: su base, la
## proa hacia +X.
static func benchy(kit: KitMesh, at: Transform3D, hex: String) -> void:
	kit.origin = at
	kit.printed(hex, 0.003)
	kit.blob(Vector3(0.045, 0.02, 0.026), Vector3(0.0, 0.02, 0.0), Vector3.ZERO, 0.55, 0.7, Vector2(1.0, 1.15), Vector2i(12, 5))
	kit.box(Vector3(0.038, 0.03, 0.032), Vector3(-0.008, 0.05, 0.0), 0.0)
	kit.box(Vector3(0.044, 0.006, 0.038), Vector3(-0.008, 0.068, 0.0), 0.0)
	kit.cylinder(0.007, 0.022, Vector3(0.01, 0.075, 0.0), Vector3.ZERO, 8)
	kit.origin = Transform3D.IDENTITY


# --- Lo que cambia con el nivel --------------------------------------------------

## Las primeras impresiones en la repisa: al empezar, el barquito y el cubo
## de calibración; con el nivel, también el gatito que brilla en la
## oscuridad, un dragón articulado y un jarrón en espiral.
static func _first_prints(kit: KitMesh, tier: int) -> void:
	var shelf: Transform3D = _shelf_frame()
	benchy(kit, shelf * Transform3D(Basis(Vector3.UP, deg_to_rad(-20.0)), Vector3(-0.3, 0.0, 0.07)), LookPalette.FILAMENT_YELLOW)
	kit.origin = shelf
	kit.printed(LookPalette.FILAMENT_GREY, 0.004)
	kit.box(Vector3(0.04, 0.04, 0.04), Vector3(-0.13, 0.02, 0.07), 0.0, Vector3(0.0, 15.0, 0.0))
	kit.paint(LookPalette.FILAMENT_GREY, WorldPalette.Surface.SMOOTH, 0.3)
	kit.box(Vector3(0.012, 0.012, 0.003), Vector3(-0.124, 0.02, 0.092), 0.0, Vector3(0.0, 15.0, 0.0))
	kit.box(Vector3(0.012, 0.003, 0.012), Vector3(-0.13, 0.0415, 0.07), 0.0, Vector3(0.0, 15.0, 0.0))
	if tier >= FULL_SHELF_TIER:
		var cat: Vector3 = Vector3(0.02, 0.0, 0.07)
		kit.night_glow(LookPalette.FILAMENT_WHITE, 0.9)
		kit.layer = 0.003
		kit.blob(Vector3(0.026, 0.03, 0.022), cat + Vector3(0.0, 0.03, 0.0), Vector3.ZERO, 0.9, 0.9, Vector2(1.0, 0.85), Vector2i(10, 6))
		kit.blob(Vector3(0.022, 0.02, 0.02), cat + Vector3(0.0, 0.072, 0.004), Vector3.ZERO, 0.9, 0.9, Vector2.ONE, Vector2i(10, 6))
		for side: float in KitMesh.SIGNS:
			kit.box(Vector3(0.01, 0.016, 0.008), cat + Vector3(side * 0.012, 0.094, 0.004), 0.0, Vector3(0.0, 0.0, -18.0 * side))
		kit.origin = Transform3D.IDENTITY
		DecorItems.dragon(kit, shelf * Vector3(0.2, 0.0, 0.07), 0.0, LookPalette.FILAMENT_BLUE, 0.018)
		kit.origin = shelf
		kit.printed(LookPalette.FILAMENT_PURPLE, 0.003, 0.45)
		var vase: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.024, 0.0), Vector2(0.036, 0.05), Vector2(0.026, 0.11), Vector2(0.033, 0.14), Vector2(0.028, 0.14), Vector2(0.021, 0.11), Vector2(0.02, 0.02), Vector2(0.0, 0.02)])
		kit.lathe(vase, Vector3(0.36, 0.0, 0.07), Vector3.ZERO, 12)
	kit.origin = Transform3D.IDENTITY


## Notas y fotos del corcho: dos al empezar, más con el nivel.
static func _cork_notes(kit: KitMesh, tier: int) -> void:
	kit.origin = _on_left(CORK_CENTER)
	var notes: Array[Array] = [
		[Vector2(-0.12, 0.1), LookPalette.FILAMENT_YELLOW, 6.0],
		[Vector2(0.1, -0.08), LookPalette.PILLOW, -5.0],
	]
	if tier >= FULL_SHELF_TIER:
		notes.append_array([
			[Vector2(0.0, 0.12), LookPalette.RUG_PATTERN[3], -3.0],
			[Vector2(-0.14, -0.1), LookPalette.SHEET, 4.0],
			[Vector2(0.14, 0.13), LookPalette.PLANT_SPROUT, 8.0],
		])
	for note: Array in notes:
		var at: Vector2 = note[0]
		_flat(kit, note[1], Vector2(0.08, 0.08), at, 0.022, note[2])
		kit.paint(LookPalette.FILAMENT_RED, WorldPalette.Surface.SMOOTH, 0.5)
		kit.box(Vector3(0.01, 0.01, 0.008), Vector3(at.x, at.y + 0.03, 0.026), 0.0)
	if tier >= FULL_SHELF_TIER:
		var photos: Array[Array] = [
			[Vector2(-0.04, -0.03), LookPalette.PLANTS[1], LookPalette.PILLOW, -4.0],
			[Vector2(0.06, 0.03), LookPalette.POSTER_SUNSET[1], LookPalette.POSTER_SUNSET[0], 5.0],
			[Vector2(-0.02, -0.15), LookPalette.RUG_PATTERN[2], LookPalette.PRINTER_WHITE, 2.0],
		]
		for photo: Array in photos:
			var at: Vector2 = photo[0]
			_flat(kit, LookPalette.SHEET, Vector2(0.1, 0.08), at, 0.0222, photo[3])
			_flat(kit, photo[2], Vector2(0.086, 0.034), at + Vector2(0.0, 0.012), 0.0225, photo[3])
			_flat(kit, photo[1], Vector2(0.086, 0.03), at + Vector2(0.0, -0.02), 0.0225, photo[3])
	kit.origin = Transform3D.IDENTITY


## Billete enmarcado de la primera venta: un rectángulo verde, sin texto.
static func _bill(kit: KitMesh) -> void:
	kit.origin = _on_back(BILL_CENTER)
	_frame(kit, Vector2(0.24, 0.15), LookPalette.WOOD_LIGHT)
	_flat(kit, LookPalette.SHEET, Vector2(0.2, 0.11), Vector2.ZERO, 0.0205)
	_flat(kit, LookPalette.PLANTS[0], Vector2(0.16, 0.075), Vector2.ZERO, 0.021)
	kit.paint(LookPalette.PLANTS[1], WorldPalette.Surface.SMOOTH, 0.1)
	kit.disc(0.02, Vector3(0.0, 0.0, 0.0215), Vector3.ZERO, 10)
	kit.origin = Transform3D.IDENTITY


## Placa enmarcada del taller (nivel 5+): madera con una placa de latón y
## una impresora dibujada.
static func _plaque(kit: KitMesh) -> void:
	kit.origin = _on_back(PLAQUE_CENTER)
	_frame(kit, Vector2(0.26, 0.2), LookPalette.WOOD_MID)
	kit.paint(LookPalette.METAL_BRASS, WorldPalette.Surface.METAL, 0.6)
	kit.quad(Vector2(0.18, 0.12), Vector3(0.0, 0.0, 0.0205))
	_flat(kit, LookPalette.RUG_PATTERN[2], Vector2(0.07, 0.006), Vector2(0.0, 0.03), 0.021)
	for x: float in [-0.03, 0.03]:
		_flat(kit, LookPalette.RUG_PATTERN[2], Vector2(0.006, 0.06), Vector2(x, 0.0), 0.021)
	_flat(kit, LookPalette.RUG_PATTERN[2], Vector2(0.05, 0.006), Vector2(0.0, -0.02), 0.021)
	kit.origin = Transform3D.IDENTITY


## Tira LED del taller (nivel 5+) arriba de la pared del fondo: el perfil de
## aluminio y el difusor, que de noche brilla (DayCycle la enciende).
static func _led_strip(kit: KitMesh) -> void:
	var from: Vector3 = DayCycle.LED_STRIP_FROM
	var to: Vector3 = DayCycle.LED_STRIP_TO
	var length: float = to.x - from.x
	var x: float = (from.x + to.x) / 2.0
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.5)
	kit.box(Vector3(length + 0.02, 0.016, 0.012), Vector3(x, LED_STRIP_Y, BACK + 0.006), 0.0)
	kit.night_glow(LookPalette.BED_LED, 1.6)
	kit.box(Vector3(length, 0.008, 0.003), Vector3(x, LED_STRIP_Y - 0.002, BACK + 0.0135), 0.0)

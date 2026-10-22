class_name CharacterModel
extends RefCounted
## El protagonista (biblia de arte §7): un joven maker de 1,40 m y unas 3,2
## cabezas, lindo pero no infantil. Pelo café en mechones grandes y flequillo
## de lado, buzo gris carbón con la capucha enrollada (forro mostaza),
## cordones, bolsillo canguro y el logo de tres capas cian, jeans con la basta
## doblada y zapatillas blancas gorditas con franja cian. Mira hacia +Z.
##
## Contrato (lo mueven CharacterController y el animador, lo leen las
## pruebas): los pivotes Node3D "HipL"/"HipR" (con "KneeL"/"KneeR"), "Body",
## "Body/ShoulderL"/"ShoulderR" (con "ElbowL"/"ElbowR") y "Body/Head", y el
## Marker3D "Body/Head/SpeechAnchor" donde se ancla el globo de diálogo.
##
## Se dibuja con 6 llamadas: el cuerpo es UNA malla con piel ("Rig/Mesh",
## CharacterRig copia la pose de los pivotes a sus huesos), la cabeza otra
## malla rígida con la cara pintada y el pelo ("Body/Head/Mesh"), cada una
## con su sombra, y un contorno fino por malla que no da sombra ("Outline").
## Las mallas y la piel se arman una vez y las comparten el cuarto, los
## retratos y las pruebas.

enum Bone { BODY, HIP_L, KNEE_L, HIP_R, KNEE_R, SHOULDER_L, ELBOW_L, SHOULDER_R, ELBOW_R, HEAD }

## Ruta de cada pivote (en el orden de Bone).
const PIVOT_PATHS: Array[String] = [
	"Body", "HipL", "HipL/KneeL", "HipR", "HipR/KneeR",
	"Body/ShoulderL", "Body/ShoulderL/ElbowL", "Body/ShoulderR", "Body/ShoulderR/ElbowR", "Body/Head",
]

## Proporciones (biblia §7.1). Alto total hasta la punta del pelo.
const HEIGHT: float = 1.40
## Caderas (pivotes) y rodillas.
const HIP_HEIGHT: float = 0.50
const HIP_X: float = 0.08
const KNEE_DROP: float = 0.23
## Hombros desde el pivote Body (en y 0,90 del modelo), su giro hacia afuera
## en reposo y el eje del brazo, un poco por fuera de la articulación (así
## cuelga sin rozar el buzo). El codo, bajando por ese eje.
const SHOULDER: Vector2 = Vector2(0.17, 0.40)
const SHOULDER_ROLL: float = 0.06
const ARM_OFFSET: float = 0.05
const ELBOW_DROP: float = 0.20
## Pivote de la cabeza (el cuello) desde Body, y el mentón levantado 6° en
## reposo: la cámara alta ve la cara.
const NECK_Y: float = 0.43
const CHIN_UP: float = -0.10
## Cráneo en el espacio de la cabeza: centro (en y 1,15 del modelo) y medias
## medidas. El eje de la cara pasa por su centro, a la altura de los ojos.
const SKULL_CENTER: Vector3 = Vector3(0.0, 0.22, 0.005)
const SKULL_HALF: Vector3 = Vector3(0.18, 0.19, 0.17)
const EYE_DROP: float = 0.03
const FACE_AXIS: Vector3 = SKULL_CENTER - Vector3(0.0, EYE_DROP, 0.0)
## Casquete del pelo (un poco más grande que el cráneo, corrido hacia atrás).
const HAIR_CENTER: Vector3 = SKULL_CENTER + Vector3(0.0, 0.02, -0.012)
const HAIR_RADII: Vector3 = Vector3(0.198, 0.208, 0.19)
## Globo de diálogo: sobre el pelo.
const SPEECH_ANCHOR_Y: float = 0.48
## Detalle (biblia §5.1): cuerpo 0,8; cabeza y pelo 1,1.
const BODY_DETAIL: float = 0.8
const HEAD_DETAIL: float = 1.1
## Brillo de la piel, de las zapatillas y de lo plástico.
const SKIN_GLOSS: float = 0.12
const SHOE_GLOSS: float = 0.3
## Margen para que la malla con piel no se recorte al moverse (su caja es la
## de reposo).
const CULL_MARGIN: float = 0.3
## Pierna de jeans y brazo de buzo: perfiles (radio, alto) de un tubo
## cerrado arriba y abierto abajo (esa punta queda adentro de la zapatilla y
## del puño), con más anillos en la rodilla y el codo, donde se doblan. El
## brazo, en el marco del hombro (cuelga hacia −Y).
const LEG_PROFILE: PackedVector2Array = [
	Vector2(0.052, 0.09), Vector2(0.054, 0.15), Vector2(0.056, 0.21), Vector2(0.0575, 0.245), Vector2(0.058, 0.27),
	Vector2(0.059, 0.295), Vector2(0.061, 0.33), Vector2(0.063, 0.39), Vector2(0.065, 0.45), Vector2(0.066, 0.51),
	Vector2(0.064, 0.55), Vector2(0.0, 0.565),
]
const ARM_PROFILE: PackedVector2Array = [
	Vector2(0.046, -0.375), Vector2(0.047, -0.33), Vector2(0.049, -0.28), Vector2(0.05, -0.235), Vector2(0.0505, -0.21),
	Vector2(0.051, -0.19), Vector2(0.052, -0.165), Vector2(0.053, -0.12), Vector2(0.054, -0.07), Vector2(0.05, -0.035),
	Vector2(0.0, -0.01),
]
const LIMB_SIDES: int = 12

static var _skin: Skin


static func build(parent: Node3D, node_name: String) -> Node3D:
	var root: Node3D = PropBuilder.group(parent, node_name)
	var pivots: Array[Node3D] = []
	for bone: int in Bone.size():
		var path: String = PIVOT_PATHS[bone]
		var holder: Node3D = root if path.get_base_dir().is_empty() else root.get_node(path.get_base_dir())
		var pivot: Node3D = PropBuilder.group(holder, path.get_file())
		pivot.transform = local_rest(bone as Bone)
		pivots.append(pivot)
	var head: Node3D = pivots[Bone.HEAD]
	var anchor: Marker3D = Marker3D.new()
	anchor.name = "SpeechAnchor"
	anchor.position = Vector3(0.0, SPEECH_ANCHOR_Y, 0.0)
	head.add_child(anchor)

	var rig: CharacterRig = CharacterRig.create(pivots)
	root.add_child(rig)
	var body: ArrayMesh = KitMesh.cached("character:body", _body_mesh)
	for material: ShaderMaterial in [WorldPalette.kit_character(), WorldPalette.outline_character()]:
		var mesh_instance: MeshInstance3D = _instance(rig, body, material)
		mesh_instance.skeleton = NodePath("..")
		mesh_instance.skin = skin()
		mesh_instance.extra_cull_margin = CULL_MARGIN
	var head_mesh: ArrayMesh = KitMesh.cached("character:head", _head_mesh)
	for material: ShaderMaterial in [WorldPalette.kit_head(), WorldPalette.outline_character()]:
		_instance(head, head_mesh, material)
	rig.follow()
	return root


## Cambia la cara de un personaje ya armado (FacePainter.Face).
static func set_expression(character: Node3D, expression: FacePainter.Face) -> void:
	(character.get_node("Body/Head/Mesh") as GeometryInstance3D).set_instance_shader_parameter(&"expression", expression)


## Reposo de cada pivote respecto de su padre.
static func local_rest(bone: Bone) -> Transform3D:
	var side: float = -1.0 if bone in [Bone.HIP_L, Bone.KNEE_L, Bone.SHOULDER_L, Bone.ELBOW_L] else 1.0
	match bone:
		Bone.BODY:
			return Transform3D(Basis.IDENTITY, Vector3(0.0, HIP_HEIGHT, 0.0))
		Bone.HIP_L, Bone.HIP_R:
			return Transform3D(Basis.IDENTITY, Vector3(HIP_X * side, HIP_HEIGHT, 0.0))
		Bone.KNEE_L, Bone.KNEE_R:
			return Transform3D(Basis.IDENTITY, Vector3(0.0, -KNEE_DROP, 0.0))
		Bone.SHOULDER_L, Bone.SHOULDER_R:
			return Transform3D(Basis(Vector3.BACK, SHOULDER_ROLL * side), Vector3(SHOULDER.x * side, SHOULDER.y, 0.0))
		Bone.ELBOW_L, Bone.ELBOW_R:
			return Transform3D(Basis.IDENTITY, Vector3(ARM_OFFSET * side, -ELBOW_DROP, 0.0))
	return Transform3D(Basis(Vector3.RIGHT, CHIN_UP), Vector3(0.0, NECK_Y, 0.0))


## Reposo de cada hueso en el espacio del modelo.
static func model_rest(bone: Bone) -> Transform3D:
	var parent: String = PIVOT_PATHS[bone].get_base_dir()
	var local: Transform3D = local_rest(bone)
	if parent.is_empty():
		return local
	return model_rest(PIVOT_PATHS.find(parent) as Bone) * local


## La piel del cuerpo (una para todos los personajes).
static func skin() -> Skin:
	if _skin == null:
		var rests: Array[Transform3D] = []
		for bone: int in Bone.size():
			rests.append(model_rest(bone as Bone))
		_skin = CharacterRig.skin_for(rests)
	return _skin


## La malla con su material ("Mesh"), o su contorno ("Outline"), que no da
## sombra: así el contorno no entra a la pasada de sombra.
static func _instance(parent: Node3D, mesh: ArrayMesh, material: ShaderMaterial) -> MeshInstance3D:
	var outline: bool = material == WorldPalette.outline_character()
	var mesh_instance: MeshInstance3D = PropBuilder.kit(parent, "Outline" if outline else "Mesh", mesh, material)
	if outline:
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh_instance


# --- El cuerpo (una malla con piel) ---------------------------------------------

static func _body_mesh() -> ArrayMesh:
	var parts: Array[CharacterRig.Part] = []
	for side: float in [-1.0, 1.0]:
		var left: bool = side < 0.0
		var hip: Bone = Bone.HIP_L if left else Bone.HIP_R
		var knee: Bone = Bone.KNEE_L if left else Bone.KNEE_R
		parts.append(CharacterRig.Part.new(_leg(side), PackedInt32Array([Bone.BODY, hip, knee]), PackedFloat32Array([0.0, KNEE_DROP]), model_rest(hip)))
		var shoulder: Bone = Bone.SHOULDER_L if left else Bone.SHOULDER_R
		var elbow: Bone = Bone.ELBOW_L if left else Bone.ELBOW_R
		parts.append(CharacterRig.Part.new(_arm(side), PackedInt32Array([Bone.BODY, shoulder, elbow]), PackedFloat32Array([0.0, ELBOW_DROP]), model_rest(shoulder)))
	parts.append(CharacterRig.Part.new(_torso(), PackedInt32Array([Bone.BODY])))
	parts.append(CharacterRig.Part.new(_neck(), PackedInt32Array([Bone.BODY, Bone.HEAD]), PackedFloat32Array([0.0]), model_rest(Bone.HEAD), Vector3.UP))
	return CharacterRig.skinned_mesh(parts)


static func _kit() -> KitMesh:
	var kit: KitMesh = KitMesh.new()
	kit.detail = BODY_DETAIL
	return kit


## Pierna de jeans en un solo tubo (se dobla en la rodilla), la basta
## doblada y la zapatilla: suela gruesa, capellada redondeada, puntera,
## lengüeta y la franja cian por fuera.
static func _leg(side: float) -> KitMesh:
	var kit: KitMesh = _kit()
	var x: float = HIP_X * side
	kit.paint(LookPalette.JEANS, WorldPalette.Surface.SMOOTH, 0.05)
	kit.lathe(LEG_PROFILE, Vector3(x, 0.0, 0.0), Vector3.ZERO, LIMB_SIDES)
	kit.paint(LookPalette.JEANS_CUFF, WorldPalette.Surface.SMOOTH, 0.05)
	kit.torus(Vector2(0.058, 0.056), 0.017, Vector3(x, 0.113, 0.0), Vector3.ZERO, TAU, Vector2i(12, 5))
	kit.paint(LookPalette.SHOE_SOLE, WorldPalette.Surface.SMOOTH, 0.15)
	kit.blob(Vector3(0.058, 0.0125, 0.105), Vector3(x, 0.0125, 0.028), Vector3.ZERO, 0.45, 0.5, Vector2.ONE, Vector2i(12, 5))
	kit.paint(LookPalette.SHOES, WorldPalette.Surface.SMOOTH, SHOE_GLOSS)
	kit.blob(Vector3(0.054, 0.046, 0.098), Vector3(x, 0.05, 0.026), Vector3.ZERO, 0.62, 0.72, Vector2(1.0, 0.8), Vector2i(14, 8))
	kit.blob(Vector3(0.03, 0.012, 0.036), Vector3(x, 0.092, 0.05), Vector3(28.0, 0.0, 0.0), 0.7, 0.8, Vector2.ONE, Vector2i(8, 4))
	kit.paint(LookPalette.SHOE_STRIPE, WorldPalette.Surface.SMOOTH, SHOE_GLOSS)
	kit.blob(Vector3(0.006, 0.014, 0.052), Vector3(x + 0.051 * side, 0.05, 0.016), Vector3.ZERO, 0.7, 0.7, Vector2.ONE, Vector2i(8, 4))
	return kit


## Brazo de buzo en un solo tubo desde el hombro (se dobla en el codo), puño
## acanalado y mano de mitón con pulgar. Se arma en el marco del hombro: el
## brazo cuelga hacia −Y.
static func _arm(side: float) -> KitMesh:
	var kit: KitMesh = _kit()
	kit.origin = model_rest(Bone.SHOULDER_L if side < 0.0 else Bone.SHOULDER_R)
	var x: float = ARM_OFFSET * side
	kit.paint(LookPalette.HOODIE, WorldPalette.Surface.SMOOTH, 0.08)
	kit.blob(Vector3(0.054, 0.058, 0.054), Vector3(x * 0.7, -0.07, 0.0), Vector3.ZERO, 1.0, 1.0, Vector2.ONE, Vector2i(10, 7))
	kit.lathe(ARM_PROFILE, Vector3(x, 0.0, 0.0), Vector3.ZERO, LIMB_SIDES)
	kit.paint(LookPalette.HOODIE_CUFF, WorldPalette.Surface.SMOOTH, 0.05)
	kit.torus(Vector2(0.046, 0.046), 0.016, Vector3(x, -0.365, 0.0), Vector3.ZERO, TAU, Vector2i(10, 5))
	kit.paint(LookPalette.SKIN, WorldPalette.Surface.SKIN, SKIN_GLOSS)
	kit.blob(Vector3(0.038, 0.05, 0.032), Vector3(x, -0.425, 0.006), Vector3.ZERO, 0.8, 0.9, Vector2.ONE, Vector2i(10, 8))
	kit.blob(Vector3(0.014, 0.026, 0.014), Vector3(x - 0.026 * side, -0.405, 0.026), Vector3(0.0, 0.0, -28.0 * side), 1.0, 1.0, Vector2.ONE, Vector2i(8, 5))
	return kit


## Cadera de jeans y el buzo: cuerpo más ancho abajo, borde acanalado,
## bolsillo canguro, logo de tres capas, capucha enrollada con el forro
## mostaza y su bulto atrás, y los cordones con puntas mostaza.
static func _torso() -> KitMesh:
	var kit: KitMesh = _kit()
	kit.paint(LookPalette.JEANS, WorldPalette.Surface.SMOOTH, 0.05)
	kit.blob(Vector3(0.148, 0.075, 0.102), Vector3(0.0, 0.515, 0.0), Vector3.ZERO, 0.6, 0.8, Vector2.ONE, Vector2i(12, 6))
	kit.paint(LookPalette.HOODIE, WorldPalette.Surface.SMOOTH, 0.08)
	kit.blob(Vector3(0.17, 0.222, 0.11), Vector3(0.0, 0.69, 0.0), Vector3.ZERO, 0.62, 0.56, Vector2(1.05, 0.95), Vector2i(18, 12))
	kit.blob(Vector3(0.112, 0.058, 0.022), Vector3(0.0, 0.585, 0.098), Vector3.ZERO, 0.4, 0.5, Vector2.ONE, Vector2i(10, 5))
	kit.blob(Vector3(0.135, 0.105, 0.055), Vector3(0.0, 0.86, -0.115), Vector3(14.0, 0.0, 0.0), 0.7, 0.8, Vector2.ONE, Vector2i(12, 8))
	# La capucha enrollada abre adelante (el cuello en V de los cordones).
	kit.torus(Vector2(0.116, 0.104), 0.046, Vector3(0.0, 0.922, -0.008), Vector3(-12.0, 180.0, 0.0), deg_to_rad(300.0), Vector2i(18, 8))
	kit.paint(LookPalette.HOODIE_ACCENT, WorldPalette.Surface.SMOOTH, 0.1)
	kit.torus(Vector2(0.104, 0.092), 0.03, Vector3(0.0, 0.952, -0.01), Vector3(-12.0, 180.0, 0.0), deg_to_rad(290.0), Vector2i(16, 5))
	kit.paint(LookPalette.HOODIE_CUFF, WorldPalette.Surface.SMOOTH, 0.05)
	kit.torus(Vector2(0.168, 0.106), 0.021, Vector3(0.0, 0.48, 0.0), Vector3.ZERO, TAU, Vector2i(18, 5))
	for i: int in LookPalette.LOGO.size():
		kit.paint(LookPalette.LOGO[i], WorldPalette.Surface.SMOOTH, 0.3)
		kit.blob(Vector3(0.024 - i * 0.004, 0.0055, 0.005), Vector3(0.068, 0.80 - i * 0.014, 0.104), Vector3.ZERO, 0.3, 0.6, Vector2.ONE, Vector2i(8, 4))
	for side: float in [-1.0, 1.0]:
		kit.paint(LookPalette.DRAWSTRINGS, WorldPalette.Surface.SMOOTH, 0.2)
		kit.tube(PackedVector3Array([Vector3(0.03 * side, 0.9, 0.098), Vector3(0.034 * side, 0.845, 0.106), Vector3(0.038 * side, 0.785, 0.11)]), 0.0065, 6, 3)
		kit.paint(LookPalette.HOODIE_ACCENT, WorldPalette.Surface.SMOOTH, 0.3)
		kit.blob(Vector3(0.008, 0.013, 0.008), Vector3(0.038 * side, 0.775, 0.11), Vector3.ZERO, 1.0, 1.0, Vector2.ONE, Vector2i(6, 4))
	return kit


## Cuello: abajo va con el cuerpo y arriba con la cabeza.
static func _neck() -> KitMesh:
	var kit: KitMesh = _kit()
	kit.paint(LookPalette.SKIN, WorldPalette.Surface.SKIN, SKIN_GLOSS)
	kit.capsule(0.05, 0.048, 0.15, Vector3(0.0, 0.86, 0.0), Vector3.ZERO, 0.95, Vector2i(10, 6))
	return kit


# --- La cabeza (rígida, en el espacio del pivote Body/Head) --------------------

## Cráneo con la piel donde se pinta la cara (superficie SKIN), orejas y el
## pelo (HairKit, superficie HAIR: no recibe la cara).
static func _head_mesh() -> ArrayMesh:
	var kit: KitMesh = KitMesh.new()
	kit.detail = HEAD_DETAIL
	# Lo que está a la altura del cuello no toca el piso.
	kit.ao_enabled = false
	kit.paint(LookPalette.SKIN, WorldPalette.Surface.SKIN, SKIN_GLOSS)
	kit.blob(SKULL_HALF, SKULL_CENTER, Vector3.ZERO, 1.0, 1.0, Vector2(0.88, 1.0), Vector2i(24, 16))
	kit.paint(LookPalette.SKIN_SHADE, WorldPalette.Surface.SKIN, SKIN_GLOSS)
	for side: float in [-1.0, 1.0]:
		kit.blob(Vector3(0.014, 0.03, 0.021), SKULL_CENTER + Vector3(0.166 * side, -0.025, -0.012), Vector3.ZERO, 1.0, 1.0, Vector2.ONE, Vector2i(7, 5))
	HairKit.add_to(kit, HAIR_CENTER, HAIR_RADII)
	return kit.commit()

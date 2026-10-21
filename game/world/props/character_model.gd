class_name CharacterModel
extends RefCounted
## El protagonista, estilo chibi: cabeza grande, pelo café alborotado,
## buzo negro con capucha, jeans y zapatillas blancas. Mira hacia +Z y mide
## unos 1,25 m. Devuelve el nodo raíz; la cabeza y el cuerpo quedan en los
## hijos "Body" y "Body/Head" para poder animarlos.


static func build(parent: Node3D, node_name: String) -> Node3D:
	var character: Node3D = PropBuilder.group(parent, node_name)
	var skin: StandardMaterial3D = WorldPalette.solid(WorldPalette.SKIN)
	var hoodie: StandardMaterial3D = WorldPalette.solid(WorldPalette.HOODIE)
	var jeans: StandardMaterial3D = WorldPalette.solid(WorldPalette.JEANS)
	var shoes: StandardMaterial3D = WorldPalette.solid(WorldPalette.SHOES)
	for side: float in [-1.0, 1.0]:
		var suffix: String = "L" if side < 0.0 else "R"
		PropBuilder.box(character, "Shoe" + suffix, Vector3(0.12, 0.06, 0.18), Vector3(0.07 * side, 0.03, 0.02), shoes)
		PropBuilder.box(character, "Leg" + suffix, Vector3(0.11, 0.34, 0.13), Vector3(0.07 * side, 0.23, 0.0), jeans)

	var body: Node3D = PropBuilder.group(character, "Body", Vector3(0.0, 0.4, 0.0))
	PropBuilder.box(body, "Torso", Vector3(0.34, 0.38, 0.22), Vector3(0.0, 0.19, 0.0), hoodie)
	PropBuilder.box(body, "Hood", Vector3(0.26, 0.1, 0.08), Vector3(0.0, 0.37, -0.11), hoodie)
	PropBuilder.box(body, "Pocket", Vector3(0.2, 0.08, 0.01), Vector3(0.0, 0.08, 0.11), WorldPalette.solid("2f313b"))
	for side: float in [-1.0, 1.0]:
		var suffix: String = "L" if side < 0.0 else "R"
		PropBuilder.box(body, "String" + suffix, Vector3(0.015, 0.08, 0.01), Vector3(0.045 * side, 0.3, 0.115), shoes)
		PropBuilder.box(body, "Arm" + suffix, Vector3(0.09, 0.32, 0.11), Vector3(0.215 * side, 0.2, 0.0), hoodie)
		PropBuilder.sphere(body, "Hand" + suffix, 0.05, Vector3(0.215 * side, 0.02, 0.01), skin)

	var head: Node3D = PropBuilder.group(body, "Head", Vector3(0.0, 0.6, 0.0))
	PropBuilder.sphere(head, "Face", 0.21, Vector3.ZERO, skin)
	var hair: StandardMaterial3D = WorldPalette.solid(WorldPalette.HAIR)
	var hair_light: StandardMaterial3D = WorldPalette.solid(WorldPalette.HAIR_LIGHT)
	PropBuilder.sphere(head, "HairCap", 0.215, Vector3(0.0, 0.05, -0.04), hair)
	var spikes: Array[Vector3] = [
		Vector3(-0.12, 0.16, 0.12), Vector3(0.0, 0.19, 0.13), Vector3(0.12, 0.15, 0.11),
		Vector3(-0.17, 0.08, 0.06), Vector3(0.17, 0.08, 0.05), Vector3(0.05, 0.22, 0.0),
		Vector3(-0.08, 0.21, -0.08),
	]
	for i: int in spikes.size():
		var spike: MeshInstance3D = PropBuilder.box(head, "Spike%d" % i, Vector3(0.09, 0.09, 0.09), spikes[i], hair if i % 2 == 0 else hair_light)
		spike.rotation_degrees = Vector3(35.0 + i * 7.0, 45.0 + i * 20.0, 15.0)
	var eyes: StandardMaterial3D = WorldPalette.solid(WorldPalette.EYES)
	for side: float in [-1.0, 1.0]:
		PropBuilder.box(head, "Eye" + ("L" if side < 0.0 else "R"), Vector3(0.035, 0.06, 0.02), Vector3(0.075 * side, -0.01, 0.195), eyes)
	return character

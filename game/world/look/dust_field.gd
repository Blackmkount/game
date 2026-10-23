class_name DustField
extends MultiMeshInstance3D
## Motas de polvo en el haz de la ventana, de día (biblia de arte §8.9): UN
## MultiMesh de COUNT cuadritos (una llamada de dibujo). Dónde está cada mota
## dentro del haz y su fase salen de una semilla (motes(), puro): con la
## misma semilla el polvo es el mismo. Las mueve el sombreador
## (dust.gdshader) con cc_anim_time y la luz de la ventana de cada hora; aquí
## no se mueve nada por cuadro.
##
## DayCycle le pone la fuerza de la hora (set_strength); en 0 (de noche) el
## nodo se esconde y no cuesta nada.

const SHADER: Shader = preload("res://game/world/look/dust.gdshader")
const COUNT: int = 40
## Lo que el motor tiene que saber que ocupa (el sombreador mueve las motas
## por todo el cuarto): la caja del cuarto.
const BOUNDS: AABB = AABB(Vector3(-3.2, 0.0, -3.2), Vector3(6.4, 2.8, 6.4))


func _init(seed_value: int) -> void:
	name = "Dust"
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	custom_aabb = BOUNDS
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = quad
	multimesh.instance_count = COUNT
	var data: PackedColorArray = motes(seed_value)
	for i: int in COUNT:
		multimesh.set_instance_transform(i, Transform3D.IDENTITY)
		multimesh.set_instance_custom_data(i, data[i])
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	material_override = material
	visible = false


## Cada mota, con la semilla `seed_value`: (u, v) en el hueco de la ventana,
## t a lo largo de la luz (0 en la ventana, 1 cerca del piso) y su fase, todo
## entre 0 y 1.
static func motes(seed_value: int, count: int = COUNT) -> PackedColorArray:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var data: PackedColorArray = PackedColorArray()
	for i: int in count:
		data.append(Color(rng.randf_range(0.06, 0.94), rng.randf_range(0.05, 0.95), rng.randf(), rng.randf()))
	return data


## Cuánto brilla el polvo con la luz de esta hora (0 = se esconde).
func set_strength(strength: float) -> void:
	(material_override as ShaderMaterial).set_shader_parameter(&"strength", strength)
	visible = strength > 0.0

class_name ReadySparkles
extends MultiMeshInstance3D
## Destellos de "pieza lista" (biblia de arte §9.5): tres estrellitas de luz
## que se suman alrededor de la pieza recién terminada, una tras otra, y se
## apagan en DURATION segundos. Un MultiMesh: una sola llamada de dibujo para
## las tres, y escondido el resto del tiempo (no cuesta nada).
##
## Cada estrellita son dos rectángulos cruzados con un halo estirado
## (halo.gdshader): un brillo de cuatro puntas. Miran a la cámara, que nunca
## gira: se orientan una vez, al empezar.

const COUNT: int = 3
const DURATION: float = 0.6
## Lo que dura cada una (empiezan escalonadas dentro de DURATION).
const EACH: float = 0.36
## Largo y ancho de cada brazo de la estrella (m) y cuánto brilla (suma a lo
## que hay detrás: sobre el piso claro hace falta más de 1).
const ARM_LENGTH: float = 0.2
const ARM_WIDTH: float = 0.045
const INTENSITY: float = 2.2
## Dónde aparece cada una respecto del centro de arriba de la pieza (m):
## encima y a los lados, para que no se hundan en la pieza.
const OFFSETS: Array[Vector3] = [Vector3(-0.08, 0.07, 0.05), Vector3(0.075, 0.1, -0.02), Vector3(-0.01, 0.15, 0.06)]
## Escala mínima (una transformación de escala 0 no se puede invertir).
const MIN_SCALE: float = 0.001

## Hacia dónde miran (la cámara, en el espacio del padre).
var _facing: Basis = Basis.IDENTITY
var _tween: Tween


func _init() -> void:
	name = "Sparkles"
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = star_mesh()
	multimesh.instance_count = COUNT
	material_override = WorldPalette.halo(LookPalette.READY_SPARKLE, 1.0, INTENSITY)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false
	_set_time(0.0)


## Suelta los destellos con su centro en `top` (espacio del padre).
func play(top: Vector3) -> void:
	position = top
	var camera: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	_facing = Basis.IDENTITY
	if camera != null:
		_facing = get_parent_node_3d().global_basis.inverse() * camera.global_basis
	stop()
	_set_time(0.0)
	visible = true
	_tween = create_tween()
	_tween.tween_method(_set_time, 0.0, DURATION, DURATION)
	_tween.tween_callback(stop)


## Los apaga ya (otra pieza, partida nueva).
func stop() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	visible = false


func is_playing() -> bool:
	return _tween != null


## Cada estrellita crece y se achica (medio seno) en su turno. Sin memoria
## nueva: solo cambia las transformaciones del MultiMesh.
func _set_time(time: float) -> void:
	var stagger: float = (DURATION - EACH) / (COUNT - 1)
	for i: int in COUNT:
		var t: float = clampf((time - i * stagger) / EACH, 0.0, 1.0)
		var size: float = maxf(sin(PI * t), MIN_SCALE)
		multimesh.set_instance_transform(i, Transform3D(_facing.scaled(Vector3.ONE * size), OFFSETS[i]))


## Dos rectángulos cruzados en el plano XY (miran hacia +Z), con UV de 0 a 1
## a lo largo de cada brazo: el halo redondo se estira y hace las puntas.
static func star_mesh() -> ArrayMesh:
	return KitMesh.cached("ready_sparkle", func() -> ArrayMesh:
		var half: Vector2 = Vector2(ARM_LENGTH, ARM_WIDTH) / 2.0
		var positions: PackedVector3Array = PackedVector3Array()
		var uvs: PackedVector2Array = PackedVector2Array()
		var normals: PackedVector3Array = PackedVector3Array()
		var indices: PackedInt32Array = PackedInt32Array()
		for arm: int in 2:
			var first: int = positions.size()
			for corner: Vector2 in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)]:
				var p: Vector2 = corner * half
				positions.append(Vector3(p.x, p.y, 0.0) if arm == 0 else Vector3(p.y, p.x, 0.0))
				uvs.append((corner + Vector2.ONE) / 2.0)
				normals.append(Vector3.BACK)
			indices.append_array(PackedInt32Array([first, first + 2, first + 1, first, first + 3, first + 2]))
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = positions
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh: ArrayMesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return mesh)

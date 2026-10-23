class_name PrintIn
extends RefCounted
## La firma del juego (biblia de arte §12.2): lo que aparece en el cuarto
## (un mueble o una impresora que se compra) se imprime en su lugar, capa a
## capa, de abajo hacia arriba. Mientras dura, las mallas del kit llevan su
## versión "imprimiéndose" (WorldPalette.reveal_of) y un corte que sube
## (reveal_y): debajo, lo impreso con la línea caliente; encima, solo la
## vista previa de las capas que faltan. Lo que no es del kit (pantallas,
## vidrio) aparece cuando el corte llega a su mitad. Al terminar vuelve el
## material de siempre, así el discard no se paga después.
##
## RoomView.sync_models lo pone a lo nuevo y un toque en el mundo lo termina
## al instante (RoomView.finish_print_ins). Lo de las mallas no cambia: las
## zonas de toque (PropBounds) son las mismas durante el efecto.
##
## Lo escondido al empezar (la pieza sin trabajo, la bandeja vacía) se queda
## como está. Avanzar no pide memoria: solo cambia un número por malla.

## Cuánto tarda en imprimirse (s).
const FURNITURE_SECONDS: float = 1.6
const PRINTER_SECONDS: float = 1.2
## El corte empieza un poco bajo la base y termina un poco sobre la punta (m),
## para que al empezar no se vea nada impreso y al final nada en cian.
const START_BELOW: float = 0.01
const END_ABOVE: float = 0.02
const REVEAL_Y: StringName = &"reveal_y"

## Lo que se está imprimiendo.
var node: Node3D

var _meshes: Array[MeshInstance3D] = []
## El material de siempre de cada una de _meshes.
var _normal: Array[Material] = []
## Lo que no es del kit: escondido hasta que el corte llega a su mitad (alto
## en el mundo, mismo índice).
var _waiting: Array[MeshInstance3D] = []
var _waiting_from: PackedFloat32Array = PackedFloat32Array()
## Alto del corte al empezar y al terminar (en el mundo).
var _span: Vector2
var _progress: float = 0.0
var _running: bool = true
var _tween: Tween


## Imprime `target` en `seconds` segundos, después de esperar `delay` (sin
## nada impreso todavía: solo la vista previa). Devuelve el efecto (para
## terminarlo antes).
static func play(target: Node3D, seconds: float, delay: float = 0.0) -> PrintIn:
	var effect: PrintIn = PrintIn.new(target)
	effect._tween = target.create_tween()
	if delay > 0.0:
		effect._tween.tween_interval(delay)
	effect._tween.tween_method(effect.set_progress, 0.0, 1.0, seconds)
	effect._tween.tween_callback(effect.finish)
	return effect


func _init(target: Node3D) -> void:
	node = target
	var box: AABB = target.global_transform * PropBounds.local_aabb(target)
	_span = Vector2(box.position.y - START_BELOW, box.end.y + END_ABOVE)
	for child: Node in target.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = child
		if not mesh.visible or mesh.mesh == null:
			continue
		var reveal: ShaderMaterial = WorldPalette.reveal_of(mesh.material_override)
		if reveal != null:
			_meshes.append(mesh)
			_normal.append(mesh.material_override)
			mesh.material_override = reveal
		else:
			var bounds: AABB = mesh.global_transform * PropBounds.mesh_aabb(mesh.mesh)
			_waiting.append(mesh)
			_waiting_from.append(bounds.get_center().y)
			mesh.visible = false
	set_progress(0.0)


## Cuánto se imprimió (0 a 1).
func progress() -> float:
	return _progress


func is_running() -> bool:
	return _running


## Pone el corte en `value` (0 = nada impreso, 1 = todo).
func set_progress(value: float) -> void:
	if not _running:
		return
	_progress = value
	var cut: float = lerpf(_span.x, _span.y, value)
	for mesh: MeshInstance3D in _meshes:
		mesh.set_instance_shader_parameter(REVEAL_Y, cut)
	for i: int in _waiting.size():
		if cut >= _waiting_from[i]:
			_waiting[i].visible = true


## Deja el efecto quieto en `value` (capturas y pruebas): ya no avanza solo.
func hold(value: float) -> void:
	_stop_tween()
	set_progress(value)


## Termina ya (al final del efecto o con un toque): vuelve todo como era.
## Con lo que se cambió mientras tanto (otro material, otra cosa visible) no
## se mete.
func finish() -> void:
	if not _running:
		return
	_stop_tween()
	_progress = 1.0
	_running = false
	if not is_instance_valid(node):
		return
	for i: int in _meshes.size():
		if _meshes[i].material_override == WorldPalette.reveal_of(_normal[i]):
			_meshes[i].material_override = _normal[i]
	for mesh: MeshInstance3D in _waiting:
		mesh.visible = true


func _stop_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null

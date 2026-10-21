class_name CameraRig
extends Camera3D
## Cámara isométrica del espacio.
##
## - Sigue un punto (el personaje, o el objeto cuyo panel está abierto) y lo
##   deja en la parte visible de la pantalla, entre la barra de arriba y lo
##   que tape abajo (la barra de secciones o un panel).
## - Zoom por escalones con transición suave: "lejos" muestra todo el
##   espacio, "normal" es la vista de siempre y "cerca" es el doble.
## - No se sale del espacio. Con la vista normal el cuarto no cabe entero de
##   lado a lado, así que la cámara sigue al personaje también ahí.
## - Se mueve de píxel en píxel del dibujo a media resolución, para que los
##   bordes del pixel art no tiemblen. Lo que falta para la posición exacta
##   queda en pixel_remainder, y la escena principal corre la imagen esa
##   fracción para que el movimiento siga siendo suave.

const PITCH: float = -30.0
const YAW: float = 45.0
const DISTANCE: float = 20.0
## Lo que ve la cámara en profundidad: el cuarto queda entre unos 14 y 26 m.
## Un rango corto también hace más nítida la sombra del sol, que lo cubre
## entero.
const NEAR: float = 5.0
const FAR: float = 35.0
## Escalones de zoom. 0,68 deja ver todo el cuarto (unos 10 m de ancho).
const ZOOM_STEPS: Array[float] = [0.68, 1.0, 2.0]
const DEFAULT_ZOOM_INDEX: int = 1
## Segundos que tarda en pasar de un escalón de zoom a otro.
const ZOOM_TIME: float = 0.12
## Fracción de la parte visible (desde arriba) donde queda el punto seguido.
## Un poco arriba del centro, para que el pulgar no lo tape.
const ANCHOR: float = 0.45

var tuning: ControlsTuning
## Punto del mundo que la cámara sigue.
var follow_point: Vector3 = Vector3.ZERO
## Velocidad en el piso (x, z) del punto seguido, para adelantarse un poco.
var follow_velocity: Vector2 = Vector2.ZERO
## Píxeles del dibujo (media resolución) tapados arriba y abajo por la interfaz.
var inset_top_px: float = 0.0
var inset_bottom_px: float = 0.0
var zoom_index: int = DEFAULT_ZOOM_INDEX
var zoom: float = 1.0
## Fracción de píxel (del dibujo) que falta para la posición exacta.
var pixel_remainder: Vector2 = Vector2.ZERO

var _base_size: float = 6.8
var _home: Vector3 = Vector3.ZERO
var _target: Vector3 = Vector3.ZERO
var _zoom_goal: float = ZOOM_STEPS[DEFAULT_ZOOM_INDEX]
var _pinch_start_zoom: float = 1.0
var _right: Vector3
var _up: Vector3
var _forward: Vector3
var _extent_min: Vector2
var _extent_max: Vector2


## `room_bounds`: lo que hay que poder ver del espacio. `home`: punto al que
## mira la cámara con zoom 1× y sin nada que seguir.
func configure(room_bounds: AABB, home: Vector3, base_size: float, p_tuning: ControlsTuning = null) -> void:
	tuning = p_tuning if p_tuning != null else ControlsTuning.current
	projection = Camera3D.PROJECTION_ORTHOGONAL
	keep_aspect = Camera3D.KEEP_WIDTH
	near = NEAR
	far = FAR
	rotation_degrees = Vector3(PITCH, YAW, 0.0)
	_right = basis.x
	_up = basis.y
	_forward = -basis.z
	_home = home
	_base_size = base_size
	_extent_min = Vector2(INF, INF)
	_extent_max = Vector2(-INF, -INF)
	for i: int in 8:
		var corner: Vector3 = room_bounds.get_endpoint(i)
		var projected: Vector2 = Vector2(corner.dot(_right), corner.dot(_up))
		_extent_min = _extent_min.min(projected)
		_extent_max = _extent_max.max(projected)
	follow_point = home
	_target = home
	size = _base_size / zoom
	snap_to_goal()


func set_base_size(base_size: float) -> void:
	_base_size = base_size


## Pasa al siguiente escalón: normal → cerca → lejos → normal.
func cycle_zoom() -> void:
	var order: Array[int] = [DEFAULT_ZOOM_INDEX, ZOOM_STEPS.size() - 1, 0]
	set_zoom_index(order[(order.find(zoom_index) + 1) % order.size()])


## Sube (+1) o baja (-1) un escalón de zoom.
func step_zoom(direction: int) -> void:
	set_zoom_index(clampi(zoom_index + direction, 0, ZOOM_STEPS.size() - 1))


func set_zoom_index(index: int) -> void:
	zoom_index = index
	_zoom_goal = ZOOM_STEPS[index]


func begin_pinch() -> void:
	_pinch_start_zoom = zoom


## `ratio`: distancia actual entre los dedos dividida por la inicial.
func update_pinch(ratio: float) -> void:
	zoom = clampf(_pinch_start_zoom * ratio, ZOOM_STEPS[0], ZOOM_STEPS[ZOOM_STEPS.size() - 1])
	_zoom_goal = zoom


## Al soltar, va al escalón más cercano.
func end_pinch() -> void:
	var best: int = 0
	for i: int in ZOOM_STEPS.size():
		if absf(log(ZOOM_STEPS[i]) - log(zoom)) < absf(log(ZOOM_STEPS[best]) - log(zoom)):
			best = i
	set_zoom_index(best)


## Avanza `delta` segundos: zoom, seguimiento y posición final. Lo llama
## RoomView.step() en cada cuadro, después de mover al personaje.
func step(delta: float) -> void:
	if absf(zoom - _zoom_goal) > 0.001:
		zoom = lerpf(zoom, _zoom_goal, 1.0 - exp(-delta / ZOOM_TIME))
	else:
		zoom = _zoom_goal
	size = _base_size / zoom
	var goal: Vector3 = _clamp(_goal())
	_target = _target.lerp(goal, 1.0 - exp(-delta / maxf(tuning.camera_follow_time, 0.001)))
	_target = _clamp(_target)
	_apply()


## Salta directo a la posición pedida, sin transición (al empezar).
func snap_to_goal() -> void:
	zoom = _zoom_goal
	size = _base_size / zoom
	_target = _clamp(_goal())
	_apply()


func _view_size() -> Vector2:
	var view: Vector2 = get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(360.0, 640.0)
	return view if view.x > 0.0 else Vector2(360.0, 640.0)


## Centro de la vista que deja el punto seguido en su lugar de la pantalla.
func _goal() -> Vector3:
	var view: Vector2 = _view_size()
	var meters_per_px: float = size / view.x
	var point: Vector3 = follow_point
	var ahead: float = clampf(zoom - 1.0, 0.0, 1.0) * tuning.camera_look_ahead / maxf(tuning.walk_speed, 0.001)
	point += Vector3(follow_velocity.x, 0.0, follow_velocity.y) * ahead
	var anchor_y: float = lerpf(inset_top_px, view.y - inset_bottom_px, ANCHOR)
	# El punto queda `below` metros por debajo del centro de la pantalla.
	var below: float = (anchor_y - view.y / 2.0) * meters_per_px
	return _compose(point.dot(_right), point.dot(_up) + below)


## Mantiene el espacio a la vista. Con zoom bajo el espacio cabe y la cámara
## queda cerca de `home`; con zoom alto se puede recorrer hasta los bordes,
## que quedan justo dentro de la parte visible.
func _clamp(target: Vector3) -> Vector3:
	var view: Vector2 = _view_size()
	var meters_per_px: float = size / view.x
	var half: Vector2 = view * meters_per_px / 2.0
	var top: float = inset_top_px * meters_per_px
	var bottom: float = inset_bottom_px * meters_per_px
	var home_r: float = _home.dot(_right)
	var home_u: float = _home.dot(_up)
	var r: float = clampf(target.dot(_right), minf(_extent_min.x + half.x, home_r), maxf(_extent_max.x - half.x, home_r))
	var u: float = clampf(target.dot(_up), minf(_extent_min.y + half.y - bottom, home_u), maxf(_extent_max.y - half.y + top, home_u))
	return _compose(r, u)


func _compose(r: float, u: float) -> Vector3:
	return _right * r + _up * u + _forward * _home.dot(_forward)


func _apply() -> void:
	var meters_per_px: float = size / _view_size().x
	var r: float = _target.dot(_right)
	var u: float = _target.dot(_up)
	var snapped_r: float = roundf(r / meters_per_px) * meters_per_px
	var snapped_u: float = roundf(u / meters_per_px) * meters_per_px
	pixel_remainder = Vector2((r - snapped_r) / meters_per_px, (u - snapped_u) / meters_per_px)
	position = _compose(snapped_r, snapped_u) - _forward * DISTANCE

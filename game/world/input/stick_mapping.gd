class_name StickMapping
extends RefCounted
## Convierte la dirección del joystick en la pantalla en una dirección en el
## piso del mundo.


## `screen`: dirección en la pantalla (x a la derecha, y hacia abajo) con largo
## de 0 a 1. Devuelve una dirección en el piso (x, z) con el mismo largo.
## Con `screen_aligned`, compensa que la vista inclinada aplasta la
## profundidad: el personaje va justo hacia donde apunta el pulgar.
static func to_floor(screen: Vector2, camera_basis: Basis, screen_aligned: bool) -> Vector2:
	if screen.length_squared() < 0.000001:
		return Vector2.ZERO
	var right: Vector3 = camera_basis.x
	var forward: Vector3 = -camera_basis.z
	var right_floor: Vector2 = Vector2(right.x, right.z).normalized()
	var forward_floor: Vector2 = Vector2(forward.x, forward.z).normalized()
	var up_amount: float = -screen.y
	if screen_aligned:
		up_amount /= absf(sin(deg_to_rad(CameraRig.PITCH)))
	var direction: Vector2 = (right_floor * screen.x + forward_floor * up_amount).normalized()
	return direction * minf(screen.length(), 1.0)

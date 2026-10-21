class_name ControlsTuning
extends RefCounted
## Valores que definen cómo se sienten los controles: joystick, caminar,
## cercanía con los objetos y cámara. Están todos aquí para ajustarlos en un
## solo lugar; los que más se notan también se pueden cambiar en vivo desde
## Ajustes → Controles (pruebas), para probarlos en el teléfono.
##
## No son números de balance: no cambian la simulación, solo la sensación.
## Las distancias en pantalla están en píxeles de la interfaz (720 de ancho).

## Instancia que usa el juego. Ajustes la modifica en vivo (no se guarda: al
## volver a abrir el juego, vuelven los valores de fábrica).
static var current: ControlsTuning = ControlsTuning.new()

# --- Toques ---
## Lo que se puede mover el dedo para que todavía cuente como toque y no
## como arrastre (Android usa unos 8 dp, que son unos 14 px aquí).
var tap_slop_px: float = 16.0
## Distancia entre dos dedos que hay que cambiar para que empiece el zoom.
## Evita que un roce de la palma corte el joystick.
var pinch_start_px: float = 24.0
## Los toques que empiezan tan cerca del borde izquierdo o derecho no mueven
## al personaje: ahí están los gestos del sistema para "atrás".
var edge_ignore_px: float = 20.0

# --- Joystick ---
## Radio del aro que se dibuja.
var joystick_ring_px: float = 90.0
## Recorrido del dedo para llegar a la velocidad máxima.
var joystick_full_speed_px: float = 60.0
## Con el dedo más cerca del centro que esto, el personaje se detiene.
var joystick_deadzone_px: float = 8.0
## Velocidad mínima al salir de la zona muerta (fracción de la máxima), para
## que el primer paso no se sienta lento.
var joystick_min_speed: float = 0.35
## Corrige el aplanamiento de la vista isométrica: el personaje va hacia
## donde apunta el pulgar en la pantalla, también en diagonal.
var joystick_screen_aligned: bool = true

# --- Caminar ---
## Metros por segundo a velocidad máxima.
var walk_speed: float = 2.6
## Segundos para llegar a la velocidad máxima y para detenerse.
var acceleration_time: float = 0.06
var deceleration_time: float = 0.08
## Grados por segundo al girar.
var turn_speed_degrees: float = 720.0
## Metros que avanza el personaje en un ciclo de dos pasos.
var stride_length: float = 0.55

# --- Cercanía con los objetos ---
## A esta distancia (del centro del personaje al borde del objeto) el objeto
## se resalta, y se deja de resaltar al alejarse más allá de reach_exit.
var reach_enter: float = 0.7
var reach_exit: float = 0.9
## Otro objeto toma el resalte solo si está al menos así de más cerca.
var reach_switch_margin: float = 0.15

# --- Cámara ---
## Tiempo (segundos) que tarda la cámara en alcanzar al personaje. Menos es
## más pegada; más es más suave.
var camera_follow_time: float = 0.15
## Metros que la cámara se adelanta hacia donde camina el personaje, con
## zoom de 2× o más.
var camera_look_ahead: float = 0.35
## Segundos entre pasos de zoom con la rueda del mouse (los touchpads mandan
## muchos eventos seguidos).
var wheel_cooldown: float = 0.15


## Vuelve a los valores de fábrica. Cambia la misma instancia, porque los
## controles guardan una referencia a ella.
static func reset() -> void:
	var defaults: ControlsTuning = ControlsTuning.new()
	for property: Dictionary in defaults.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			current.set(property["name"], defaults.get(property["name"]))


## Convierte la distancia del dedo al centro del joystick en una fracción de
## la velocidad máxima (0 a 1).
func speed_fraction(distance_px: float) -> float:
	if distance_px < joystick_deadzone_px:
		return 0.0
	var span: float = maxf(joystick_full_speed_px - joystick_deadzone_px, 1.0)
	var travel: float = clampf((distance_px - joystick_deadzone_px) / span, 0.0, 1.0)
	return lerpf(joystick_min_speed, 1.0, travel)

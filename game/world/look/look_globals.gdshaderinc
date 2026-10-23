// Globales del mundo "Mundo Impreso" (biblia de arte §2.4 y §3.2) y el modelo
// de color.
//
// Modelo de color: todo se pinta y se ilumina en el espacio de la pantalla.
// Un color #rrggbb bajo luz neutra 1,0 se ve exactamente así:
//   color = albedo × (ambiente + relleno + luces + parche) × oclusión
//         + albedo × sol + luz propia
// Lo que no es el sol sale por cc_out() (pasada base) y el sol por
// cc_sun_out() (dentro de light()). Las dos deshacen las conversiones de
// color que el motor aplica a esa pasada, según lo que midió ColorProbe
// (game/world/look/color_probe.gd) al arrancar, y la captura
// 00_calibracion comprueba el resultado.
//
// Lo medido en Compatibility (Godot 4.7.2, ver docs/DECISIONES.md): la
// pasada base pasa EMISSION y el ALBEDO sin luz a lineal con un cúbico
// (cc_engine_linear) y al final todo vuelve a sRGB con una potencia
// (cc_engine_srgb). Lo que suma light() ya es lineal. El sol con sombra se
// dibuja en otra pasada que se pasa a sRGB por su cuenta y se suma ya en el
// espacio de la pantalla.
//
// Los valores los ponen DayCycle (la hora), RoomView (personaje y tiempo de
// animación), CameraRig (metros por píxel) y ColorProbe. Los de por defecto
// (la mañana) están en project.godot, sección [shader_globals].

#ifndef LOOK_GLOBALS
#define LOOK_GLOBALS

// Ambiente de arriba y rebote de abajo (ya multiplicados por su energía).
global uniform vec3 cc_amb_sky;
global uniform vec3 cc_amb_ground;
// Relleno desde el lado de la cámara: dirección, rgb × energía y en w el
// refuerzo extra para el personaje.
global uniform vec3 cc_fill_dir;
global uniform vec4 cc_fill;
// Luz de la ventana: hacia dónde viaja, color × fuerza, hueco (z0, z1, y0,
// y1), plano de la pared, rejas (separación, medio grosor, alto del
// travesaño, medio ancho del parante central) y el adorno de sol de la reja
// (centro z, y; radio de los dos aros). Las medidas salen de WindowSpec.
global uniform vec3 cc_window_dir;
global uniform vec3 cc_window_color;
global uniform vec4 cc_window_rect;
global uniform float cc_window_x;
global uniform vec4 cc_window_bars;
global uniform vec4 cc_window_sun;
// Dos cajas que tapan el parche de la ventana (centro y medias medidas).
global uniform vec4 cc_occ_a_c;
global uniform vec4 cc_occ_a_h;
global uniform vec4 cc_occ_b_c;
global uniform vec4 cc_occ_b_h;
// Personaje: posición de los pies y radio de su mancha (0 = no hay).
global uniform vec4 cc_char_pos;
// Cuatro luces del sombreador: posición y alcance; color × intensidad.
global uniform vec4 cc_pl0;
global uniform vec4 cc_pl1;
global uniform vec4 cc_pl2;
global uniform vec4 cc_pl3;
global uniform vec4 cc_pl0_col;
global uniform vec4 cc_pl1_col;
global uniform vec4 cc_pl2_col;
global uniform vec4 cc_pl3_col;
// Tira LED: segmento de a a b, color × intensidad y alcance en w.
global uniform vec3 cc_strip_a;
global uniform vec3 cc_strip_b;
global uniform vec4 cc_strip_col;
// 0 de día, 1 de noche.
global uniform float cc_night;
// Metros por píxel interno del dibujo del mundo.
global uniform float cc_px_m;
// Cuarto: x0, z0, lado y alto de pared.
global uniform vec4 cc_room;
// Modelo de color: 1 = el motor convierte esa pasada a sRGB. Y si el sol del
// nivel de calidad actual tiene sombra (si no, va en la pasada base).
global uniform float cc_base_fix;
global uniform float cc_sun_fix;
global uniform float cc_sun_shadowed;
// Tiempo de animación (pantallas, latidos, balanceo). Lo avanza
// RoomView.step(): con el paso fijo de las capturas siempre da lo mismo.
global uniform float cc_anim_time;

// El cúbico con que el motor pasa a lineal lo que sale de la pasada base.
vec3 cc_engine_linear(vec3 x) {
	return x * (x * (x * 0.305306011 + 0.682171111) + 0.012522878);
}

// Lo que hay que entregarle a la potencia final del motor para ver `c` en la
// pantalla (su inversa exacta).
vec3 cc_from_display(vec3 c) {
	return pow((clamp(c, 0.0, 1.0) + 0.055) / 1.055, vec3(2.4));
}

// Salida de la pasada base: `c` es el color tal como debe verse.
vec3 cc_out(vec3 c) {
	vec3 target = cc_from_display(c);
	if (cc_base_fix > 0.5) {
		return target;
	}
	// El motor pasa la salida a lineal con su cúbico: se le entrega el valor
	// que da `target` después del cúbico (tres pasos de Newton desde c). Sin
	// esto, lo oscuro se ve más oscuro (0,05 se veía 0,027).
	vec3 x = clamp(c, 0.0, 1.0);
	for (int i = 0; i < 3; i++) {
		x -= (cc_engine_linear(x) - target) / (x * (x * 0.915918033 + 1.364342222) + 0.012522878);
	}
	return max(x, vec3(0.0));
}

// Salida del sol (dentro de light()): `c` es lo que el sol debe sumar en la
// pantalla y `base` lo que ya puso la pasada base en ese punto. Con sombra,
// el sol va en su propia pasada; sin sombra (nivel Bajo) se suma en lineal
// dentro de la pasada base.
vec3 cc_sun_out(vec3 c, vec3 base) {
	if (cc_sun_shadowed > 0.5) {
		return cc_sun_fix > 0.5 ? cc_from_display(c) : c;
	}
	return cc_from_display(base + c) - cc_from_display(base);
}

float cc_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float cc_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(cc_hash(i), cc_hash(i + vec2(1.0, 0.0)), u.x),
		mix(cc_hash(i + vec2(0.0, 1.0)), cc_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Parpadeo suave de la guirnalda de noche (biblia §8.9): cada foco a su
// ritmo según dónde está a lo largo de la pared (x), entre 0,62 y 1. Lo usan
// el foco (kit_body, luz propia que parpadea) y su halo (halo_field).
float cc_twinkle(float x) {
	return 0.81 + 0.12 * sin(cc_anim_time * 1.9 + x * 9.7) + 0.07 * sin(cc_anim_time * 3.1 + x * 23.3);
}

// Las líneas finas se apagan cuando quedan por debajo de un píxel (si no,
// centellean): `coord_fw` es fwidth de la coordenada y `period` su periodo.
float cc_aa_fade(float coord_fw, float period) {
	return 1.0 - smoothstep(0.3, 0.75, coord_fw / period);
}

#endif

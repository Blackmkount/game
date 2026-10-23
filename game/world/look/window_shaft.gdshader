// Haz de luz que entra por la ventana (biblia de arte §6.3), sin niebla
// volumétrica: los cuatro bordes del hueco se estiran en el sombreador desde
// la pared hasta el piso, en la dirección de la luz de la ventana de esa hora,
// y SUMAN un brillo tenue con las rayas de las rejas (las mismas del parche:
// WindowSpec). Una llamada de dibujo, sin sombra. `strength` lo pone DayCycle
// (factor "window_shaft" de la hora).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://game/world/look/look_globals.gdshaderinc"

uniform float strength = 0.0;

// UV.y: 0 en la pared, 1 en el piso. Posición en el hueco (0 a 1).
varying float v_along;
varying vec2 v_hole;

void vertex() {
	vec3 p = VERTEX;
	vec4 r = cc_window_rect;
	float down = max(-cc_window_dir.y, 0.08);
	v_along = UV.y;
	v_hole = vec2((p.z - r.x) / (r.y - r.x), (p.y - r.z) / (r.w - r.z));
	VERTEX = p + cc_window_dir * (p.y / down) * UV.y;
	// Cada hoja contiene un borde del hueco (a lo largo de z) y la dirección
	// de la luz.
	NORMAL = normalize(cross(vec3(0.0, 0.0, 1.0), cc_window_dir));
}

void fragment() {
	vec4 r = cc_window_rect;
	vec4 bars = cc_window_bars;
	float z = r.x + v_hole.x * (r.y - r.x);
	float y = r.z + v_hole.y * (r.w - r.z);
	float soft = 0.004 + 0.012 * v_along * 2.0;
	float bar_z = abs(fract((z - r.x) / bars.x) - 0.5) * bars.x;
	float light = smoothstep(bars.y, bars.y + soft, bar_z);
	light *= smoothstep(bars.y, bars.y + soft, abs(y - bars.z));
	light *= smoothstep(bars.w, bars.w + soft, abs(z - (r.x + r.y) * 0.5));
	float fade = pow(1.0 - v_along, 1.5) * smoothstep(0.0, 0.06, v_along + 0.01);
	float edge = smoothstep(0.0, 0.12, v_hole.x) * smoothstep(1.0, 0.88, v_hole.x);
	float facing = abs(dot(NORMAL, VIEW));
	float shimmer = 0.9 + 0.1 * sin(cc_anim_time * 0.6 + v_along * 9.0 + v_hole.x * 5.0);
	vec3 c = cc_window_color * strength * fade * mix(0.35, 1.0, light) * edge * (0.4 + 0.6 * facing) * shimmer;
	ALBEDO = cc_out(c);
}

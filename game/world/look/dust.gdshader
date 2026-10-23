// Motas de polvo que flotan en el haz de la ventana de día (biblia de arte
// §8.9, DustField): un MultiMesh de cuadritos que miran a la cámara y SUMAN la
// luz de la ventana con un punto suave. Cada copia trae en INSTANCE_CUSTOM
// dónde está dentro del haz (u, v en el hueco; t a lo largo de la luz) y su
// fase; el sombreador las pone en la dirección de la ventana de esa hora
// (cc_window_dir), así siguen al haz cuando cambia la hora. Se mueven con
// cc_anim_time. `strength` lo pone DayCycle (factor "haz y polvo"); en 0 el
// nodo se esconde.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://game/world/look/look_globals.gdshaderinc"

uniform float strength = 0.0;
// Lado de una mota (m) y cuánto brilla con factor 1.
uniform float size = 0.012;
uniform float brightness = 1.6;
// Hasta dónde baja el polvo por el haz (fracción del camino al piso) y
// cuánto se mueve cada mota alrededor de su lugar (m).
uniform float reach = 0.85;
uniform float drift = 0.035;

varying float v_glow;

void vertex() {
	vec4 m = INSTANCE_CUSTOM;
	vec4 r = cc_window_rect;
	float down = max(-cc_window_dir.y, 0.08);
	vec3 start = vec3(cc_window_x, mix(r.z, r.w, m.y), mix(r.x, r.y, m.x));
	float along = m.z * reach;
	vec3 p = start + cc_window_dir * (start.y / down) * along;
	float time = cc_anim_time * 0.12 + m.w * 6.2832;
	p += vec3(sin(time * 1.3), sin(time * 0.9 + 1.7), cos(time * 1.1)) * drift;
	float scale = size * (0.7 + 0.6 * fract(m.w * 7.31));
	vec3 right = INV_VIEW_MATRIX[0].xyz;
	vec3 up = INV_VIEW_MATRIX[1].xyz;
	vec3 world = p + (right * VERTEX.x + up * VERTEX.y) * scale;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
	// Aparecen al entrar al haz, se apagan cerca del piso y titilan.
	float fade = smoothstep(0.0, 0.12, m.z) * (1.0 - smoothstep(0.7, 1.0, m.z));
	v_glow = fade * (0.55 + 0.45 * sin(time * 9.0 + m.w * 23.0));
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float a = pow(clamp(1.0 - length(q), 0.0, 1.0), 1.5);
	ALBEDO = cc_out(cc_window_color * strength * brightness * v_glow * a);
}

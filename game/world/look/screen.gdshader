// Pantallas con luz propia, dibujadas aquí mismo (sin texturas). `mode`:
// 0 computador viejo en reposo (terminal), 1 computador modelando (cubo de
// alambre que gira), 2 a 5 pantallita de la impresora (libre, imprimiendo,
// lista, falla). Lo de adentro sí tiene píxeles grandes a propósito: es el
// contenido de una pantalla vieja.
// Se anima con cc_anim_time (no con TIME): las capturas con paso fijo salen
// siempre iguales.
shader_type spatial;
render_mode unshaded, shadows_disabled, fog_disabled;

#include "res://game/world/look/look_globals.gdshaderinc"
#include "res://game/world/look/printer_display.gdshaderinc"

uniform int mode = 0;
uniform vec4 tint = vec4(1.0);

vec3 terminal(vec2 px, vec2 q) {
	vec3 col = mix(vec3(0.05, 0.16, 0.14), vec3(0.08, 0.22, 0.19), q.y);
	// Barra de arriba.
	if (px.y < 0.1) {
		col = vec3(0.13, 0.3, 0.26);
	}
	// Líneas de texto que suben despacio.
	float scroll = px.y * 18.0 + cc_anim_time * 0.6;
	float width = 0.25 + cc_hash(vec2(floor(scroll), 3.0)) * 0.55;
	float y_in = fract(scroll);
	if (px.y > 0.14 && px.x > 0.08 && px.x < 0.08 + width && y_in > 0.3 && y_in < 0.75) {
		col = mix(col, vec3(0.5, 0.88, 0.63), 0.85);
	}
	// Cursor que parpadea.
	if (px.x > 0.08 && px.x < 0.13 && px.y > 0.82 && px.y < 0.88 && fract(cc_anim_time * 1.2) < 0.55) {
		col = vec3(0.7, 1.0, 0.8);
	}
	return col;
}

vec3 modeling(vec2 px) {
	vec3 col = mix(vec3(0.07, 0.11, 0.22), vec3(0.11, 0.17, 0.31), px.y);
	// Barras de herramientas del programa de modelado.
	if (px.x < 0.1) {
		col = vec3(0.14, 0.2, 0.34);
	}
	if (px.y < 0.09) {
		col = vec3(0.16, 0.23, 0.38);
	}
	if (px.x < 0.1 && fract(px.y * 7.0) < 0.45 && px.y > 0.15) {
		col = vec3(0.22, 0.6, 0.85);
	}
	// Piso en cuadrícula.
	if (px.y > 0.62) {
		vec2 g = vec2((px.x - 0.55) / max(px.y - 0.45, 0.02), 1.0 / max(px.y - 0.45, 0.02));
		float grid = min(abs(fract(g.x * 0.5) - 0.5), abs(fract(g.y * 0.25 + cc_anim_time * 0.1) - 0.5));
		col = mix(col, vec3(0.16, 0.35, 0.55), (1.0 - smoothstep(0.0, 0.06, grid)) * 0.6);
	}
	// Cubo de alambre que gira (el modelo del pedido).
	float a = cc_anim_time * 0.7;
	float ca = cos(a);
	float sa = sin(a);
	vec2 center = vec2(0.56, 0.45);
	vec2 pts[8];
	for (int i = 0; i < 8; i++) {
		vec3 v = vec3(float(i & 1) * 2.0 - 1.0, float((i >> 1) & 1) * 2.0 - 1.0, float((i >> 2) & 1) * 2.0 - 1.0);
		vec3 r = vec3(v.x * ca - v.z * sa, v.y, v.x * sa + v.z * ca);
		r = vec3(r.x, r.y * 0.92 - r.z * 0.38, r.y * 0.38 + r.z * 0.92);
		pts[i] = center + vec2(r.x, -r.y) * vec2(0.17, 0.22);
	}
	float d = 10.0;
	for (int i = 0; i < 8; i++) {
		for (int k = 0; k < 3; k++) {
			int j = i ^ (1 << k);
			if (j > i) {
				d = min(d, seg(px, pts[i], pts[j]));
			}
		}
	}
	return mix(col, vec3(0.45, 0.92, 1.0), 1.0 - smoothstep(0.0, 0.018, d));
}

// Monitor viejo: vidrio curvo (esquinas oscuras) y líneas de barrido.
vec3 crt(vec2 uv, bool is_modeling) {
	vec2 c = uv * 2.0 - 1.0;
	c *= 1.0 + 0.06 * dot(c, c);
	vec2 q = c * 0.5 + 0.5;
	if (q.x < 0.0 || q.x > 1.0 || q.y < 0.0 || q.y > 1.0) {
		return vec3(0.02);
	}
	float vignette = 1.0 - smoothstep(0.55, 1.08, length(c * vec2(0.92, 1.0)));
	vec2 px = floor(q * vec2(96.0, 72.0)) / vec2(96.0, 72.0);
	vec3 col = is_modeling ? modeling(px) : terminal(px, q);
	col *= 0.86 + 0.14 * step(0.5, fract(q.y * 72.0));
	return col * vignette * 1.25;
}

void fragment() {
	vec3 col = mode <= 1 ? crt(UV, mode == 1) : display(UV, mode);
	ALBEDO = cc_out(col * tint.rgb);
}

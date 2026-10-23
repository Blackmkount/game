// Destellos de "pieza lista" (ReadySparkles): estrellitas de cuatro puntas
// (dos rectángulos cruzados; en cada uno, un brazo que se afina hasta la
// punta) que se MEZCLAN con lo de atrás, con el borde del verde de "lista" y
// el centro dorado. Sumar luz no se veía sobre el piso al sol, que ya es
// claro; así se leen sobre lo claro y sobre lo oscuro.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://game/world/look/look_globals.gdshaderinc"

uniform vec4 edge_color = vec4(0.298, 0.749, 0.353, 1.0);
uniform vec4 core_color = vec4(1.0, 0.824, 0.478, 1.0);
// Desde dónde (hacia el centro del brazo) empieza el dorado y dónde ya es
// todo dorado (0 = la punta, 1 = el centro).
uniform vec2 core = vec2(0.45, 0.85);

void fragment() {
	// x a lo largo del brazo, y a lo ancho; el brazo se afina hacia la punta.
	vec2 p = UV * 2.0 - 1.0;
	float t = 1.0 - abs(p.x);
	float half_width = t * t;
	float inside = half_width - abs(p.y);
	ALPHA = smoothstep(0.0, 0.12, inside);
	float gold = smoothstep(core.x, core.y, t) * smoothstep(0.0, 0.5, inside / max(half_width, 0.001));
	ALBEDO = cc_out(mix(edge_color.rgb, core_color.rgb, gold));
}

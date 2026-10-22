// Fondo del diorama (biblia de arte §8.10): un cuadro pegado a la cámara con
// un degradado del centro al borde, un resplandor detrás del cuarto (con la
// viñeta incluida, sin pasada de pantalla completa) y ruido contra las
// bandas. Los colores los pone DayCycle según la hora.
shader_type spatial;
// Opaco (escribe profundidad al fondo de la vista): con depth_draw_never,
// Compatibility lo dibuja entre los transparentes y los tapa.
render_mode unshaded, shadows_disabled, fog_disabled;

#include "res://game/world/look/look_globals.gdshaderinc"

uniform vec4 center_color = vec4(0.149, 0.2, 0.361, 1.0);
uniform vec4 edge_color = vec4(0.078, 0.106, 0.176, 1.0);
// Resplandor detrás del diorama (ya multiplicado por su fuerza).
uniform vec4 glow_color = vec4(0.125, 0.16, 0.268, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	float r = length((uv - vec2(0.5, 0.5)) * vec2(1.1, 0.95));
	vec3 col = mix(center_color.rgb, edge_color.rgb, smoothstep(0.1, 0.85, r));
	float glow = 1.0 - smoothstep(0.0, 0.62, length((uv - vec2(0.5, 0.55)) * vec2(1.0, 1.25)));
	col += glow_color.rgb * glow;
	float grain = cc_hash(FRAGCOORD.xy);
	ALBEDO = cc_out(col + (grain - 0.5) / 255.0);
}

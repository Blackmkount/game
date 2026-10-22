// Halos de noche en el piso (HaloField): un MultiMesh de cuadros acostados
// que SUMAN luz con un degradé redondo, cada uno del color de su copia
// (MultiMesh.use_colors: llega multiplicado en COLOR). Solo de noche: todo se
// multiplica por cc_night.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://game/world/look/look_globals.gdshaderinc"

uniform float falloff = 1.6;
uniform float intensity = 1.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float a = pow(clamp(1.0 - length(p), 0.0, 1.0), falloff);
	ALBEDO = cc_out(COLOR.rgb * a * intensity * cc_night);
}

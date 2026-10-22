// Contorno fino del personaje (biblia de arte §3.7): casco invertido por las
// normales (sirve con mallas suaves, unidas y con piel), siempre de
// OUTLINE_PX píxeles: el grosor sale de cc_px_m (metros por píxel del mundo)
// o, en un retrato, de px_m_override. Lo dibuja una MeshInstance3D aparte que
// comparte la malla y no da sombra. Tinta índigo; en el pelo, café oscuro.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled, fog_disabled;

#include "res://game/world/look/look_globals.gdshaderinc"

uniform vec4 ink = vec4(0.102, 0.0941, 0.1882, 1.0);
uniform vec4 hair_ink = vec4(0.1804, 0.0941, 0.0471, 1.0);
instance uniform float px_m_override = 0.0;

const float OUTLINE_PX = 1.5;
// La superficie del pelo (UV.x entero, ver kit_body.gdshaderinc).
const int CC_HAIR = 9;

varying vec3 v_ink;

void vertex() {
	float px_m = px_m_override > 0.0 ? px_m_override : cc_px_m;
	float scale = max(length(MODEL_MATRIX[0].xyz), 0.001);
	VERTEX += normalize(NORMAL) * (OUTLINE_PX * px_m / scale);
	v_ink = int(floor(UV.x + 0.001)) == CC_HAIR ? hair_ink.rgb : ink.rgb;
}

void fragment() {
	ALBEDO = cc_out(v_ink);
}

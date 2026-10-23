// Sombra suave debajo de la base del diorama: lo apoya en el fondo, como una
// foto de producto. Color y fuerza: biblia de arte §4.1 (#05070f al 60 %).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://game/world/look/look_globals.gdshaderinc"

uniform vec4 color = vec4(0.0196, 0.0275, 0.0588, 0.6);

void fragment() {
	float d = length(UV * 2.0 - 1.0);
	ALBEDO = cc_out(color.rgb);
	ALPHA = color.a * (1.0 - smoothstep(0.55, 1.0, d));
}

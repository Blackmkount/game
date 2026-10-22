// Marcas del piso que se tocan (lugar libre, marco de cercanía, destino):
// color plano semitransparente. Si `period` > 0, el alfa late entre `alpha` y
// `alpha_low` con ese periodo (segundos de cc_anim_time).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://game/world/look/look_globals.gdshaderinc"

uniform vec4 color = vec4(0.2196, 0.8392, 1.0, 1.0);
uniform float alpha = 1.0;
uniform float alpha_low = 1.0;
uniform float period = 0.0;

void fragment() {
	float a = alpha;
	if (period > 0.0) {
		a = mix(alpha, alpha_low, 0.5 - 0.5 * cos(cc_anim_time * 6.2831853 / period));
	}
	ALBEDO = cc_out(color.rgb);
	ALPHA = a * color.a;
}

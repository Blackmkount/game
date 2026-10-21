// EXP 3a: paleta + Bayer 4x4 como postproceso 3D con hint_screen_texture.
shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled, fog_disabled;

#include "res://shaders/palette_dither.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest, repeat_disable;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	ivec2 pixel = ivec2(FRAGCOORD.xy);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// Medido en 4.7.2: en Compatibility la textura de pantalla y ALBEDO de un
	// shader unshaded ya están en el espacio de la pantalla (sRGB).
	ALBEDO = palette_dither(c, pixel);
#else
	ALBEDO = to_linear(palette_dither(to_srgb(c), pixel));
#endif
}

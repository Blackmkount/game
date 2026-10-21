// EXP 2: ¿existe hint_normal_roughness_texture en Compatibility?
shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled;

uniform sampler2D nr_tex : hint_normal_roughness_texture, filter_nearest, repeat_disable;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	ALBEDO = texture(nr_tex, SCREEN_UV).rgb;
}

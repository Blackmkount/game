// Experimento 3A: oclusión ambiental falsa con planos que oscurecen (blend_mul).
// shape 0: franja (UV.y = 0 en el borde de contacto, se aclara hacia UV.y = 1).
// shape 1: mancha rectangular redondeada bajo un objeto (sombra de contacto).
// Se dibuja en bandas, con tramado opcional, para que parezca pixel art.
shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_disabled, shadows_disabled;

uniform int shape = 0;
uniform vec3 tint : source_color = vec3(0.42, 0.33, 0.52);
uniform float strength = 0.75;
uniform float steps = 3.0;
uniform float dither = 1.0;
uniform vec2 size_m = vec2(1.0, 1.0);
uniform float falloff_m = 0.15;

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	const float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[x + y * 4] + 0.5) / 16.0;
}

void fragment() {
	float occlusion;
	if (shape == 0) {
		occlusion = pow(1.0 - UV.y, 1.5);
	} else {
		vec2 p = (UV - 0.5) * size_m;
		vec2 inner = size_m * 0.5 - vec2(falloff_m);
		vec2 q = abs(p) - inner;
		float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
		occlusion = clamp(1.0 - d / falloff_m, 0.0, 1.0);
	}
	float offset = mix(0.5, bayer4(FRAGCOORD.xy), dither);
	float level = clamp(floor(occlusion * steps + offset) / steps, 0.0, 1.0);
	ALBEDO = mix(vec3(1.0), tint, level * strength);
}

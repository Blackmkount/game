// Experimento 4 (apoyo): haz de luz falso desde la ventana. Prisma inclinado,
// aditivo y sin escritura de profundidad. UV.y = 0 en la ventana y 1 en el
// piso; la intensidad baja en 3 escalones con tramado.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec3 color : source_color = vec3(1.0, 0.72, 0.38);
uniform float intensity = 0.2;
// 0 = sin tramado, 1 = tramado en todo el degradado.
uniform float dither = 0.3;
uniform float steps = 3.0;

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	const float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[x + y * 4] + 0.5) / 16.0;
}

void fragment() {
	float amount = mix(1.0, 0.25, UV.y);
	amount = floor(amount * steps + 0.5 + (bayer4(FRAGCOORD.xy) - 0.5) * dither) / steps;
	ALBEDO = color * amount * intensity;
}

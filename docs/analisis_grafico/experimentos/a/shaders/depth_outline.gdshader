// EXP 1: contorno por detección de bordes usando la profundidad.
// Se dibuja en un rectángulo que cubre toda la pantalla dentro del SubViewport.
shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform vec4 line_color : source_color = vec4(0.102, 0.075, 0.125, 1.0);
// Color de las aristas convexas (bordes que apuntan a la cámara): un brillo.
uniform vec4 ridge_color : source_color = vec4(1.0, 0.945, 0.863, 0.35);
// Color de las aristas cóncavas (rincones, unión con el piso).
uniform vec4 valley_color : source_color = vec4(0.102, 0.075, 0.125, 0.45);
// Salto de profundidad (metros) que cuenta como silueta.
uniform float silhouette_threshold = 0.08;
// Cambio de pendiente de la profundidad que cuenta como arista interior.
uniform float crease_threshold = 0.006;
uniform bool use_creases = true;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float view_depth(vec2 uv, mat4 inv_proj) {
	float raw = texture(depth_tex, uv).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(uv, raw) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(uv * 2.0 - 1.0, raw);
#endif
	vec4 view = inv_proj * vec4(ndc, 1.0);
	return -view.z / view.w;
}

void fragment() {
	vec2 px = 1.0 / VIEWPORT_SIZE;
	float c = view_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	float l = view_depth(SCREEN_UV - vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float r = view_depth(SCREEN_UV + vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float u = view_depth(SCREEN_UV - vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	float d = view_depth(SCREEN_UV + vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	// Silueta: este píxel está delante de un vecino lejano. Así la línea cae
	// sobre el objeto cercano y mide 1 píxel.
	float far_step = max(max(l, r), max(u, d)) - c;
	float silhouette = step(silhouette_threshold, far_step);
	float ridge = 0.0;
	float valley = 0.0;
	if (use_creases) {
		// En cámara ortográfica una cara plana tiene profundidad lineal en
		// pantalla: su segunda derivada es cero. Si no lo es, hay una arista.
		float jump = max(max(abs(l - c), abs(r - c)), max(abs(u - c), abs(d - c)));
		float flat_area = step(jump, silhouette_threshold);
		float lap = (l + r - 2.0 * c) + (u + d - 2.0 * c);
		ridge = step(crease_threshold, lap) * flat_area;
		valley = step(crease_threshold, -lap) * flat_area;
	}
	vec3 color = line_color.rgb;
	float alpha = silhouette * line_color.a;
	if (silhouette < 0.5) {
		color = mix(valley_color.rgb, ridge_color.rgb, ridge);
		alpha = max(ridge * ridge_color.a, valley * valley_color.a);
	}
	ALBEDO = color;
	ALPHA = alpha;
}

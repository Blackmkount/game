// EXP 1b: contorno por profundidad + aristas por normales RECONSTRUIDAS desde
// la profundidad (sustituto de hint_normal_roughness_texture, que no existe en
// Compatibility). Silueta oscura de 1 px; aristas convexas con brillo y
// cóncavas con sombra, también de 1 px.
shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform vec4 line_color : source_color = vec4(0.102, 0.075, 0.125, 1.0);
uniform vec4 ridge_color : source_color = vec4(1.0, 0.945, 0.863, 0.4);
uniform vec4 valley_color : source_color = vec4(0.102, 0.075, 0.125, 0.4);
uniform float silhouette_threshold = 0.08;
// Ángulo mínimo (grados) entre dos caras para dibujar una arista.
uniform float crease_angle = 35.0;
// Depuración: 1 = rojo arista convexa, azul cóncava, verde silueta.
uniform int debug_view = 0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

vec3 view_pos(vec2 uv, mat4 inv_proj) {
	float raw = texture(depth_tex, uv).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(uv, raw) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(uv * 2.0 - 1.0, raw);
#endif
	vec4 v = inv_proj * vec4(ndc, 1.0);
	return v.xyz / v.w;
}

// Normal de la cara en uv. En cada eje elige el lado cuya recta (2 vecinos)
// predice mejor la profundidad de este píxel: así no mezcla dos caras ni en
// esquinas simétricas. La normal siempre mira hacia la cámara (+z de vista).
vec3 normal_at(vec2 uv, vec2 px, mat4 inv_proj) {
	vec2 ox = vec2(px.x, 0.0);
	vec2 oy = vec2(0.0, px.y);
	vec3 p = view_pos(uv, inv_proj);
	vec3 xp = view_pos(uv + ox, inv_proj);
	vec3 xp2 = view_pos(uv + 2.0 * ox, inv_proj);
	vec3 xn = view_pos(uv - ox, inv_proj);
	vec3 xn2 = view_pos(uv - 2.0 * ox, inv_proj);
	vec3 yp = view_pos(uv + oy, inv_proj);
	vec3 yp2 = view_pos(uv + 2.0 * oy, inv_proj);
	vec3 yn = view_pos(uv - oy, inv_proj);
	vec3 yn2 = view_pos(uv - 2.0 * oy, inv_proj);
	float err_xp = abs(2.0 * xp.z - xp2.z - p.z);
	float err_xn = abs(2.0 * xn.z - xn2.z - p.z);
	float err_yp = abs(2.0 * yp.z - yp2.z - p.z);
	float err_yn = abs(2.0 * yn.z - yn2.z - p.z);
	vec3 dx = err_xp < err_xn ? xp - p : p - xn;
	vec3 dy = err_yp < err_yn ? yp - p : p - yn;
	vec3 n = normalize(cross(dy, dx));
	return n.z < 0.0 ? -n : n;
}

void fragment() {
	vec2 px = 1.0 / VIEWPORT_SIZE;
	mat4 ip = INV_PROJECTION_MATRIX;
	float c = -view_pos(SCREEN_UV, ip).z;
	float l = -view_pos(SCREEN_UV - vec2(px.x, 0.0), ip).z;
	float r = -view_pos(SCREEN_UV + vec2(px.x, 0.0), ip).z;
	float u = -view_pos(SCREEN_UV - vec2(0.0, px.y), ip).z;
	float d = -view_pos(SCREEN_UV + vec2(0.0, px.y), ip).z;
	float far_step = max(max(l, r), max(u, d)) - c;
	float silhouette = step(silhouette_threshold, far_step);
	float jump = max(max(abs(l - c), abs(r - c)), max(abs(u - c), abs(d - c)));
	float flat_area = step(jump, silhouette_threshold);

	vec3 nc = normal_at(SCREEN_UV, px, ip);
	vec3 nr = normal_at(SCREEN_UV + vec2(px.x, 0.0), px, ip);
	vec3 nd = normal_at(SCREEN_UV + vec2(0.0, px.y), px, ip);
	float limit = cos(radians(crease_angle));
	float crease_x = step(dot(nc, nr), limit);
	float crease_y = step(dot(nc, nd), limit);
	// Convexa si la normal gira hacia donde avanzamos: dot(n2 - n1, p2 - p1) > 0.
	vec3 pc = view_pos(SCREEN_UV, ip);
	vec3 pr = view_pos(SCREEN_UV + vec2(px.x, 0.0), ip);
	vec3 pd = view_pos(SCREEN_UV + vec2(0.0, px.y), ip);
	float bend = crease_x * dot(nr - nc, pr - pc) + crease_y * dot(nd - nc, pd - pc);
	float lap_x = bend;
	// Las normales leen 2 píxeles alrededor: en el borde de la pantalla se
	// repetiría el último píxel y saldría una línea punteada falsa.
	vec2 border = step(vec2(2.0), FRAGCOORD.xy) * step(FRAGCOORD.xy, VIEWPORT_SIZE - 2.0);
	float crease = max(crease_x, crease_y) * flat_area * border.x * border.y;
	float ridge = crease * step(0.0, bend);
	float valley = crease * (1.0 - step(0.0, bend));

	vec3 color = line_color.rgb;
	float alpha = silhouette * line_color.a;
	if (silhouette < 0.5) {
		color = mix(valley_color.rgb, ridge_color.rgb, ridge);
		alpha = max(ridge * ridge_color.a, valley * valley_color.a);
	}
	ALBEDO = color;
	ALPHA = alpha;
	if (debug_view == 1) {
		ALBEDO = vec3(ridge, silhouette, valley);
		ALPHA = max(max(ridge, valley), silhouette);
	} else if (debug_view == 2) {
		ALBEDO = vec3(max(lap_x, 0.0), 0.0, max(-lap_x, 0.0)) * 40.0 + vec3(0.0, crease_x * 0.5, 0.0);
		ALPHA = 1.0;
	}
}

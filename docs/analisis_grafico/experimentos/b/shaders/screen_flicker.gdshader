// Experimento 5: pantalla emisiva con animación barata (solo TIME, sin texturas).
// Dibuja "líneas de código" que se desplazan, líneas de barrido, un cursor que
// parpadea, una banda que recorre la pantalla y un leve parpadeo de brillo.
// El tiempo se cuantiza (fps) para que la animación se sienta pixel art.
shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform vec2 resolution = vec2(22.0, 14.0);
uniform vec3 background : source_color = vec3(0.06, 0.13, 0.19);
uniform vec3 text_color : source_color = vec3(0.45, 0.95, 0.72);
uniform vec3 accent_color : source_color = vec3(0.35, 0.78, 1.0);
uniform float anim_fps = 8.0;
uniform float scroll_speed = 1.5;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 px = floor(UV * resolution);
	float t = floor(TIME * anim_fps) / anim_fps;
	float scroll = floor(t * scroll_speed);
	float row = px.y + scroll;
	vec3 color = background;
	bool text_row = mod(px.y, 2.0) < 1.0 && px.y > 0.0 && px.y < resolution.y - 1.0;
	float indent = 1.0 + floor(hash(vec2(row, 7.0)) * 3.0) * 2.0;
	float len = 3.0 + floor(hash(vec2(row, 1.0)) * (resolution.x - 8.0));
	if (text_row && px.x >= indent && px.x < indent + len) {
		bool gap = hash(vec2(px.x, row)) < 0.18;
		if (!gap) {
			color = hash(vec2(row, 3.0)) < 0.25 ? accent_color : text_color;
		}
	}
	// Cursor que parpadea en la última línea de texto.
	float last = resolution.y - 3.0;
	if (px.y == last && px.x == indent + len + 1.0 && mod(floor(TIME * 2.0), 2.0) < 1.0) {
		color = vec3(1.0);
	}
	// Líneas de barrido y banda que baja por la pantalla.
	color *= mod(px.y, 2.0) < 1.0 ? 1.0 : 0.82;
	float bar = 1.0 - fract(t * 0.35);
	if (abs(UV.y - bar) < 0.07) {
		color *= 1.25;
	}
	// Parpadeo global de brillo, en escalones.
	color *= 0.9 + 0.1 * hash(vec2(t, 3.0));
	ALBEDO = color;
}

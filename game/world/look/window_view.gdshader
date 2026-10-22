// Lo que se ve por la ventana: un barrio de una ciudad de valle (cerros con
// casitas de colores, azoteas con tanque de agua negro y varillas "para el
// próximo piso", ropa tendida, cables de luz y una buganvilla).
// `mood` = pesos (día, tarde, noche) que suman 1; lo pone DayCycle. Las nubes
// se mueven con cc_anim_time.
shader_type spatial;
render_mode unshaded, shadows_disabled, fog_disabled;

#include "res://game/world/look/look_globals.gdshaderinc"

uniform vec3 mood = vec3(1.0, 0.0, 0.0);

vec3 pick3(vec3 day, vec3 gold, vec3 night) {
	return day * mood.x + gold * mood.y + night * mood.z;
}

void fragment() {
	vec2 uv = UV;           // (0,0) arriba a la izquierda
	float y = 1.0 - uv.y;   // 0 abajo, 1 arriba
	float night = mood.z;
	// Cielo.
	vec3 sky_top = pick3(vec3(0.36, 0.6, 0.92), vec3(0.42, 0.36, 0.62), vec3(0.03, 0.05, 0.14));
	vec3 sky_low = pick3(vec3(0.8, 0.9, 0.97), vec3(1.0, 0.68, 0.42), vec3(0.12, 0.12, 0.28));
	vec3 col = mix(sky_low, sky_top, smoothstep(0.35, 1.0, y));
	// Nubes (de día y de tarde).
	float cl = cc_noise(vec2(uv.x * 4.0 + cc_anim_time * 0.01, y * 9.0)) * cc_noise(vec2(uv.x * 9.0, y * 3.0 + 1.7));
	col = mix(col, pick3(vec3(1.0), vec3(1.0, 0.82, 0.7), vec3(0.18, 0.18, 0.3)), smoothstep(0.25, 0.5, cl) * smoothstep(0.55, 0.8, y) * 0.7);
	// Sol bajo de la tarde y luna de noche.
	float sun = length((uv - vec2(0.78, 0.5)) * vec2(1.3, 1.0));
	col += vec3(1.0, 0.75, 0.4) * (1.0 - smoothstep(0.0, 0.09, sun)) * mood.y * 1.2 + vec3(1.0, 0.6, 0.3) * (1.0 - smoothstep(0.0, 0.35, sun)) * mood.y * 0.35;
	float moon = length((uv - vec2(0.25, 0.22)) * vec2(1.3, 1.0));
	col = mix(col, vec3(0.95, 0.95, 0.85), (1.0 - smoothstep(0.035, 0.045, moon)) * night);
	// Estrellas.
	vec2 sc = floor(uv * vec2(70.0, 50.0));
	col += vec3(0.8) * step(0.985, cc_hash(sc)) * night * smoothstep(0.45, 0.8, y);
	// Cerros lejanos con casitas.
	float ridge = 0.42 + 0.07 * sin(uv.x * 5.0 + 1.3) + 0.03 * sin(uv.x * 13.0);
	if (y < ridge) {
		vec3 hill = pick3(vec3(0.5, 0.64, 0.58), vec3(0.62, 0.45, 0.45), vec3(0.07, 0.09, 0.17));
		vec2 cell = floor(vec2(uv.x * 55.0, y * 60.0));
		float r = cc_hash(cell);
		vec3 houses[4] = vec3[4](vec3(0.95, 0.8, 0.62), vec3(0.92, 0.6, 0.52), vec3(0.98, 0.92, 0.75), vec3(0.75, 0.82, 0.92));
		if (r > 0.45 && y < ridge - 0.02) {
			hill = mix(hill, houses[int(r * 40.0) % 4] * pick3(vec3(1.0), vec3(1.0, 0.75, 0.6), vec3(0.15)), 0.55);
			if (r > 0.8) hill = mix(hill, vec3(1.0, 0.82, 0.45), night * 0.9);
		}
		col = mix(col, hill, 0.95);
	}
	// Ciudad del medio: edificios bajos.
	float bx = floor(uv.x * 9.0);
	float bh = 0.22 + cc_hash(vec2(bx, 4.0)) * 0.14;
	if (y < bh) {
		vec3 walls[4] = vec3[4](vec3(0.93, 0.7, 0.5), vec3(0.97, 0.88, 0.6), vec3(0.65, 0.78, 0.86), vec3(0.85, 0.55, 0.52));
		vec3 w = walls[int(cc_hash(vec2(bx, 7.0)) * 40.0) % 4];
		w *= pick3(vec3(1.0), vec3(1.0, 0.78, 0.62), vec3(0.1, 0.11, 0.18));
		vec2 win = fract(vec2(uv.x * 9.0 * 3.0, y * 26.0));
		bool is_win = win.x > 0.3 && win.x < 0.7 && win.y > 0.3 && win.y < 0.7 && y < bh - 0.02;
		if (is_win) {
			float lit = step(0.45, cc_hash(floor(vec2(uv.x * 27.0, y * 26.0))));
			w = mix(w * 0.7, vec3(1.0, 0.8, 0.45), lit * night);
		}
		col = w;
	}
	// Azotea del vecino, cerca: piso de concreto, tanque de agua negro,
	// varillas que esperan el próximo piso y una cuerda con ropa.
	if (y < 0.13) {
		col = pick3(vec3(0.72, 0.68, 0.64), vec3(0.78, 0.6, 0.5), vec3(0.08, 0.08, 0.12));
		if (y > 0.115) col *= 0.8;
	}
	vec2 tank = (uv - vec2(0.22, 0.83)) / vec2(0.085, 0.07);
	if (abs(tank.x) < 1.0 && tank.y > -1.0 && tank.y < 1.0) {
		col = pick3(vec3(0.13, 0.14, 0.16), vec3(0.16, 0.12, 0.12), vec3(0.03, 0.03, 0.05));
		if (tank.y < -0.75) col *= 1.6;
		col += vec3(0.25) * smoothstep(0.6, 0.95, -tank.x) * (1.0 - night) * 0.4;
	}
	for (int i = 0; i < 4; i++) {
		float rx = 0.55 + float(i) * 0.05;
		if (abs(uv.x - rx) < 0.004 && y > 0.12 && y < 0.2) col = pick3(vec3(0.45, 0.28, 0.2), vec3(0.4, 0.22, 0.15), vec3(0.05));
	}
	float line_y = 0.25 - 0.04 * sin((uv.x - 0.32) / 0.6 * 3.14159);
	if (uv.x > 0.32 && uv.x < 0.92) {
		if (abs(y - line_y) < 0.003) col = vec3(0.25) * (1.0 - night * 0.8);
		float slot = fract(uv.x * 16.0);
		if (y < line_y && y > line_y - 0.06 && slot > 0.2 && slot < 0.75) {
			vec3 cloth[4] = vec3[4](vec3(0.9, 0.3, 0.3), vec3(0.98, 0.85, 0.3), vec3(0.3, 0.6, 0.9), vec3(0.95, 0.95, 0.92));
			col = cloth[int(floor(uv.x * 16.0)) % 4] * pick3(vec3(1.0), vec3(1.0, 0.8, 0.65), vec3(0.12));
		}
	}
	// Cables de luz cruzando.
	float c1 = 0.62 + 0.08 * (uv.x - 0.5) * (uv.x - 0.5) * 4.0 - uv.x * 0.12;
	float c2 = c1 - 0.035;
	if (abs(y - c1) < 0.0035 || abs(y - c2) < 0.003) col = pick3(vec3(0.15), vec3(0.15, 0.1, 0.1), vec3(0.01));
	// Buganvilla asomando por la izquierda.
	float bloom = cc_noise(uv * vec2(18.0, 14.0)) - length((uv - vec2(0.0, 0.62)) * vec2(1.1, 0.9)) * 2.4;
	if (bloom > -0.35) col = mix(pick3(vec3(0.82, 0.18, 0.5), vec3(0.85, 0.25, 0.45), vec3(0.1, 0.05, 0.1)), pick3(vec3(0.3, 0.5, 0.25), vec3(0.3, 0.35, 0.2), vec3(0.03, 0.05, 0.04)), step(0.7, cc_hash(floor(uv * 60.0))));
	// Bruma de la distancia y un toque de calor de la tarde.
	col = mix(col, sky_low, (1.0 - smoothstep(0.0, 0.3, abs(y - ridge))) * 0.15 * (1.0 - night));
	ALBEDO = cc_out(col);
}

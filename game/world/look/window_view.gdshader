// Lo que se ve por la ventana (biblia de arte §8.5): un barrio de una ciudad
// de valle inventada. Cielo con nubes, una cordillera azulada, un cerro verde
// con casitas de colores que trepan y una torre de iglesia, edificios bajos y,
// cerca, la azotea del vecino: tanque de agua negro sin marca, varillas "para
// el segundo piso", ropa tendida, una buganvilla magenta y un poste con
// cables enredados que cruzan la vista. De noche: estrellas, luna y ventanas
// encendidas.
//
// Va en un cuadro detrás del hueco, de frente a la cámara (ortográfica y fija).
// Cada fragmento se proyecta hacia atrás por la vista hasta la pared: lo que
// no cae en el hueco se descarta, así nada se asoma por encima de la pared.
// Con ese punto en la pared salen dos sistemas de coordenadas:
// - `far`: el de la pantalla (lo lejano: cielo, cordillera, cerro), con el
//   horizonte derecho;
// - `near`: el del hueco, de 0 a 1 de izquierda a derecha y de abajo arriba
//   (lo cercano: azotea, tanque, ropa, cables), paralelo a la pared como los
//   objetos del cuarto.
// `mood` = pesos (día, tarde, noche) que suman 1; lo pone DayCycle. Las nubes
// se mueven con cc_anim_time.
shader_type spatial;
render_mode unshaded, shadows_disabled, fog_disabled;

#include "res://game/world/look/look_globals.gdshaderinc"

uniform vec3 mood = vec3(1.0, 0.0, 0.0);
// Hacia dónde mira la cámara (la pone RoomShell desde CameraRig).
uniform vec3 view_dir = vec3(-0.6124, -0.5, -0.6124);

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec3 pick3(vec3 day, vec3 gold, vec3 night) {
	return day * mood.x + gold * mood.y + night * mood.z;
}

// Cobertura suave de una figura de distancia con signo `d` (< 0 adentro).
float cover(float d, float aa) {
	return 1.0 - smoothstep(-aa, aa, d);
}

float box_sd(vec2 p, vec2 c, vec2 h) {
	vec2 q = abs(p - c) - h;
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
}

float fbm(vec2 p) {
	return cc_noise(p) * 0.55 + cc_noise(p * 2.07 + 3.1) * 0.3 + cc_noise(p * 4.3 + 7.7) * 0.15;
}

void fragment() {
	vec4 r = cc_window_rect;
	float s = (cc_window_x - v_world.x) / -view_dir.x;
	vec3 on_wall = v_world - view_dir * s;
	if (on_wall.z < r.x - 0.01 || on_wall.z > r.y + 0.01 || on_wall.y < r.z - 0.01 || on_wall.y > r.w + 0.01) {
		discard;
	}
	vec3 right = normalize(cross(view_dir, vec3(0.0, 1.0, 0.0)));
	vec3 up = cross(right, view_dir);
	vec3 d = on_wall - vec3(cc_window_x, (r.z + r.w) * 0.5, (r.x + r.y) * 0.5);
	vec2 far = vec2(dot(d, right), dot(d, up)) / 1.2 + 0.5;
	vec2 near = vec2((r.y - on_wall.z) / (r.y - r.x), (on_wall.y - r.z) / (r.w - r.z));
	float fa = max(fwidth(far.y), 0.0005);
	float na = max(max(fwidth(near.x), fwidth(near.y)), 0.0005);
	float night = mood.z;
	vec3 dim = pick3(vec3(1.0), vec3(1.0, 0.8, 0.66), vec3(0.13, 0.14, 0.24));

	// Cielo de la mañana (abajo más claro), nubes y, de noche, estrellas y luna.
	vec3 sky_top = pick3(vec3(0.42, 0.65, 0.93), vec3(0.46, 0.38, 0.66), vec3(0.04, 0.06, 0.16));
	vec3 sky_low = pick3(vec3(0.84, 0.92, 0.98), vec3(1.0, 0.7, 0.45), vec3(0.13, 0.13, 0.3));
	vec3 col = mix(sky_low, sky_top, smoothstep(0.4, 1.0, far.y));
	float cloud = fbm(vec2(far.x * 3.0 + cc_anim_time * 0.004, far.y * 7.0));
	col = mix(col, pick3(vec3(1.0), vec3(1.0, 0.84, 0.72), vec3(0.2, 0.2, 0.32)), smoothstep(0.55, 0.7, cloud) * smoothstep(0.62, 0.8, far.y) * 0.85);
	col += vec3(0.85) * step(0.992, cc_hash(floor(far * vec2(140.0, 120.0)))) * night * smoothstep(0.6, 0.85, far.y);
	col = mix(col, vec3(0.95, 0.95, 0.85), cover(length(far - vec2(0.3, 0.86)) - 0.045, fa) * night);

	// Cordillera lejana, azulada por la distancia.
	float range_h = 0.6 + 0.05 * fbm(vec2(far.x * 3.0, 2.0)) - 0.04 * sin(far.x * 5.0 + 0.6);
	col = mix(col, pick3(vec3(0.6, 0.7, 0.84), vec3(0.62, 0.5, 0.62), vec3(0.09, 0.1, 0.2)), cover(far.y - range_h, fa));

	// Cerro verde con casitas de colores que trepan y la torre de la iglesia.
	float hill_h = 0.5 + 0.08 * sin(far.x * 4.2 + 2.2) + 0.02 * fbm(vec2(far.x * 9.0, 1.0));
	float on_hill = cover(far.y - hill_h, fa);
	col = mix(col, pick3(vec3(0.46, 0.66, 0.48), vec3(0.6, 0.5, 0.36), vec3(0.06, 0.1, 0.14)), on_hill);
	vec2 cell = far * vec2(46.0, 58.0);
	vec2 ci = floor(cell);
	vec2 cf = fract(cell);
	float pick = cc_hash(ci);
	float house = step(0.32, pick) * step(0.14, cf.x) * step(cf.x, 0.86) * step(0.2, cf.y) * step(far.y, hill_h - 0.015) * on_hill;
	vec3 hues[6] = vec3[6](vec3(0.97, 0.8, 0.62), vec3(0.94, 0.58, 0.5), vec3(0.99, 0.92, 0.72), vec3(0.66, 0.8, 0.92), vec3(0.88, 0.66, 0.84), vec3(0.8, 0.5, 0.38));
	col = mix(col, hues[int(pick * 60.0) % 6] * dim, house * 0.9);
	float lit_house = house * step(0.55, cc_hash(ci + 7.0)) * step(0.35, cf.x) * step(cf.x, 0.65) * step(0.45, cf.y) * step(cf.y, 0.75);
	col = mix(col, vec3(1.0, 0.82, 0.45), lit_house * night);
	vec2 tower_p = vec2(far.x - 0.74, far.y - (0.5 + 0.08 * sin(0.74 * 4.2 + 2.2)));
	float tower = min(box_sd(tower_p, vec2(0.0, 0.03), vec2(0.016, 0.05)), box_sd(tower_p, vec2(0.0, 0.09), vec2(0.01, 0.02)));
	col = mix(col, pick3(vec3(0.98, 0.96, 0.9), vec3(1.0, 0.86, 0.7), vec3(0.3, 0.3, 0.4)), cover(tower, fa));

	// Edificios bajos del medio (paralelos a la pared), con ventanas.
	float lot = floor(near.x * 5.0);
	float lot_pick = cc_hash(vec2(lot, 4.0));
	float roof_h = 0.36 + lot_pick * 0.16;
	float building = cover(near.y - roof_h, na);
	vec3 walls[5] = vec3[5](vec3(0.93, 0.7, 0.52), vec3(0.97, 0.88, 0.62), vec3(0.64, 0.79, 0.86), vec3(0.86, 0.56, 0.5), vec3(0.94, 0.92, 0.86));
	vec3 wall_col = walls[int(lot_pick * 50.0) % 5] * dim;
	vec2 win = fract(vec2(near.x * 15.0, near.y * 14.0));
	float window = step(0.3, win.x) * step(win.x, 0.7) * step(0.3, win.y) * step(win.y, 0.72) * step(near.y, roof_h - 0.04);
	float window_lit = step(0.5, cc_hash(floor(vec2(near.x * 15.0, near.y * 14.0)) + 3.0));
	wall_col = mix(wall_col, mix(vec3(0.34, 0.42, 0.52) * dim, vec3(1.0, 0.8, 0.45), window_lit * night), window);
	col = mix(col, wall_col, building);
	col = mix(col, pick3(vec3(0.82, 0.78, 0.72), vec3(0.85, 0.66, 0.54), vec3(0.12, 0.12, 0.18)), building * cover(abs(near.y - roof_h + 0.012) - 0.012, na));

	// Azotea del vecino: losa de concreto y pretil.
	float roof = cover(near.y - 0.2, na);
	col = mix(col, pick3(vec3(0.74, 0.7, 0.66), vec3(0.8, 0.62, 0.52), vec3(0.08, 0.08, 0.12)), roof);
	col = mix(col, pick3(vec3(0.86, 0.82, 0.76), vec3(0.9, 0.72, 0.6), vec3(0.12, 0.12, 0.16)), cover(abs(near.y - 0.19) - 0.02, na));
	// Tanque de agua negro (sin marca), con su tapa.
	float tank = box_sd(near, vec2(0.34, 0.33), vec2(0.075, 0.12)) - 0.03;
	tank = min(tank, box_sd(near, vec2(0.34, 0.47), vec2(0.045, 0.012)) - 0.01);
	vec3 tank_col = pick3(vec3(0.14, 0.15, 0.18), vec3(0.17, 0.13, 0.13), vec3(0.03, 0.03, 0.05));
	tank_col += vec3(0.12) * smoothstep(0.31, 0.27, near.x) * (1.0 - night);
	col = mix(col, tank_col, cover(tank, na));
	// Varillas que esperan el segundo piso, con la punta doblada.
	for (int i = 0; i < 4; i++) {
		float x = 0.62 + float(i) * 0.045;
		float rod = min(box_sd(near, vec2(x, 0.3), vec2(0.004, 0.1)), box_sd(near, vec2(x + 0.012, 0.4), vec2(0.014, 0.004)));
		col = mix(col, pick3(vec3(0.5, 0.3, 0.22), vec3(0.45, 0.25, 0.18), vec3(0.06, 0.04, 0.04)), cover(rod, na));
	}
	// Cuerda con ropa tendida.
	float line_y = 0.52 - 0.05 * sin((near.x - 0.42) / 0.2 * 3.14159);
	if (near.x > 0.42 && near.x < 0.62) {
		col = mix(col, vec3(0.26, 0.25, 0.28) * dim, cover(abs(near.y - line_y) - 0.004, na));
		float slot = fract((near.x - 0.42) * 25.0);
		float piece = floor((near.x - 0.42) * 25.0);
		vec3 cloth[4] = vec3[4](vec3(0.92, 0.32, 0.32), vec3(0.98, 0.86, 0.32), vec3(0.32, 0.6, 0.92), vec3(0.96, 0.96, 0.93));
		float hang = step(0.15, slot) * step(slot, 0.85) * step(near.y, line_y) * step(line_y - 0.07 - 0.03 * cc_hash(vec2(piece, 2.0)), near.y);
		col = mix(col, cloth[int(piece) % 4] * dim, hang);
	}
	// Buganvilla magenta que cae por la izquierda.
	float bloom = fbm(near * vec2(9.0, 7.0)) - length((near - vec2(0.0, 0.45)) * vec2(1.6, 0.9)) * 1.4;
	float bloom_mask = smoothstep(-0.12, -0.08, bloom);
	vec3 bloom_col = mix(pick3(vec3(0.84, 0.2, 0.52), vec3(0.86, 0.26, 0.46), vec3(0.12, 0.05, 0.1)), pick3(vec3(0.3, 0.52, 0.26), vec3(0.32, 0.36, 0.2), vec3(0.03, 0.05, 0.04)), step(0.72, cc_hash(floor(near * 70.0))));
	col = mix(col, bloom_col, bloom_mask);
	// Poste de luz y cables enredados que cruzan la vista.
	col = mix(col, pick3(vec3(0.42, 0.4, 0.42), vec3(0.4, 0.34, 0.34), vec3(0.06, 0.06, 0.08)), cover(box_sd(near, vec2(0.86, 0.5), vec2(0.012, 0.6)), na));
	vec3 wire = pick3(vec3(0.16, 0.16, 0.19), vec3(0.16, 0.12, 0.12), vec3(0.02, 0.02, 0.03));
	for (int k = 0; k < 4; k++) {
		float fk = float(k);
		float t = (near.x - 0.86) / 0.86;
		float sag = 0.9 - fk * 0.035 + (0.06 + fk * 0.015) * t * t - 0.05 * t;
		sag += 0.008 * sin(near.x * 31.0 + fk * 2.0) * step(near.x, 0.5);
		col = mix(col, wire, cover(abs(near.y - sag) - 0.004, na));
	}
	// Bruma clara hacia el horizonte (de día).
	col = mix(col, sky_low, (1.0 - smoothstep(0.0, 0.14, abs(far.y - hill_h))) * 0.1 * (1.0 - night));
	ALBEDO = cc_out(col);
}

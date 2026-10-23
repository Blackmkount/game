// La pantallita de las impresoras (y seg(), que usa también el monitor):
// la comparten screen.gdshader (cada "Display") y display_field.gdshader
// (todas las pantallitas con el zoom lejos, en un MultiMesh). Necesita
// look_globals.gdshaderinc antes (cc_anim_time).

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

// Pantallita de la impresora: 2 libre, 3 imprimiendo (barra que avanza),
// 4 lista (visto), 5 falla (signo de admiración).
vec3 display(vec2 uv, int state) {
	vec2 px = floor(uv * vec2(24.0, 14.0)) / vec2(24.0, 14.0);
	vec3 ink = vec3(0.85, 0.97, 1.0);
	vec3 col = state == 2 ? vec3(0.12, 0.32, 0.75) : state == 3 ? vec3(0.07, 0.45, 0.6) : state == 4 ? vec3(0.13, 0.55, 0.3) : vec3(0.72, 0.18, 0.2);
	if (state == 2) {
		if (px.y > 0.25 && px.y < 0.35 && px.x > 0.12 && px.x < 0.75) {
			col = ink;
		}
		if (px.y > 0.55 && px.y < 0.65 && px.x > 0.12 && px.x < 0.5) {
			col = ink;
		}
	} else if (state == 3) {
		float progress = fract(cc_anim_time * 0.15);
		if (px.y > 0.2 && px.y < 0.36 && px.x > 0.1 && px.x < 0.9) {
			col = px.x < 0.1 + 0.8 * progress ? vec3(0.35, 0.95, 1.0) : vec3(0.04, 0.25, 0.35);
		}
		if (px.y > 0.55 && px.y < 0.65 && px.x > 0.1 && px.x < 0.6) {
			col = ink;
		}
	} else if (state == 4) {
		float d = min(seg(uv, vec2(0.3, 0.5), vec2(0.45, 0.72)), seg(uv, vec2(0.45, 0.72), vec2(0.72, 0.25)));
		col = mix(col, ink, 1.0 - smoothstep(0.04, 0.08, d));
	} else {
		if (abs(px.x - 0.5) < 0.06 && ((px.y > 0.18 && px.y < 0.6) || (px.y > 0.7 && px.y < 0.82))) {
			col = ink;
		}
	}
	return col * 1.15;
}

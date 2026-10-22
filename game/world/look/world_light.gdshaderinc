// La luz del mundo que no es el sol del motor (biblia de arte §3.4–3.5 y
// §6): ambiente de dos colores, relleno desde el lado de la cámara, cuatro
// luces del sombreador, la tira LED, el parche de sol que entra por la
// ventana (con rejas y lo que lo tapa) y la oclusión (rincones, mapa del
// piso y mancha del personaje).
//
// Todo se calcula aquí: cero luces extra del motor y cero llamadas de dibujo
// extra. Los valores son globales (ver look_globals.gdshaderinc).

#ifndef WORLD_LIGHT
#define WORLD_LIGHT

#include "res://game/world/look/look_globals.gdshaderinc"

// Mapa de oclusión del piso (96 × 96, lo pinta FloorAO una vez por
// distribución). Sin mapa, el motor da blanco: nada se oscurece.
global uniform sampler2D cc_floor_ao : filter_linear, repeat_disable;

// La oclusión se tiñe hacia índigo (#c7ccff), nunca gris.
const vec3 CC_AO_TINT = vec3(0.7804, 0.8, 1.0);
// Envoltura de las luces del sombreador.
const float CC_POINT_WRAP = 0.3;
// El parche de la ventana tapado por un mueble o el personaje queda a este
// tanto.
const float CC_PATCH_BLOCKED = 0.15;
// Cápsula del personaje que tapa el parche: radio y alto (m).
const float CC_CHAR_RADIUS = 0.22;
const float CC_CHAR_HEIGHT = 1.4;
// Uniones piso-pared y rincón: hasta -40 % dentro de 0,35 m.
const float CC_SEAM_REACH = 0.35;
const float CC_SEAM_DARK = 0.4;
// Mancha del personaje: -50 %.
const float CC_CHAR_DARK = 0.5;

vec3 cc_ao_color(float ao) {
	return mix(vec3(1.0), CC_AO_TINT, 1.0 - ao) * ao;
}

// Luz puntual sin sombra: caída cuadrática hasta su alcance y envoltura.
vec3 cc_point(vec3 p, vec3 n, vec4 pos_range, vec4 color) {
	if (pos_range.w <= 0.0) {
		return vec3(0.0);
	}
	vec3 d = pos_range.xyz - p;
	float dist = length(d);
	float att = clamp(1.0 - dist / pos_range.w, 0.0, 1.0);
	att *= att;
	float ndl = clamp((dot(n, d / max(dist, 0.0001)) + CC_POINT_WRAP) / (1.0 + CC_POINT_WRAP), 0.0, 1.0);
	return color.rgb * att * ndl;
}

// Tira de luz (segmento): lava la pared de arriba hacia abajo.
vec3 cc_strip(vec3 p, vec3 n) {
	if (cc_strip_col.w <= 0.0) {
		return vec3(0.0);
	}
	vec3 ab = cc_strip_b - cc_strip_a;
	float t = clamp(dot(p - cc_strip_a, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
	return cc_point(p, n, vec4(cc_strip_a + ab * t, cc_strip_col.w), cc_strip_col);
}

// ¿El rayo o + d·t (0 < t < t_max) atraviesa la caja de centro c y medias
// medidas h? Una caja con h.x = 0 no existe.
bool cc_ray_hits_box(vec3 o, vec3 d, vec3 c, vec3 h, float t_max) {
	if (h.x <= 0.0) {
		return false;
	}
	vec3 safe = mix(d, vec3(0.00001), vec3(lessThan(abs(d), vec3(0.00001))));
	vec3 t0 = (c - h - o) / safe;
	vec3 t1 = (c + h - o) / safe;
	vec3 near_t = min(t0, t1);
	vec3 far_t = max(t0, t1);
	float enter = max(max(near_t.x, near_t.y), max(near_t.z, 0.0));
	float leave = min(min(far_t.x, far_t.y), min(far_t.z, t_max));
	return leave > enter;
}

// ¿El rayo atraviesa al personaje (una cápsula parada sobre cc_char_pos)?
// Lo que está dentro de la cápsula (él mismo y el piso bajo sus pies) no se
// tapa a sí mismo.
bool cc_ray_hits_character(vec3 o, vec3 d, float t_max) {
	if (cc_char_pos.w <= 0.0 || length(o.xz - cc_char_pos.xz) < CC_CHAR_RADIUS + 0.03) {
		return false;
	}
	vec2 dir = d.xz;
	float len2 = dot(dir, dir);
	if (len2 < 0.000001) {
		return false;
	}
	float t = clamp(dot(cc_char_pos.xz - o.xz, dir) / len2, 0.0, t_max);
	vec3 q = o + d * t;
	return length(q.xz - cc_char_pos.xz) < CC_CHAR_RADIUS
		&& q.y > cc_char_pos.y && q.y < cc_char_pos.y + CC_CHAR_HEIGHT;
}

// Parche de sol de la ventana: se sigue el rayo desde el punto hacia la luz
// hasta el plano de la pared. Si pasa por el hueco y no por una reja, el
// punto queda iluminado; la penumbra crece con la distancia. Si en el camino
// hay un mueble o el personaje, queda casi apagado.
float cc_window_patch(vec3 p, vec3 n) {
	vec3 to_light = -cc_window_dir;
	if (to_light.x > -0.01) {
		return 0.0;
	}
	float ndl = dot(n, to_light);
	if (ndl <= 0.0) {
		return 0.0;
	}
	float t = (cc_window_x - p.x) / to_light.x;
	if (t < 0.03) {
		return 0.0;
	}
	vec3 hit = p + to_light * t;
	float soft = 0.004 + t * 0.012;
	vec4 r = cc_window_rect;
	// Casi todos los puntos salen aquí, antes de probar rejas y cajas.
	if (hit.z < r.x - soft || hit.z > r.y + soft || hit.y < r.z - soft || hit.y > r.w + soft) {
		return 0.0;
	}
	float inside = smoothstep(r.x - soft, r.x + soft, hit.z)
		* (1.0 - smoothstep(r.y - soft, r.y + soft, hit.z))
		* smoothstep(r.z - soft, r.z + soft, hit.y)
		* (1.0 - smoothstep(r.w - soft, r.w + soft, hit.y));
	vec4 bars = cc_window_bars;
	float light = inside;
	if (bars.x > 0.0) {
		// Rejas verticales (a media separación de los bordes del hueco), el
		// travesaño y el parante central de la ventana corrediza.
		float bar_z = abs(fract((hit.z - r.x) / bars.x) - 0.5) * bars.x;
		light *= smoothstep(bars.y, bars.y + soft, bar_z);
		light *= smoothstep(bars.y, bars.y + soft, abs(hit.y - bars.z));
		light *= smoothstep(bars.w, bars.w + soft, abs(hit.z - (r.x + r.y) * 0.5));
	}
	if (light <= 0.0) {
		return 0.0;
	}
	if (cc_ray_hits_box(p, to_light, cc_occ_a_c.xyz, cc_occ_a_h.xyz, t)
			|| cc_ray_hits_box(p, to_light, cc_occ_b_c.xyz, cc_occ_b_h.xyz, t)
			|| cc_ray_hits_character(p, to_light, t)) {
		light *= CC_PATCH_BLOCKED;
	}
	return light * ndl;
}

// Oclusión falsa: uniones piso-pared y el rincón, el mapa del piso (manchas
// bajo los muebles) y la mancha bajo el personaje. 1 = nada.
float cc_occlusion(vec3 p, vec3 n) {
	float dx = p.x - cc_room.x;
	float dz = p.z - cc_room.y;
	float ao = 1.0;
	if (dx > -0.02 && dz > -0.02 && p.y > -0.02) {
		float near_x = 1.0 - smoothstep(0.0, CC_SEAM_REACH, dx);
		float near_z = 1.0 - smoothstep(0.0, CC_SEAM_REACH, dz);
		float near_floor = 1.0 - smoothstep(0.0, CC_SEAM_REACH, p.y);
		float seam = max(max(near_x * near_floor, near_z * near_floor), near_x * near_z);
		ao = 1.0 - CC_SEAM_DARK * seam;
	}
	if (p.y < 0.03 && n.y > 0.7) {
		vec2 uv = (p.xz - cc_room.xy) / cc_room.z;
		if (uv.x > 0.0 && uv.y > 0.0 && uv.x < 1.0 && uv.y < 1.0) {
			ao *= texture(cc_floor_ao, uv).r;
		}
		if (cc_char_pos.w > 0.0) {
			float d = length(p.xz - cc_char_pos.xz);
			ao *= 1.0 - CC_CHAR_DARK * (1.0 - smoothstep(cc_char_pos.w * 0.3, cc_char_pos.w, d));
		}
	}
	return ao;
}

// Todo lo que suma la pasada base, por unidad de color del objeto. `ao`:
// oclusión (horneada × la de cc_occlusion). `fill_boost`: 1 para el
// personaje (más relleno, nunca a contraluz), 0 para lo demás.
vec3 cc_world_light(vec3 p, vec3 n, float ao, float fill_boost) {
	vec3 ao_color = cc_ao_color(ao);
	vec3 ambient = mix(cc_amb_ground, cc_amb_sky, clamp(n.y * 0.5 + 0.5, 0.0, 1.0));
	float f = clamp(dot(n, normalize(cc_fill_dir)) * 0.6 + 0.4, 0.0, 1.0);
	float fill_peak = max(max(cc_fill.r, cc_fill.g), max(cc_fill.b, 0.001));
	vec3 fill = (cc_fill.rgb + cc_fill.rgb / fill_peak * cc_fill.w * fill_boost) * f * f;
	vec3 lights = cc_point(p, n, cc_pl0, cc_pl0_col) + cc_point(p, n, cc_pl1, cc_pl1_col)
		+ cc_point(p, n, cc_pl2, cc_pl2_col) + cc_point(p, n, cc_pl3, cc_pl3_col)
		+ cc_strip(p, n) + cc_window_color * cc_window_patch(p, n);
	return (ambient + fill) * ao_color + lights * mix(vec3(1.0), ao_color, 0.5);
}

#endif

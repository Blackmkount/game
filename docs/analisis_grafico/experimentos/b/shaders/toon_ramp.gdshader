// Experimento 1: sombreado toon con rampa de color propia (función light()).
// - Luz direccional: el valor N·L × sombra elige un color de una rampa de
//   3 bandas (frío en sombra, neutro, cálido en luz). La rampa es una
//   GradientTexture1D con interpolación CONSTANT: editable en el inspector.
// - Luces locales (omni): se suman en escalones (bandas) en vez de degradado.
// - Textura pixel art proyectada por el eje dominante de la normal (barato).
// - Oclusión ambiental opcional desde el color de vértice, en bandas con
//   tramado (dither) Bayer 4x4 para que se vea pixel art.
shader_type spatial;
render_mode specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable;
uniform bool use_texture = false;
uniform float tex_scale = 1.0;
uniform sampler2D ramp : source_color, filter_nearest, repeat_disable;
uniform float ramp_energy = 1.0;
uniform float point_steps = 3.0;
uniform bool use_vertex_ao = false;
uniform float ao_steps = 3.0;
uniform vec3 ao_tint : source_color = vec3(0.42, 0.33, 0.52);
uniform int debug_mode = 0;
// 0 = rampa desde textura, 1 = rampa con 3 colores uniformes.
uniform int ramp_source = 0;
uniform vec3 band_shadow : source_color = vec3(0.243, 0.204, 0.471);
uniform vec3 band_mid : source_color = vec3(0.659, 0.51, 0.565);
uniform vec3 band_lit : source_color = vec3(1.0, 0.886, 0.753);
uniform float band_low = 0.18;
uniform float band_high = 0.5;

vec3 ramp_color(float lit) {
	if (ramp_source == 1) {
		return lit < band_low ? band_shadow : (lit < band_high ? band_mid : band_lit);
	}
	return texture(ramp, vec2(clamp(lit, 0.01, 0.99), 0.5)).rgb;
}

varying vec3 v_world;
varying vec3 v_world_normal;

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	const float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[x + y * 4] + 0.5) / 16.0;
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 color = albedo.rgb;
	if (use_texture) {
		vec3 n = abs(v_world_normal);
		vec2 uv;
		if (n.y >= n.x && n.y >= n.z) {
			uv = v_world.xz;
		} else if (n.x >= n.z) {
			uv = vec2(v_world.z, -v_world.y);
		} else {
			uv = vec2(v_world.x, -v_world.y);
		}
		color *= texture(albedo_tex, uv * tex_scale).rgb;
	}
	if (use_vertex_ao) {
		float occlusion = 1.0 - COLOR.r;
		float level = floor(occlusion * ao_steps + bayer4(FRAGCOORD.xy)) / ao_steps;
		color *= mix(vec3(1.0), ao_tint, clamp(level, 0.0, 1.0));
	}
	ALBEDO = color;
}

void light() {
	float ndl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	if (debug_mode == 1 && LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += vec3(ATTENUATION);
	} else if (debug_mode == 2 && LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += vec3(ndl);
	} else if (debug_mode == 4 && LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += vec3(clamp(ndl * ATTENUATION, 0.01, 0.99));
	} else if (debug_mode == 5 && LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += ramp_color(0.0);
	} else if (debug_mode == 6 && LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += vec3(0.1);
	} else if (debug_mode == 3 && LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += texture(ramp, vec2(clamp(ndl * ATTENUATION, 0.01, 0.99), 0.5)).rgb;
	} else if (LIGHT_IS_DIRECTIONAL) {
		float lit = ndl * ATTENUATION;
		vec3 band = ramp_color(lit);
		// LIGHT_COLOR llega multiplicado por PI (convención física de Godot).
		DIFFUSE_LIGHT += band * LIGHT_COLOR / PI * ramp_energy;
	} else {
		float lit = ndl * ATTENUATION;
		lit = floor(lit * point_steps + 0.5) / point_steps;
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * lit;
	}
}

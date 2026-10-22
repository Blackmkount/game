// Lo que dibuja ColorProbe (color_probe.gd) para medir el modelo de color:
// escribe valores crudos por las mismas salidas que el kit (EMISSION en la
// pasada base y SPECULAR_LIGHT en la del sol), sin cc_out() ni cc_sun_out().
shader_type spatial;
render_mode ambient_light_disabled;

// Lo que suma la pasada base y lo que suma el sol (sin sombra encima).
uniform float base_level = 0.0;
uniform float sun_level = 0.0;

void fragment() {
	ALBEDO = vec3(0.0);
	ROUGHNESS = 1.0;
	EMISSION = vec3(base_level);
}

void light() {
	SPECULAR_LIGHT += vec3(sun_level) * step(0.5, ATTENUATION);
}

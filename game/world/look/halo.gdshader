// Halo de luz falso (en vez del "glow" del entorno, que en Compatibility
// cuesta el doble y cuadruplica el fondo): un cuadrado que mira a la cámara y
// SUMA luz con un degradé redondo, o de cápsula si `aspect` > 1 (la tira LED).
// Pensado para un MultiMesh (los destellos de "pieza lista", los halos de la
// noche): `intensity` es del material, no de cada instancia (un "instance
// uniform" ocupa lugares del búfer de globales por cada instancia, ver
// kit_body.gdshaderinc).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://game/world/look/look_globals.gdshaderinc"

uniform vec4 color = vec4(1.0, 0.7, 0.36, 1.0);
uniform float falloff = 2.2;
// Ancho / alto del cuadrado.
uniform float aspect = 1.0;
uniform float intensity = 1.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	p.x = max(abs(p.x * aspect) - (aspect - 1.0), 0.0);
	float a = pow(clamp(1.0 - length(p), 0.0, 1.0), falloff);
	ALBEDO = cc_out(color.rgb * a * intensity);
}

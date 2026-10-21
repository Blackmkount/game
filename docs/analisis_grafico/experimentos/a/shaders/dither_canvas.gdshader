// EXP 3b: lo mismo, pero como material del SubViewportContainer (2D).
// No necesita copiar la pantalla y ve todo (transparentes y glow incluidos).
shader_type canvas_item;

#include "res://shaders/palette_dither.gdshaderinc"

void fragment() {
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	ivec2 pixel = ivec2(floor(UV * size));
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(palette_dither(c.rgb, pixel), c.a);
}

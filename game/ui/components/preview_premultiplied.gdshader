// Pone la vista de un modelo (ModelPreview) sobre la tarjeta. Lo que dibuja
// un SubViewport transparente con MSAA viene premultiplicado: el borde
// suavizado ya trae su alfa en el color. Mezclarlo como siempre lo volvía a
// multiplicar por el alfa y dejaba un borde oscuro alrededor del modelo. Se
// suma premultiplicado y el alfa de quien lo contiene (un panel que aparece
// o se va) se aplica también al color.
shader_type canvas_item;
render_mode blend_premul_alpha;

// El color de la vista con el de quienes la contienen (modulate).
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 drawn = texture(TEXTURE, UV);
	COLOR = vec4(drawn.rgb * tint.rgb * tint.a, drawn.a * tint.a);
}

// Contorno oscuro de estilo pixel art (técnica "inverted hull"): se dibuja
// la cara trasera del objeto un poco agrandada y de un solo color. Funciona
// con las formas básicas centradas en su origen (cajas, cilindros, esferas).
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;

uniform vec4 outline_color : source_color = vec4(0.102, 0.075, 0.125, 1.0);
uniform float thickness = 0.02;

void vertex() {
	VERTEX += sign(VERTEX) * thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}

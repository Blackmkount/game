// La pieza mientras se imprime: plástico impreso de un color (como
// kit_tinted.gdshader) con la capa caliente arriba (instance uniform
// hot_top, ver kit_body.gdshaderinc). Solo la usan las piezas que crecen.
shader_type spatial;
render_mode ambient_light_disabled;

#define KIT_TINTED
#define HOT_LAYER
#include "res://game/world/look/kit_body.gdshaderinc"

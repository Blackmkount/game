// Plástico transparente de un color (como kit_tinted.gdshader), visto de los
// dos lados: la tapa ámbar de la impresora de resina. Va en la pasada
// transparente y no da sombra (WorldPalette.glass).
shader_type spatial;
render_mode ambient_light_disabled, blend_mix, cull_disabled, depth_draw_never;

#define KIT_TINTED
#define KIT_GLASS
#include "res://game/world/look/kit_body.gdshaderinc"

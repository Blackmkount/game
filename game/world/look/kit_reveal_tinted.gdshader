// Igual que kit_reveal.gdshader, para los materiales de un color por
// uniform (kit_tinted.gdshader): el filamento del carrete, la luz de adentro
// de las impresoras cerradas, la resina.
shader_type spatial;
render_mode ambient_light_disabled, cull_disabled;

#define KIT_TINTED
#define REVEAL
#include "res://game/world/look/kit_body.gdshaderinc"

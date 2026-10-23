// Igual que kit.gdshader, con el color, la superficie, el brillo, las capas y
// la luz propia por uniform (WorldPalette.solid, paint, textured y glow).
shader_type spatial;
render_mode ambient_light_disabled;

#define KIT_TINTED
#include "res://game/world/look/kit_body.gdshaderinc"

// El cuerpo del personaje (biblia de arte §3.1): el kit con color por
// vértice (una malla con piel), terminador más marcado y luz de borde (los
// pone WorldPalette.kit_character), más relleno de cámara para que nunca
// quede a contraluz, y luz de estudio en los retratos (preview_light).
shader_type spatial;
render_mode ambient_light_disabled;

#define KIT_CHARACTER
#include "res://game/world/look/kit_body.gdshaderinc"

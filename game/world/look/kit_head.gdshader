// La cabeza del personaje (biblia de arte §7.5): kit_character con la cara
// pintada (FacePainter) proyectada alrededor de la cabeza, la expresión y
// hacia dónde miran las pupilas (instance uniform expression y gaze). El
// pelo va en la misma malla y no recibe la cara.
shader_type spatial;
render_mode ambient_light_disabled;

#define KIT_CHARACTER
#define KIT_HEAD
#include "res://game/world/look/kit_body.gdshaderinc"

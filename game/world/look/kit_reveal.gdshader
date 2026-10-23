// Lo que se compra mientras aparece en su lugar imprimiéndose (biblia de
// arte §12.2, PrintIn): kit.gdshader cortado en reveal_y, con la línea
// caliente del corte, el relleno visible por dentro (por eso dibuja las dos
// caras) y encima solo las capas que faltan, en cian. Solo se usa mientras
// dura el efecto: el material de siempre no paga el discard ni el
// instance uniform (ver kit_body.gdshaderinc).
shader_type spatial;
render_mode ambient_light_disabled, cull_disabled;

#define REVEAL
#include "res://game/world/look/kit_body.gdshaderinc"

// Las pantallitas de las impresoras con el zoom lejos (DisplayField): un
// MultiMesh de cuadros, cada uno dibujado igual que su "Display"
// (printer_display.gdshaderinc). El estado de cada copia llega en COLOR.r
// (MultiMesh.use_colors): (modo - 2 + 0,5) / 4, con el modo de
// screen.gdshader (2 libre, 3 imprimiendo, 4 lista, 5 falla).
shader_type spatial;
render_mode unshaded, shadows_disabled, fog_disabled;

#include "res://game/world/look/look_globals.gdshaderinc"
#include "res://game/world/look/printer_display.gdshaderinc"

void fragment() {
	int state = 2 + clamp(int(COLOR.r * 4.0), 0, 3);
	ALBEDO = cc_out(display(UV, state));
}

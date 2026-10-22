class_name ClientStyle
extends RefCounted
## Color de cada tipo de cliente en la interfaz: el cuadro con su avatar en
## las tarjetas de Pedidos. Es solo presentación, no balance: los clientes
## siguen viviendo en data/clients.json.

const COLORS: Dictionary[String, Color] = {
	"amigos": Color("4fdc7a"),
	"vecinos": Color("f5b82e"),
	"tiendas": Color("38d6ff"),
	"makers": Color("9b5de5"),
	"cosplayers": Color("f28c28"),
	"talleres": Color("8a8f9c"),
}


## Color del cliente, o el del texto apagado si todavía no tiene uno.
static func color(client_id: String) -> Color:
	if COLORS.has(client_id):
		return COLORS[client_id]
	return UiPalette.TEXT_MUTED

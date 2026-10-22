extends GutTest
## Cada cliente de data/clients.json tiene su color en las tarjetas de Pedidos.


func test_every_client_has_its_own_color() -> void:
	var catalog: DataCatalog = DataCatalog.load_from()
	var colors: Array[Color] = []
	for client: Dictionary in catalog.files["clients"]:
		assert_true(ClientStyle.COLORS.has(client["id"]), "Falta el color de " + String(client["id"]))
		colors.append(ClientStyle.color(client["id"]))
	for index: int in colors.size():
		assert_eq(colors.count(colors[index]), 1, "Dos clientes con el mismo color")


func test_an_unknown_client_uses_the_muted_text_color() -> void:
	assert_eq(ClientStyle.color("nadie"), UiPalette.TEXT_MUTED)

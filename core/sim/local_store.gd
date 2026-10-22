class_name LocalStore
extends RefCounted
## Ferretería del barrio (GDD 5.6): vende un carrete de PLA o PETG que se
## lleva al instante, más caro que la tienda. Es la salida de emergencia
## cuando el material no alcanza para ningún pedido.
##
## check_buy es la misma revisión que hace el comando, así la interfaz puede
## deshabilitar el botón con el motivo exacto. Comprar no usa el azar.


## Revisa, en este orden (el primer problema gana): que la ferretería venda
## ese material, que alcance el dinero y que el carrete quepa en el
## almacenamiento.
static func check_buy(state: GameState, rules: SimRules, material_id: String) -> CommandResult:
	if not rules.local_store_cents.has(material_id):
		return CommandResult.fail("ERR_NOT_IN_LOCAL_STORE")
	var price: int = rules.local_store_cents[material_id]
	if state.money_cents < price:
		return CommandResult.fail("ERR_NO_MONEY", [CommandResult.cents_arg(price)])
	var capacity: int = WorkshopRules.storage_capacity_grams(state, rules)
	if state.total_grams() + rules.local_store_grams > capacity:
		return CommandResult.fail("ERR_NO_STORAGE", [CommandResult.grams_arg(capacity)])
	return CommandResult.success()


## Paga y agrega el carrete nuevo al final de la lista, con un uid nuevo.
## Llamar solo después de check_buy.
static func buy(sim: Simulation, material_id: String) -> Spool:
	var state: GameState = sim.state
	var rules: SimRules = sim.rules
	state.money_cents -= rules.local_store_cents[material_id]
	var spool: Spool = Spool.new(state.take_uid(), material_id, rules.local_store_color, rules.local_store_grams)
	state.spools.append(spool)
	sim.changes.spools = true
	sim.changes.money = true
	return spool

class_name LocalStoreButtons
extends VBoxContainer
## Botones de la ferretería del barrio: uno por material que vende, con el
## peso del carrete y su precio ("PLA · 1.000 g · $27"). Se usa en la línea de
## arriba de Pedidos (cuando nadie pide algo que se pueda hacer) y en
## Inventario.
##
## Un botón que no se puede usar queda deshabilitado con el motivo debajo
## (LocalStore.check_buy, la misma revisión que hace el comando).

## Se tocó comprar un carrete de ese material.
signal buy_requested(material_id: String)

const BUTTON_HEIGHT: float = 88.0


## "Ferretería: al instante, 50% más cara".
static func title(rules: SimRules) -> String:
	var percent: int = roundi((rules.local_store_price_multiplier - 1.0) * 100.0)
	return UiFormat.tr_format("LOCAL_STORE_TITLE", [percent])


func _init() -> void:
	name = "LocalStore"
	add_theme_constant_override("separation", 8)


func _ready() -> void:
	var state: GameState = Game.state
	var rules: SimRules = Game.rules
	var flow: HFlowContainer = HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	add_child(flow)
	# Motivos distintos de los botones deshabilitados, sin repetir.
	var notes: Array[String] = []
	for material_id: String in rules.local_store_cents:
		var button: Button = _button(rules, material_id)
		flow.add_child(button)
		var check: CommandResult = LocalStore.check_buy(state, rules, material_id)
		if check.ok:
			continue
		button.disabled = true
		var note: String = UiFormat.reason(check, rules.game_seconds_per_real_second)
		if not notes.has(note):
			notes.append(note)
	if not notes.is_empty():
		var label: Label = UiKit.label("\n".join(notes), "MutedLabel", true)
		label.name = "BuyLocalNote"
		add_child(label)


func _button(rules: SimRules, material_id: String) -> Button:
	var button: Button = Button.new()
	button.name = "BuyLocal_" + material_id
	button.text = UiFormat.tr_format("LOCAL_STORE_BUY", [
		tr(rules.materials[material_id]["name_key"]),
		UiFormat.grams(rules.local_store_grams),
		UiFormat.money(rules.local_store_cents[material_id]),
	])
	button.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: buy_requested.emit(material_id))
	return button

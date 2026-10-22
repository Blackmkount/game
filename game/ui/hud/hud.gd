class_name Hud
extends Control
## Interfaz principal sobre la habitación, con el estilo de la imagen de
## referencia: tarjeta del personaje con nivel y experiencia, dinero y fecha
## arriba; objetivos a la derecha; accesos rápidos a la izquierda; barra de
## secciones abajo. Las secciones se abren como pantallas sobre la habitación.
##
## También muestra lo que acompaña a los controles del mundo (WorldControls):
## el panel inferior de un objeto, el joystick, las burbujas de estado, la
## burbuja sobre el objeto cercano, el globo de diálogo, la pista para
## jugadores nuevos y el botón de zoom. Arriba de todo, la capa de
## celebraciones (FeedbackLayer).
##
## Se actualiza con las señales de Events: el dinero, la experiencia, los
## objetivos y el número de "Pedidos" cambian apenas cambia la partida.

## Se cerró el panel inferior del objeto.
signal sheet_closed
## Se abrió una sección, o se volvió a la habitación ("home").
signal screen_changed(screen_id: String)
signal zoom_pressed
## Botón de un panel inferior que no abre una sección (imprimir, retirar,
## embalar...): lo maneja el ciclo de pedidos.
signal sheet_command(action_id: String)
## Botón de una tarjeta de la pantalla de pedidos (aceptar, imprimir...).
signal order_card_action(verb: String, uid: int)
## Comprar un carrete en la ferretería (desde Pedidos o Inventario).
signal local_store_requested(material_id: String)

const MARGIN: float = 16.0
const TOP: float = 20.0
const CONTENT_TOP: float = 150.0
const NAV_HEIGHT: float = 116.0
const ZOOM_BUTTON_SIZE: Vector2 = Vector2(96, 104)
const ZOOM_LABELS: Array[String] = ["ZOOM_FAR", "ZOOM_NORMAL", "ZOOM_NEAR"]
## Espacio libre entre el globo de diálogo y la burbuja de cercanía.
const SPEECH_GAP: float = 8.0
## Si el globo se corre hacia un costado, la cabeza tiene que quedar al menos
## así de adentro de su borde.
const SPEECH_HEAD_MARGIN: float = 24.0
## Pantalla (y opción) que abre cada botón de un panel inferior.
const ACTION_SCREENS: Dictionary[String, Array] = {
	"orders": ["orders", ""],
	"shop_furniture": ["shop", "furniture"],
	"inventory": ["inventory", ""],
	"map": ["map", ""],
}

var joystick: JoystickRing
var status_bubbles: StatusBubbles
var bubble: InteractBubble
var speech: SpeechBubble
var move_hint: MoveHint
var feedback: FeedbackLayer

var _profile: ProfileCard
var _money: ResourcePill
var _date: ResourcePill
var _objectives: ObjectivesPanel
var _side: VBoxContainer
var _orders_button: SideButton
var _tasks_button: SideButton
var _nav: BottomNav
var _zoom_button: Button
var _zoom_index: int = 1
var _sheet_host: Control
var _sheet: BottomSheet
var _screen_host: Control
var _screen: ScreenBase
var _screen_id: String = "home"
var _badge_queued: bool = false


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_world_overlay()
	_build_top_bar()
	_build_objectives()
	_build_side_buttons()
	_build_zoom_button()
	_build_nav()
	_build_sheet_host()
	_build_screen_host()
	feedback = FeedbackLayer.new()
	feedback.name = "FeedbackLayer"
	feedback.toast_spot = _toast_spot
	add_child(feedback)
	joystick = JoystickRing.new()
	joystick.name = "Joystick"
	add_child(joystick)
	_connect_events()
	_refresh_values()
	_refresh_badge()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _money != null:
		_refresh_values()
		set_zoom_label(_zoom_index)


## Abre una sección por su id ("shop", "inventory"...). "home" cierra la
## pantalla abierta y vuelve a la habitación. `option` elige algo dentro de
## la sección (por ejemplo, la categoría de la tienda).
func open_screen(screen_id: String, option: String = "") -> void:
	close_sheet()
	if _screen != null:
		_screen_host.remove_child(_screen)
		_screen.queue_free()
		_screen = null
	_screen_id = screen_id
	var on_home: bool = screen_id == "home"
	_objectives.visible = on_home
	_side.visible = on_home
	status_bubbles.visible = on_home
	_zoom_button.visible = on_home
	move_hint.visible = on_home and move_hint.mode != MoveHint.Mode.NONE
	_nav.set_active(screen_id if screen_id in ["home", "workshop", "inventory", "shop", "profile"] else "")
	if not on_home:
		_screen = _create_screen(screen_id, option)
		_screen.name = "Screen"
		_screen.close_requested.connect(func() -> void: open_screen("home"))
		_screen_host.add_child(_screen)
		_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_changed.emit(screen_id)


func current_screen_id() -> String:
	return _screen_id


## Muestra el panel inferior de un objeto. Si ya había uno, lo reemplaza.
## Con `animate` en false, el reemplazo queda en su lugar sin deslizarse: es
## como se refresca un panel abierto cuando cambia la partida.
func show_sheet(sheet: BottomSheet, animate: bool = true) -> void:
	var swapping: bool = _sheet != null
	if swapping:
		_sheet_host.remove_child(_sheet)
		_sheet.queue_free()
	_sheet = sheet
	_sheet.name = "Sheet"
	_sheet.close_requested.connect(close_sheet)
	_sheet.action_pressed.connect(_on_sheet_action)
	_sheet_host.add_child(_sheet)
	if animate or not swapping:
		_sheet.slide_in(MARGIN)
	else:
		_sheet.dock(MARGIN)
	_zoom_button.visible = false
	move_hint.visible = false
	# El panel tapa la barra de secciones; sin esto asoma su borde debajo.
	_nav.visible = false


func close_sheet() -> void:
	if _sheet == null:
		return
	var closing: BottomSheet = _sheet
	_sheet = null
	closing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	closing.slide_out(closing.queue_free)
	_nav.visible = true
	_zoom_button.visible = _screen_id == "home"
	move_hint.visible = _screen_id == "home" and move_hint.mode != MoveHint.Mode.NONE
	sheet_closed.emit()


func has_sheet() -> bool:
	return _sheet != null


func current_sheet() -> BottomSheet:
	return _sheet


## Píxeles de la interfaz que tapan el mundo arriba y abajo: la cámara deja
## lo importante entre medio.
func world_insets() -> Vector2:
	var bottom: float = MARGIN + NAV_HEIGHT
	if _sheet != null:
		bottom = maxf(bottom, _sheet.covered_height())
	return Vector2(CONTENT_TOP, bottom)


## Pone la burbuja de cercanía sobre el objeto (punta de abajo en `anchor`),
## sin salirse de la parte libre del mundo ni quedar bajo los paneles del HUD.
func place_bubble(icon_name: String, anchor: Vector2) -> void:
	var side: float = InteractBubble.SIZE
	var top_left: Vector2 = anchor - Vector2(side / 2.0, side + InteractBubble.LIFT)
	bubble.show_over(icon_name, keep_in_world(Rect2(top_left, Vector2(side, side))))


## Pone el globo de diálogo sobre la cabeza (punta de abajo en `anchor`), sin
## salirse de la pantalla ni tapar la burbuja de cercanía (se pone después de
## ella en cada cuadro).
func place_speech(anchor: Vector2) -> void:
	var box: Vector2 = speech.size
	var spot: Vector2 = keep_in_world(Rect2(anchor - Vector2(box.x / 2.0, box.y + SpeechBubble.LIFT), box))
	if bubble.visible:
		var avoid: Rect2 = Rect2(bubble.position, bubble.size).grow(SPEECH_GAP)
		if avoid.intersects(Rect2(spot, box)):
			spot = _speech_clear_of(avoid, spot, box, anchor.x)
	speech.position = spot


## Dónde va el globo de diálogo (de tamaño `box`) para no tapar `avoid`:
## corrido hacia el costado contrario, si así sigue sobre la cabeza (en
## `head_x`); si no, por encima.
func _speech_clear_of(avoid: Rect2, spot: Vector2, box: Vector2, head_x: float) -> Vector2:
	var beside: Vector2 = spot
	beside.x = avoid.position.x - box.x if avoid.get_center().x > head_x else avoid.end.x
	beside = keep_in_world(Rect2(beside, box))
	var over_head: bool = head_x >= beside.x + SPEECH_HEAD_MARGIN and head_x <= beside.x + box.x - SPEECH_HEAD_MARGIN
	if over_head and not avoid.intersects(Rect2(beside, box)):
		return beside
	return keep_in_world(Rect2(Vector2(spot.x, avoid.position.y - box.y), box))


func set_zoom_label(zoom_index: int) -> void:
	_zoom_index = zoom_index
	if _zoom_button != null:
		_zoom_button.text = tr(ZOOM_LABELS[clampi(zoom_index, 0, ZOOM_LABELS.size() - 1)])


## Número rojo del botón "Pedidos": cuántas cosas esperan al jugador.
func set_orders_badge(count: int) -> void:
	_orders_button.set_badge(count)


## Centro de la píldora del dinero, en coordenadas de la interfaz: hacia ahí
## vuela lo que se cobra.
func money_pill_center() -> Vector2:
	return _money.get_global_rect().get_center()


## Centro de la barra de experiencia, en coordenadas de la interfaz.
func xp_bar_center() -> Vector2:
	return _profile.xp_bar_center()


## Pequeño salto de la píldora del dinero cuando llega un cobro.
func bump_money() -> void:
	_money.bump()


## Dónde va el aviso corto: debajo del panel de objetivos y a la derecha de
## los botones de la izquierda, para que se vea lo que acaba de cambiar (por
## ejemplo, el objetivo que pasa a "1/3" al cobrar).
func _toast_spot() -> Vector2:
	var spot: Vector2 = Vector2(MARGIN, CONTENT_TOP)
	if _side.visible:
		spot.x = _side.get_global_rect().end.x + MARGIN
	if _objectives.visible:
		spot.y = _objectives.get_global_rect().end.y + MARGIN
	return spot


## Corre un rectángulo para que quede en la parte libre del mundo: entre la
## barra de arriba y la de abajo, a la derecha de los botones de la izquierda
## y debajo del panel de objetivos. Devuelve su esquina de arriba a la izquierda.
func keep_in_world(rect: Rect2) -> Vector2:
	var area: Vector2 = get_viewport_rect().size
	var spot: Vector2 = rect.position
	spot.x = clampf(spot.x, MARGIN, area.x - MARGIN - rect.size.x)
	spot.y = clampf(spot.y, CONTENT_TOP, area.y - world_insets().y - rect.size.y)
	if _side.visible:
		var column: Rect2 = _side.get_global_rect().grow(8.0)
		if column.intersects(Rect2(spot, rect.size)):
			spot.x = column.end.x
	if _objectives.visible:
		var panel: Rect2 = _objectives.get_global_rect().grow(8.0)
		if panel.intersects(Rect2(spot, rect.size)):
			spot.y = panel.end.y
	return spot


func _create_screen(screen_id: String, option: String) -> ScreenBase:
	match screen_id:
		"workshop":
			return WorkshopScreen.new()
		"inventory":
			var inventory: InventoryScreen = InventoryScreen.new()
			inventory.local_store_requested.connect(local_store_requested.emit)
			return inventory
		"shop":
			return ShopScreen.new(option if not option.is_empty() else ShopScreen.DEFAULT_CATEGORY)
		"profile":
			return ProfileScreen.new()
		"orders":
			var orders: OrdersScreen = OrdersScreen.new()
			orders.card_action.connect(func(verb: String, uid: int) -> void: order_card_action.emit(verb, uid))
			orders.local_store_requested.connect(local_store_requested.emit)
			return orders
		"tasks":
			return TasksScreen.new()
		"map":
			return MapScreen.new()
		"settings":
			var settings: SettingsScreen = SettingsScreen.new()
			settings.language_changed.connect(func() -> void: open_screen.call_deferred("settings"))
			return settings
	push_error("Pantalla desconocida: " + screen_id)
	return ScreenBase.new("star", "")


func _on_sheet_action(action_id: String) -> void:
	if not ACTION_SCREENS.has(action_id):
		sheet_command.emit(action_id)
		return
	var target: Array = ACTION_SCREENS[action_id]
	open_screen(target[0], target[1])


## Lo que se dibuja sobre el mundo y debajo del resto del HUD. Las burbujas de
## estado van primero, para quedar debajo de la de cercanía y del globo.
func _build_world_overlay() -> void:
	status_bubbles = StatusBubbles.new()
	status_bubbles.name = "StatusBubbles"
	add_child(status_bubbles)
	bubble = InteractBubble.new()
	bubble.name = "InteractBubble"
	# La burbuja no recibe toques: WorldControls revisa si el toque cayó en
	# ella. Así un arrastre que empieza encima sigue siendo el joystick.
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bubble)
	speech = SpeechBubble.new()
	speech.name = "SpeechBubble"
	add_child(speech)
	move_hint = MoveHint.new()
	move_hint.name = "MoveHint"
	add_child(move_hint)


func _build_top_bar() -> void:
	var bar: HBoxContainer = UiKit.hbox(12)
	bar.name = "TopBar"
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = MARGIN
	bar.offset_right = -MARGIN
	bar.offset_top = TOP
	add_child(bar)
	_profile = ProfileCard.new()
	_profile.name = "ProfileCard"
	_profile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(_profile)
	var pills: VBoxContainer = UiKit.vbox(8)
	pills.custom_minimum_size = Vector2(214, 0)
	bar.add_child(pills)
	_money = ResourcePill.new("coin", Color.WHITE)
	_money.name = "MoneyPill"
	pills.add_child(_money)
	_date = ResourcePill.new("calendar", UiPalette.ACCENT)
	_date.name = "DatePill"
	pills.add_child(_date)
	var settings: Button = Button.new()
	settings.name = "SettingsButton"
	settings.theme_type_variation = "IconButton"
	settings.icon = UiKit.icon_texture("gear")
	settings.add_theme_constant_override("icon_max_width", 34)
	settings.custom_minimum_size = Vector2(60, 60)
	settings.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	settings.focus_mode = Control.FOCUS_NONE
	settings.pressed.connect(func() -> void: open_screen("settings"))
	bar.add_child(settings)


func _build_objectives() -> void:
	_objectives = ObjectivesPanel.new()
	_objectives.name = "ObjectivesPanel"
	_objectives.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_objectives.offset_left = -MARGIN - 330.0
	_objectives.offset_right = -MARGIN
	_objectives.offset_top = CONTENT_TOP
	_objectives.custom_minimum_size = Vector2(330, 0)
	_objectives.pressed.connect(func() -> void: open_screen("tasks"))
	add_child(_objectives)


func _build_side_buttons() -> void:
	_side = UiKit.vbox(12)
	_side.name = "SideButtons"
	_side.position = Vector2(MARGIN, CONTENT_TOP)
	add_child(_side)
	var buttons: Array[Array] = [["orders", "chat", "SIDE_ORDERS"], ["tasks", "tasks", "SIDE_TASKS"], ["map", "map", "SIDE_MAP"]]
	for entry: Array in buttons:
		var button: SideButton = SideButton.new(entry[1], entry[2])
		button.name = "Side_" + entry[0]
		var screen_id: String = entry[0]
		button.pressed.connect(func() -> void: open_screen(screen_id))
		_side.add_child(button)
		if screen_id == "orders":
			_orders_button = button
		elif screen_id == "tasks":
			_tasks_button = button
	_tasks_button.set_badge(ObjectivesPanel.VISIBLE_OBJECTIVES)


## Botón de zoom abajo a la izquierda, al alcance del pulgar: cambia entre
## normal, cerca y lejos (todo el cuarto).
func _build_zoom_button() -> void:
	_zoom_button = Button.new()
	_zoom_button.name = "ZoomButton"
	_zoom_button.theme_type_variation = "IconButton"
	_zoom_button.icon = UiKit.icon_texture("zoom")
	_zoom_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zoom_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	_zoom_button.add_theme_constant_override("icon_max_width", 40)
	_zoom_button.add_theme_font_size_override("font_size", 19)
	_zoom_button.focus_mode = Control.FOCUS_NONE
	_zoom_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_zoom_button.offset_left = MARGIN
	_zoom_button.offset_right = MARGIN + ZOOM_BUTTON_SIZE.x
	_zoom_button.offset_bottom = -MARGIN - NAV_HEIGHT - MARGIN
	_zoom_button.offset_top = _zoom_button.offset_bottom - ZOOM_BUTTON_SIZE.y
	_zoom_button.pressed.connect(func() -> void: zoom_pressed.emit())
	add_child(_zoom_button)
	set_zoom_label(_zoom_index)


func _build_nav() -> void:
	_nav = BottomNav.new()
	_nav.name = "BottomNav"
	_nav.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_nav.offset_left = MARGIN
	_nav.offset_right = -MARGIN
	_nav.offset_top = -MARGIN - NAV_HEIGHT
	_nav.offset_bottom = -MARGIN
	_nav.tab_selected.connect(open_screen)
	add_child(_nav)


## Lugar del panel inferior: no recibe toques (solo el panel), así el mundo
## sigue respondiendo encima de él.
func _build_sheet_host() -> void:
	_sheet_host = Control.new()
	_sheet_host.name = "SheetHost"
	_sheet_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_sheet_host)


func _build_screen_host() -> void:
	_screen_host = Control.new()
	_screen_host.name = "ScreenHost"
	_screen_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen_host.offset_left = MARGIN
	_screen_host.offset_right = -MARGIN
	_screen_host.offset_top = CONTENT_TOP
	_screen_host.offset_bottom = -MARGIN - NAV_HEIGHT - 12.0
	add_child(_screen_host)


func _connect_events() -> void:
	Events.time_changed.connect(_on_time_changed)
	Events.money_changed.connect(_on_money_changed)
	Events.xp_changed.connect(_profile.refresh.unbind(1))
	Events.level_up.connect(_profile.refresh.unbind(1))
	Events.order_delivered.connect(_objectives.refresh.unbind(5))
	Events.offers_changed.connect(_queue_badge)
	Events.order_changed.connect(_queue_badge.unbind(1))
	Events.order_removed.connect(_queue_badge.unbind(1))
	Events.printer_changed.connect(_queue_badge.unbind(1))
	Events.game_loaded.connect(_on_game_loaded)


func _refresh_values() -> void:
	if Game.state == null:
		return
	_on_money_changed(Game.state.money_cents)
	_on_time_changed(Game.state.game_minutes)


func _on_time_changed(game_minutes: float) -> void:
	_date.set_value(UiFormat.date(game_minutes))


func _on_money_changed(money_cents: int) -> void:
	_money.set_value(UiFormat.money(money_cents))


## Partida nueva o recién cargada: todo lo que muestra el HUD puede cambiar.
func _on_game_loaded() -> void:
	_refresh_values()
	_profile.refresh()
	_objectives.refresh()
	_queue_badge()


## Pide recalcular el número de "Pedidos" al final del cuadro: los avisos de un
## mismo cambio (un despacho cambia el pedido y la impresora...) lo calculan
## una sola vez.
func _queue_badge() -> void:
	if _badge_queued:
		return
	_badge_queued = true
	_refresh_badge.call_deferred()


func _refresh_badge() -> void:
	_badge_queued = false
	if Game.state == null:
		return
	set_orders_badge(OrderQueries.pending_actions(Game.state, Game.rules))

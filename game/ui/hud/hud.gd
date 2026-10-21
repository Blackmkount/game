class_name Hud
extends Control
## Interfaz principal sobre la habitación, con el estilo de la imagen de
## referencia: tarjeta del personaje con nivel y experiencia, dinero y fecha
## arriba; objetivos a la derecha; accesos rápidos a la izquierda; barra de
## secciones abajo. Las secciones se abren como pantallas sobre la habitación.

const MARGIN: float = 16.0
const TOP: float = 20.0
const CONTENT_TOP: float = 150.0
const NAV_HEIGHT: float = 116.0

var _profile: ProfileCard
var _money: ResourcePill
var _date: ResourcePill
var _objectives: ObjectivesPanel
var _side: VBoxContainer
var _tasks_button: SideButton
var _nav: BottomNav
var _screen_host: Control
var _screen: ScreenBase
var _screen_id: String = "home"


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top_bar()
	_build_objectives()
	_build_side_buttons()
	_build_nav()
	_build_screen_host()
	Events.time_changed.connect(func(_minutes: float) -> void: _refresh_values())
	_refresh_values()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _money != null:
		_refresh_values()


## Abre una sección por su id ("shop", "inventory"...). "home" cierra la
## pantalla abierta y vuelve a la habitación.
func open_screen(screen_id: String) -> void:
	if _screen != null:
		_screen_host.remove_child(_screen)
		_screen.queue_free()
		_screen = null
	_screen_id = screen_id
	var on_home: bool = screen_id == "home"
	_objectives.visible = on_home
	_side.visible = on_home
	_nav.set_active(screen_id if screen_id in ["home", "workshop", "inventory", "shop", "profile"] else "")
	if on_home:
		return
	_screen = _create_screen(screen_id)
	_screen.name = "Screen"
	_screen.close_requested.connect(func() -> void: open_screen("home"))
	_screen_host.add_child(_screen)
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func current_screen_id() -> String:
	return _screen_id


func _create_screen(screen_id: String) -> ScreenBase:
	match screen_id:
		"workshop":
			return WorkshopScreen.new()
		"inventory":
			return InventoryScreen.new()
		"shop":
			return ShopScreen.new()
		"profile":
			return ProfileScreen.new()
		"orders":
			return OrdersScreen.new()
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
		if screen_id == "tasks":
			_tasks_button = button
	_tasks_button.set_badge(ObjectivesPanel.VISIBLE_OBJECTIVES)


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


func _refresh_values() -> void:
	if Game.state == null:
		return
	_money.set_value(UiFormat.money(Game.state.money_cents))
	_date.set_value(UiFormat.date(Game.state.game_minutes))

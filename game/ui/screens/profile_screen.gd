class_name ProfileScreen
extends ScreenBase
## Perfil del protagonista: retrato, nivel, experiencia y estadísticas.

## Retrato de cuerpo entero (biblia de arte §7.9): lado de la vista (px),
## ancho que muestra (m), punto que queda al centro y giro (grados).
const PORTRAIT_SIZE: float = 150.0
const PORTRAIT_FRAME: float = 1.65
const PORTRAIT_TARGET: Vector3 = Vector3(0.0, 0.72, 0.0)
const PORTRAIT_YAW: float = 30.0


func _init() -> void:
	super("user", "SCREEN_PROFILE")


func _build_content() -> void:
	var state: GameState = Game.state
	var header: HBoxContainer = UiKit.hbox(16)
	content.add_child(header)
	var frame: PanelContainer = UiKit.panel("IconTile")
	frame.add_child(ModelPreview.new(func(world: Node3D) -> void: CharacterModel.build(world, "Character"), PORTRAIT_SIZE, PORTRAIT_FRAME, PORTRAIT_TARGET, PORTRAIT_YAW))
	header.add_child(frame)
	var info: VBoxContainer = UiKit.vbox(6)
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(info)
	info.add_child(UiKit.label(tr("PROFILE_DEFAULT_NAME"), "TitleLabel"))
	info.add_child(UiKit.label(UiFormat.tr_format("HUD_LEVEL", [Game.level()]), "BoldLabel"))
	var span: int = Game.levels.xp_span_of_level(state.xp)
	info.add_child(UiKit.xp_bar(Game.levels.xp_into_level(state.xp), span))
	info.add_child(UiKit.label(UiFormat.tr_format("HUD_XP", [UiFormat.number(Game.levels.xp_into_level(state.xp)), UiFormat.number(span)]), "SmallLabel"))

	add_section("PROFILE_STATS")
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	content.add_child(grid)
	_stat(grid, "calendar", "PROFILE_DAY", str(GameClock.day(state.game_minutes)))
	_stat(grid, "coin", "PROFILE_MONEY", UiFormat.money(state.money_cents))
	_stat(grid, "printer", "PROFILE_PRINTERS", str(state.printers.size()))
	_stat(grid, "chat", "PROFILE_ORDERS", str(state.delivered_total))
	_stat(grid, "tasks", "PROFILE_OBJECTIVES", "0 / %d" % (Game.catalog.files["objectives"] as Array).size())
	_stat(grid, "spool", "PROFILE_MATERIAL", UiFormat.grams(state.total_grams()))


func _stat(grid: GridContainer, icon_name: String, title_key: String, value: String) -> void:
	var card: PanelContainer = UiKit.panel("CardPanel")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row: HBoxContainer = UiKit.hbox(10)
	card.add_child(row)
	row.add_child(UiKit.icon(icon_name, 36, Color.WHITE if icon_name == "coin" else UiPalette.ACCENT))
	var column: VBoxContainer = UiKit.vbox(0)
	row.add_child(column)
	column.add_child(UiKit.label(tr(title_key), "SmallLabel"))
	column.add_child(UiKit.label(value, "BoldLabel"))
	grid.add_child(card)

extends GutTest
## La base de la interfaz del ciclo de pedidos sobre la escena principal:
## - el HUD cambia apenas cambia la partida (dinero, experiencia, objetivos y
##   el número de "Pedidos");
## - los paneles inferiores: botones para el ciclo, opciones, avance, error y
##   refresco sin animación;
## - la capa de celebraciones y las burbujas de estado;
## - las pantallas que se rearman sin perder el desplazamiento;
## - "Empezar partida nueva" con dos toques.

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
const SEED: int = 1234

var _main: Control
var _hud: Hud
var _previous_locale: String
var _previous_processing: bool


func before_each() -> void:
	_previous_processing = Game.is_processing()
	# La partida solo avanza cuando la prueba lo pide.
	Game.set_process(false)
	Game.reset_game(SEED)
	_previous_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	await wait_process_frames(2)
	_hud = _main.get_node("Hud")


func after_each() -> void:
	TranslationServer.set_locale(_previous_locale)
	Game.set_process(_previous_processing)


func test_a_delivery_shows_at_once_in_money_xp_objectives_and_badge() -> void:
	assert_eq(_badge("Side_orders"), "", "Todavía no hay mensajes")
	Game.advance(3.0)
	await wait_process_frames(1)
	assert_eq(_badge("Side_orders"), "1", "Llegó el primer mensaje")
	var order: Order = _to_packed(Game.state.offers[0].uid)
	await wait_process_frames(1)
	assert_eq(_badge("Side_orders"), "1", "Falta despacharlo")
	assert_true(Game.dispatch_order(order.uid).ok)
	await wait_process_frames(1)
	var top: Array[String] = _label_texts(_hud.get_node("TopBar"))
	assert_has(top, "$256", "Sin esperar al próximo minuto de juego")
	assert_has(top, "5 / 100 XP")
	assert_has(_label_texts(_hud.get_node("ObjectivesPanel")), "Entrega 3 llaveros (1/3)")
	assert_eq(_badge("Side_orders"), "", "No queda nada por hacer")


func test_the_xp_bar_fills_within_a_level_and_jumps_on_level_up() -> void:
	var bar: ProgressBar = _hud.get_node("TopBar/ProfileCard").find_children("*", "ProgressBar", true, false)[0]
	Game.state.xp = 60
	Events.xp_changed.emit(Game.state.xp)
	assert_lt(bar.value, 60.0, "Se llena de a poco")
	await wait_seconds(ProfileCard.XP_FILL_TIME + 0.1)
	assert_eq(bar.value, 60.0)
	# Nivel 2 con más experiencia dentro del nivel que la que mostraba la barra.
	Game.state.xp = 280
	Events.level_up.emit(Game.level())
	assert_eq(Game.level(), 2)
	assert_eq(bar.value, float(Game.levels.xp_into_level(280)), "En otro nivel va directo")
	assert_eq(bar.max_value, float(Game.levels.xp_span_of_level(280)))


func test_the_portrait_changes_its_face_at_the_big_moments() -> void:
	var card: ProfileCard = _hud.get_node("TopBar/ProfileCard")
	var face: GeometryInstance3D = card.find_children("Mesh", "MeshInstance3D", true, false).filter(
		func(node: Node) -> bool: return node.get_parent().name == "Head")[0]
	assert_eq(card.shown_face(), FacePainter.Face.NEUTRAL)
	Events.print_failed.emit(1, "spaghetti")
	assert_eq(card.shown_face(), FacePainter.Face.WORRIED, "Preocupado si falla una impresión")
	assert_eq(face.get_instance_shader_parameter(&"expression"), FacePainter.Face.WORRIED, "El retrato la muestra")
	card._face_timer.timeout.emit()
	assert_eq(card.shown_face(), FacePainter.Face.NEUTRAL, "Después vuelve a la normal")
	Events.level_up.emit(2)
	assert_eq(card.shown_face(), FacePainter.Face.SURPRISE, "Sorpresa al subir de nivel")
	card._face_timer.timeout.emit()
	assert_eq(card.shown_face(), FacePainter.Face.HAPPY, "y después feliz")
	card._face_timer.timeout.emit()
	assert_eq(card.shown_face(), FacePainter.Face.NEUTRAL)
	assert_true(Events.order_delivered.is_connected(card._on_order_delivered))
	card._on_order_delivered(1, "llavero", 100, 10, true)
	assert_eq(card.shown_face(), FacePainter.Face.NEUTRAL, "Si llegó tarde no hay festejo")
	card._on_order_delivered(1, "llavero", 100, 10, false)
	assert_eq(card.shown_face(), FacePainter.Face.HAPPY, "Feliz al cobrar a tiempo")


func test_a_sheet_button_that_is_not_a_section_goes_to_the_order_loop() -> void:
	var sheet: BottomSheet = BottomSheet.new(Previews.icon("printer"), "Cubo Uno")
	sheet.add_action("print", "Imprimir", true)
	_hud.show_sheet(sheet)
	watch_signals(_hud)
	(sheet.find_child("Action_print", true, false) as Button).pressed.emit()
	assert_signal_emitted_with_parameters(_hud, "sheet_command", ["print"])
	assert_eq(_hud.current_screen_id(), "home")


func test_an_order_card_button_reaches_the_hud() -> void:
	_hud.open_screen("orders")
	var screen: OrdersScreen = _hud.get_node("ScreenHost/Screen")
	watch_signals(_hud)
	screen.card_action.emit("accept", 4)
	assert_signal_emitted_with_parameters(_hud, "order_card_action", ["accept", 4])


func test_refreshing_an_open_sheet_does_not_slide_it_again() -> void:
	var first: BottomSheet = BottomSheet.new(Previews.icon("printer"), "Uno")
	_hud.show_sheet(first, false)
	assert_eq(first.offset_transform_position.y, BottomSheet.SLIDE_DISTANCE, "El primero siempre sube")
	await wait_seconds(BottomSheet.SLIDE_TIME + 0.1)
	var second: BottomSheet = BottomSheet.new(Previews.icon("printer"), "Dos")
	_hud.show_sheet(second, false)
	assert_eq(second.offset_transform_position, Vector2.ZERO, "Ya está en su lugar")
	assert_eq(second.modulate.a, 1.0)
	assert_eq(_hud.current_sheet(), second)
	assert_false(is_instance_valid(first) and first.is_inside_tree(), "El anterior se fue")
	var third: BottomSheet = BottomSheet.new(Previews.icon("printer"), "Tres")
	_hud.show_sheet(third)
	assert_eq(third.offset_transform_position.y, BottomSheet.SLIDE_DISTANCE, "Con animación sube")
	# Los paneles reemplazados se borran al final del cuadro.
	await wait_process_frames(1)


func test_sheet_choices_progress_error_and_disabled_action() -> void:
	var sheet: BottomSheet = BottomSheet.new(Previews.icon("printer"), "Imprimir: Llavero")
	sheet.add_error("Ese carrete ya no está.")
	sheet.add_line("calendar", "Lista en 50 s")
	sheet.add_chips("mode", [
		{"id": "draft", "text": "Borrador", "selected": false, "enabled": true},
		{"id": "normal", "text": "Normal", "selected": true, "enabled": true},
		{"id": "fine", "text": "Fino · calidad 3: no alcanza", "selected": false, "enabled": false},
	])
	sheet.add_progress("job", "printer", "Lista en 50 s", 0.25)
	sheet.add_action("orders", "Ver pedidos")
	sheet.add_action("print", "Imprimir", true, false, "Primero hay que terminar de modelarlo.")
	_hud.show_sheet(sheet)
	await wait_process_frames(1)
	var error: Node = sheet.find_child("Error", true, false)
	assert_eq(error.get_index(), 2, "La línea roja va justo debajo del título")
	assert_has(_label_texts(error), "Ese carrete ya no está.")
	var print_button: Button = sheet.find_child("Action_print", true, false)
	assert_true(print_button.disabled)
	assert_eq((sheet.find_child("Note_print", true, false) as Label).text, "Primero hay que terminar de modelarlo.")
	assert_null(sheet.find_child("Note_orders", true, false), "Sin nota no hay línea")
	assert_eq((sheet.find_child("Chip_mode_normal", true, false) as Button).theme_type_variation, "PrimaryButton")
	assert_eq((sheet.find_child("Chip_mode_draft", true, false) as Button).theme_type_variation, "TabButton")
	assert_true((sheet.find_child("Chip_mode_fine", true, false) as Button).disabled)
	watch_signals(_hud)
	(sheet.find_child("Chip_mode_draft", true, false) as Button).pressed.emit()
	assert_signal_emitted_with_parameters(_hud, "sheet_command", ["mode_draft"])

	var bar: ProgressBar = sheet.find_child("Progress_job", true, false)
	assert_almost_eq(bar.value, 0.25, 0.001)
	sheet.set_progress("job", "Lista en 25 s", 0.5)
	assert_eq((sheet.find_child("ProgressText_job", true, false) as Label).text, "Lista en 25 s", "El texto cambia enseguida")
	assert_lt(bar.value, 0.5, "La barra avanza de a poco")
	await wait_seconds(BottomSheet.PROGRESS_TIME + 0.1)
	assert_almost_eq(bar.value, 0.5, 0.001)


func test_payout_flies_to_the_money_and_lands_once() -> void:
	var landed: Array[int] = [0]
	_hud.feedback.fly("+$6", UiPalette.GOLD, Vector2(360, 900), _hud.money_pill_center(), 0.3, func() -> void: landed[0] += 1)
	var flying: Array[String] = []
	for label: Label in _visible_labels(_hud.feedback):
		flying.append(label.text)
	assert_eq(flying.size(), 1)
	assert_eq(flying[0], "+$6")
	await wait_seconds(0.5)
	assert_eq(landed[0], 1)
	assert_eq(_visible_labels(_hud.feedback).size(), 0, "Al llegar desaparece")
	_hud.bump_money()
	var pill: Control = _hud.get_node("TopBar").find_child("MoneyPill", true, false)
	assert_gt(pill.scale.x, 1.0, "La píldora salta")
	await wait_seconds(ResourcePill.BUMP_TIME + 0.1)
	assert_eq(pill.scale, Vector2.ONE)


func test_the_speech_never_covers_the_nearby_bubble() -> void:
	_hud.speech.say(tr("SPEECH_NEW_MESSAGE"))
	await wait_process_frames(1)
	var head: Vector2 = Vector2(360.0, 700.0)
	# La burbuja a un costado de la cabeza: el globo se corre al otro costado.
	_hud.place_bubble("printer", Vector2(460.0, 690.0))
	_hud.place_speech(head)
	_assert_speech_clear_over(head)
	var beside: float = _hud.speech.position.y
	# La burbuja justo sobre la cabeza: el globo sube por encima de ella.
	_hud.place_bubble("printer", Vector2(370.0, 690.0))
	_hud.place_speech(head)
	_assert_speech_clear_over(head)
	assert_lt(_hud.speech.position.y, beside, "Sube por encima de la burbuja")
	# Sin burbuja de cercanía, va sobre la cabeza como siempre.
	_hud.bubble.hide_bubble()
	_hud.place_speech(head)
	assert_almost_eq(_hud.speech.position.x + _hud.speech.size.x / 2.0, head.x, 0.5)


func test_the_speech_never_covers_a_status_bubble() -> void:
	_hud.speech.say(tr("SPEECH_NEW_MESSAGE"))
	await wait_process_frames(1)
	var head: Vector2 = Vector2(360.0, 700.0)
	var item: WorldInteractable = WorldInteractable.new(WorldInteractable.Kind.PRINTER, 2, AABB(Vector3.ZERO, Vector3.ONE))
	var bubbles: StatusBubbles = _hud.status_bubbles
	var index: int = bubbles.add(item)
	bubbles.bubble(index).set_state("warning", "", UiPalette.BADGE, true)
	# El aviso de la impresora, al lado de la cabeza (como en la captura 23a).
	bubbles.place(index, Vector2(470.0, 560.0))
	bubbles.set_visible_for(index, true)
	await wait_process_frames(1)
	_hud.bubble.hide_bubble()
	_hud.place_speech(head)
	var status: Rect2 = bubbles.bubble(index).get_rect()
	assert_false(Rect2(_hud.speech.position, _hud.speech.size).intersects(status), "No tapa el aviso")
	var middle: float = _hud.speech.position.x + _hud.speech.size.x / 2.0
	assert_lt(absf(middle - head.x), _hud.speech.size.x / 2.0, "Sigue sobre la cabeza")
	# Oculta, no cuenta: va sobre la cabeza como siempre.
	bubbles.set_visible_for(index, false)
	_hud.place_speech(head)
	assert_almost_eq(_hud.speech.position.x + _hud.speech.size.x / 2.0, head.x, 0.5)


func test_a_toast_never_covers_the_objectives_or_the_side_buttons() -> void:
	# El agradecimiento llega justo cuando el objetivo cambia a (1/3): debe verse.
	_hud.feedback.toast("Amigos y familia: «¡Quedó genial! Ya todos me preguntan dónde lo hice.»")
	await wait_process_frames(2)
	var toast: Rect2 = (_hud.feedback.get_node("Toast") as Control).get_global_rect()
	assert_false(toast.intersects((_hud.get_node("ObjectivesPanel") as Control).get_global_rect()), "No tapa los objetivos")
	assert_false(toast.intersects((_hud.get_node("SideButtons") as Control).get_global_rect()), "No tapa los botones de la izquierda")
	assert_lte(toast.end.x, _hud.get_viewport_rect().size.x, "Entra en la pantalla")
	# Con una sección abierta no hay objetivos ni botones: va bajo la barra de arriba.
	_hud.open_screen("orders")
	_hud.feedback.toast("Ese mensaje ya no está.")
	await wait_seconds(FeedbackLayer.TOAST_SECONDS + 0.1)
	assert_eq((_hud.feedback.get_node("Toast") as Control).get_global_rect().position.y, Hud.CONTENT_TOP)


func test_toasts_wait_their_turn_and_keep_the_latest() -> void:
	for text: String in ["uno", "dos", "tres", "cuatro"]:
		_hud.feedback.toast(text)
	var toast: Control = _hud.feedback.get_node("Toast")
	assert_has(_label_texts(toast), "uno")
	await wait_seconds(FeedbackLayer.TOAST_SECONDS + 0.1)
	assert_has(_label_texts(toast), "tres", "Esperan dos como mucho: el más viejo se descarta")
	await wait_seconds(FeedbackLayer.TOAST_SECONDS)
	assert_has(_label_texts(toast), "cuatro")
	await wait_seconds(FeedbackLayer.TOAST_SECONDS)
	assert_false(toast.visible)


func test_status_bubbles_take_taps_only_when_shown_at_home() -> void:
	var item: WorldInteractable = WorldInteractable.new(WorldInteractable.Kind.PRINTER, 2, AABB(Vector3.ZERO, Vector3.ONE))
	var bubbles: StatusBubbles = _hud.status_bubbles
	var index: int = bubbles.add(item)
	bubbles.bubble(index).set_state("check", "", UiPalette.XP_FILL, false)
	bubbles.place(index, Vector2(300, 600))
	var center: Vector2 = Vector2(300, 600) + Vector2.ONE * StatusBubble.SIZE / 2.0
	assert_null(bubbles.hit(center), "Oculta no se toca")
	bubbles.set_visible_for(index, true)
	await wait_process_frames(1)
	assert_eq(bubbles.hit(center), item)
	assert_eq(bubbles.hit(center - Vector2(StatusBubble.HIT_SIZE / 2.0 - 2.0, 0.0)), item, "Se toca en 88 px aunque se vea de 72")
	assert_null(bubbles.hit(center - Vector2(StatusBubble.HIT_SIZE / 2.0 + 2.0, 0.0)))
	_hud.open_screen("tasks")
	assert_null(bubbles.hit(center), "Solo en la habitación")


func test_rebuilding_a_screen_keeps_the_scroll() -> void:
	_hud.open_screen("tasks")
	var screen: ScreenBase = _hud.get_node("ScreenHost/Screen")
	await wait_process_frames(2)
	var bottom: int = int(screen.scroll.get_v_scroll_bar().max_value - screen.scroll.size.y)
	assert_gt(bottom, 200, "La lista es más alta que la pantalla")
	# Hasta abajo: es donde se nota si el contenido nuevo todavía no tiene su alto.
	screen.scroll.scroll_vertical = bottom
	await wait_process_frames(1)
	var first_card: Node = screen.content.get_child(0)
	screen.rebuild()
	await wait_process_frames(2)
	assert_ne(screen.content.get_child(0), first_card, "El contenido es nuevo")
	assert_eq(screen.scroll.scroll_vertical, bottom)


func test_a_new_game_needs_a_second_tap_within_three_seconds() -> void:
	Game.advance(3.0)
	_hud.open_screen("settings")
	var settings: SettingsScreen = _hud.get_node("ScreenHost/Screen")
	var restarts: Array[int] = [0]
	settings.restart = func() -> void: restarts[0] += 1
	var button: Button = settings.find_child("NewGame", true, false)
	var played: GameState = Game.state
	button.pressed.emit()
	assert_eq(button.text, "¿Seguro? Se borra tu partida. Toca otra vez")
	assert_same(Game.state, played, "Un toque no borra nada")
	await wait_seconds(SettingsScreen.CONFIRM_SECONDS + 0.2)
	assert_eq(button.text, "Empezar partida nueva", "Pasado el tiempo hay que empezar de nuevo")
	button.pressed.emit()
	assert_same(Game.state, played)
	button.pressed.emit()
	assert_not_same(Game.state, played, "Partida nueva")
	assert_eq(Game.state.offers.size(), 0)
	assert_eq(restarts[0], 1)


## El globo de diálogo no tapa la burbuja de cercanía y sigue sobre la
## cabeza (en `head`).
func _assert_speech_clear_over(head: Vector2) -> void:
	var speech: Rect2 = Rect2(_hud.speech.position, _hud.speech.size)
	var bubble: Rect2 = Rect2(_hud.bubble.position, _hud.bubble.size)
	assert_false(speech.intersects(bubble), "El globo %s no tapa la burbuja %s" % [speech, bubble])
	assert_between(head.x, speech.position.x, speech.end.x, "El globo sigue sobre la cabeza")
	assert_lt(speech.end.y, head.y, "El globo queda arriba de la cabeza")


## Número rojo del botón de la izquierda, o "" si no se ve.
func _badge(button_name: String) -> String:
	var badge: Control = _hud.get_node("SideButtons/" + button_name).find_children("*", "PanelContainer", false, false)[0]
	if not badge.visible:
		return ""
	return (badge.get_child(0) as Label).text


## Acepta el mensaje y lleva el pedido con comandos de Game hasta embalarlo.
func _to_packed(offer_uid: int) -> Order:
	var result: CommandResult = Game.accept_offer(offer_uid)
	assert_true(result.ok, result.reason)
	var order: Order = Game.state.find_order(result.uid)
	_advance_until(func() -> bool: return order.stage == Order.Stage.READY_TO_PRINT)
	var plan: PrintPlan = PrintPlanner.recommend(Game.state, Game.rules, order)
	assert_true(Game.start_print(order.uid, plan.printer_uid, plan.spool_uid, plan.mode_id).ok)
	_advance_until(func() -> bool: return order.stage == Order.Stage.PRINTED)
	assert_true(Game.remove_pieces(plan.printer_uid).ok)
	assert_true(Game.pack_order(order.uid).ok)
	return order


## Avanza de a un segundo real hasta que se cumpla `condition`, con un límite
## para no quedar esperando para siempre.
func _advance_until(condition: Callable, max_real_seconds: int = 120) -> void:
	for i: int in max_real_seconds:
		if condition.call():
			return
		Game.advance(1.0)
	assert_true(condition.call(), "No llegó a tiempo")


func _visible_labels(root: Node) -> Array[Label]:
	var labels: Array[Label] = []
	for node: Node in root.get_children():
		if node is Label and (node as Label).visible:
			labels.append(node)
	return labels


func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for node: Node in root.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return texts

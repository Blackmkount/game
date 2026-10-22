class_name UiKit
extends RefCounted
## Atajos para armar la interfaz con el tema común.

const ICON_DIR: String = "res://assets/icons/%s.svg"


## Un botón dentro de `root` que tiene un dedo encima ahora mismo, o null.
## Rearmar la interfaz en ese momento lo borraría y el toque se perdería: hay
## que esperar a que se suelte (button_up).
static func held_button(root: Node) -> BaseButton:
	for node: Node in root.find_children("*", "BaseButton", true, false):
		var button: BaseButton = node
		if not button.toggle_mode and button.is_pressed():
			return button
	return null


static func icon_texture(icon_name: String) -> Texture2D:
	return load(ICON_DIR % icon_name)


static func icon(icon_name: String, size: float, color: Color = UiPalette.TEXT) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	rect.texture = icon_texture(icon_name)
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.modulate = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


static func label(text: String, variation: String = "", wrap: bool = false) -> Label:
	var result: Label = Label.new()
	result.text = text
	result.theme_type_variation = variation
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result


static func panel(variation: String = "") -> PanelContainer:
	var result: PanelContainer = PanelContainer.new()
	result.theme_type_variation = variation
	return result


static func hbox(separation: int = 10) -> HBoxContainer:
	var box: HBoxContainer = HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


static func vbox(separation: int = 8) -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


## Cuadro con un icono centrado (para tarjetas de la tienda, inventario...).
static func icon_tile(icon_name: String, size: float, color: Color = UiPalette.TEXT) -> PanelContainer:
	var tile: PanelContainer = panel("IconTile")
	tile.custom_minimum_size = Vector2(size, size)
	tile.add_child(icon(icon_name, size * 0.6, color))
	return tile


static func xp_bar(value: float, max_value: float) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.theme_type_variation = "XpBar"
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	bar.max_value = maxf(max_value, 1.0)
	bar.value = value
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


## Etiqueta naranja con candado: "Nivel 3".
static func lock_tag(level: int) -> HBoxContainer:
	var tag: HBoxContainer = hbox(4)
	tag.add_child(icon("lock", 22, UiPalette.LOCKED))
	var text: Label = label(UiFormat.tr_format("SHOP_LEVEL_REQUIRED", [level]), "BoldLabel")
	text.add_theme_color_override("font_color", UiPalette.LOCKED)
	text.add_theme_font_size_override("font_size", 20)
	tag.add_child(text)
	return tag

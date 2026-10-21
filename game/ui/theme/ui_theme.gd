class_name UiTheme
extends RefCounted
## Tema visual de toda la interfaz, armado por código para que sea el mismo en
## todas las pantallas. Variaciones disponibles (theme_type_variation):
## - PanelContainer: "CardPanel", "PillPanel", "ActivePanel", "BadgePanel", "IconTile"
## - Button: "PrimaryButton", "NavButton", "NavButtonActive", "TabButton", "IconButton"
## - Label: "TitleLabel", "BoldLabel", "MutedLabel", "SmallLabel", "BadgeLabel"
## - ProgressBar: "XpBar"

const FONT: FontFile = preload("res://assets/fonts/Nunito.ttf")
const BASE_FONT_SIZE: int = 24

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


static func font(weight: int) -> FontVariation:
	var variation: FontVariation = FontVariation.new()
	variation.base_font = FONT
	var tag: int = TextServerManager.get_primary_interface().name_to_tag("wght")
	variation.variation_opentype = {tag: weight}
	return variation


static func _build() -> Theme:
	var theme: Theme = Theme.new()
	var regular: FontVariation = font(650)
	var bold: FontVariation = font(850)
	theme.default_font = regular
	theme.default_font_size = BASE_FONT_SIZE

	theme.set_stylebox("panel", "PanelContainer", _box(UiPalette.PANEL, UiPalette.BORDER, 18, 14, 2, UiPalette.GLOW, 8))
	_variation(theme, "CardPanel", "PanelContainer")
	theme.set_stylebox("panel", "CardPanel", _box(UiPalette.CARD, UiPalette.CARD_BORDER, 14, 12, 2))
	_variation(theme, "PillPanel", "PanelContainer")
	theme.set_stylebox("panel", "PillPanel", _box(UiPalette.PANEL, UiPalette.BORDER, 26, 10, 2, UiPalette.GLOW, 6))
	_variation(theme, "ActivePanel", "PanelContainer")
	theme.set_stylebox("panel", "ActivePanel", _box(UiPalette.ACCENT_DARK, UiPalette.ACCENT, 14, 12, 2, UiPalette.GLOW, 10))
	_variation(theme, "BadgePanel", "PanelContainer")
	theme.set_stylebox("panel", "BadgePanel", _box(UiPalette.BADGE, UiPalette.BADGE.darkened(0.3), 14, 2, 2))
	_variation(theme, "IconTile", "PanelContainer")
	theme.set_stylebox("panel", "IconTile", _box(Color("0d1424"), UiPalette.CARD_BORDER, 12, 4, 2))

	theme.set_color("font_color", "Label", UiPalette.TEXT)
	_label(theme, "TitleLabel", bold, 32, UiPalette.TEXT)
	_label(theme, "BoldLabel", bold, BASE_FONT_SIZE, UiPalette.TEXT)
	_label(theme, "MutedLabel", regular, 21, UiPalette.TEXT_MUTED)
	_label(theme, "SmallLabel", regular, 19, UiPalette.TEXT_MUTED)
	_label(theme, "BadgeLabel", bold, 18, UiPalette.TEXT)

	_button(theme, "Button", UiPalette.BUTTON, UiPalette.BORDER, UiPalette.TEXT)
	theme.set_font("font", "Button", bold)
	_variation(theme, "PrimaryButton", "Button")
	_button(theme, "PrimaryButton", UiPalette.PRIMARY, UiPalette.ACCENT, UiPalette.PRIMARY_TEXT)
	_variation(theme, "TabButton", "Button")
	_button(theme, "TabButton", UiPalette.BUTTON, UiPalette.CARD_BORDER, UiPalette.TEXT_MUTED)
	theme.set_stylebox("pressed", "TabButton", _box(UiPalette.ACCENT_DARK, UiPalette.ACCENT, 16, 10, 2, UiPalette.GLOW, 6))
	theme.set_stylebox("hover_pressed", "TabButton", _box(UiPalette.ACCENT_DARK, UiPalette.ACCENT, 16, 10, 2, UiPalette.GLOW, 6))
	theme.set_color("font_pressed_color", "TabButton", UiPalette.ACCENT)
	theme.set_color("font_hover_pressed_color", "TabButton", UiPalette.ACCENT)
	theme.set_font_size("font_size", "TabButton", 20)
	_variation(theme, "IconButton", "Button")
	_button(theme, "IconButton", UiPalette.PANEL, UiPalette.BORDER, UiPalette.TEXT)
	_variation(theme, "NavButton", "Button")
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		theme.set_stylebox(state, "NavButton", empty)
	theme.set_color("font_color", "NavButton", UiPalette.TEXT)
	theme.set_color("font_hover_color", "NavButton", UiPalette.ACCENT)
	theme.set_color("font_pressed_color", "NavButton", UiPalette.ACCENT)
	theme.set_font_size("font_size", "NavButton", 19)
	_variation(theme, "NavButtonActive", "NavButton")
	var active: StyleBoxFlat = _box(UiPalette.ACCENT_DARK, UiPalette.ACCENT, 18, 6, 3, UiPalette.GLOW, 12)
	for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
		theme.set_stylebox(state, "NavButtonActive", active)
	theme.set_color("font_color", "NavButtonActive", UiPalette.ACCENT)

	var bar_back: StyleBoxFlat = _box(UiPalette.BAR_BACK, Color("233650"), 8, 0, 2)
	theme.set_stylebox("background", "ProgressBar", bar_back)
	theme.set_stylebox("fill", "ProgressBar", _box(UiPalette.ACCENT, UiPalette.ACCENT, 8, 0, 0))
	theme.set_color("font_color", "ProgressBar", UiPalette.TEXT)
	_variation(theme, "XpBar", "ProgressBar")
	theme.set_stylebox("fill", "XpBar", _box(UiPalette.XP_FILL, UiPalette.XP_FILL, 8, 0, 0))

	var grabber: StyleBoxFlat = _box(UiPalette.BORDER, UiPalette.BORDER, 4, 0, 0)
	theme.set_stylebox("grabber", "VScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grabber)
	theme.set_stylebox("scroll", "VScrollBar", _box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 4, 0, 0))
	return theme


static func _variation(theme: Theme, variation: String, base: String) -> void:
	theme.set_type_variation(variation, base)


static func _label(theme: Theme, variation: String, label_font: Font, size: int, color: Color) -> void:
	_variation(theme, variation, "Label")
	theme.set_font("font", variation, label_font)
	theme.set_font_size("font_size", variation, size)
	theme.set_color("font_color", variation, color)


static func _button(theme: Theme, type: String, background: Color, border: Color, text: Color) -> void:
	theme.set_stylebox("normal", type, _box(background, border, 16, 10, 2))
	theme.set_stylebox("hover", type, _box(background.lightened(0.06), UiPalette.ACCENT, 16, 10, 2, UiPalette.GLOW, 6))
	theme.set_stylebox("pressed", type, _box(UiPalette.BUTTON_PRESSED, UiPalette.ACCENT, 16, 10, 2, UiPalette.GLOW, 8))
	theme.set_stylebox("hover_pressed", type, _box(UiPalette.BUTTON_PRESSED, UiPalette.ACCENT, 16, 10, 2, UiPalette.GLOW, 8))
	theme.set_stylebox("disabled", type, _box(UiPalette.BUTTON_DISABLED, Color("243049"), 16, 10, 2))
	theme.set_stylebox("focus", type, StyleBoxEmpty.new())
	theme.set_color("font_color", type, text)
	theme.set_color("font_hover_color", type, text)
	theme.set_color("font_pressed_color", type, text)
	theme.set_color("font_disabled_color", type, UiPalette.TEXT_DISABLED)


static func _box(background: Color, border: Color, radius: int, margin: int, border_width: int, shadow: Color = Color(0, 0, 0, 0), shadow_size: int = 0) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(margin)
	box.shadow_color = shadow
	box.shadow_size = shadow_size
	box.anti_aliasing = true
	return box

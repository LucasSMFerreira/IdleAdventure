class_name DarkTheme
extends RefCounted

const STONE := Color("1a1614")
const STONE_LIGHT := Color("241d19")
const BRONZE := Color("b45309")
const GOLD := Color("fbbf24")
const CRIMSON := Color("991b1b")
const TEXT := Color("f8e7c2")
const RARITY_COLORS: Array[Color] = [Color("9ca3af"), Color("3b82f6"), Color("a855f7"), Color("f59e0b")]

static func panel(color: Color = STONE, border: Color = BRONZE, width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(5.0)
	return style

static func button(control: Control, accent: Color = BRONZE) -> void:
	control.add_theme_color_override("font_color", TEXT)
	control.add_theme_font_size_override("font_size", 12)
	control.add_theme_color_override("font_hover_color", GOLD)
	control.add_theme_stylebox_override("normal", panel(STONE_LIGHT, accent, 1))
	control.add_theme_stylebox_override("hover", panel(Color("38281c"), GOLD, 2))
	control.add_theme_stylebox_override("pressed", panel(Color("100d0c"), CRIMSON, 2))

static func label(control: Label, size: int = 12, color: Color = TEXT) -> void:
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_color", color)

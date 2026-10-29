class_name UiKit
extends RefCounted
## Shared theme, fonts and styleboxes for every Control in the game.

const FONT_PATH := "res://assets/font/Cubic_11.ttf"
const TEX_PANEL := preload("res://assets/generated/ui/panel.png")
const TEX_PANEL_SEL := preload("res://assets/generated/ui/panel_sel.png")
const TEX_BUTTON := preload("res://assets/generated/ui/button.png")

const INK := Color("#e8eef8")
const MUTED := Color("#9fb0c8")
const GOLD := Color("#f2c94c")
const GREEN := Color("#8fe0b0")
const RED := Color("#e2556b")
const CYAN := Color("#7ee3d4")
const NIGHT := Color("#9a8fe0")

static var _theme: Theme
static var _font: Font


static func font() -> Font:
	if _font == null:
		var f: FontFile = load(FONT_PATH)
		if f:
			f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
			f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		_font = f
	return _font


static func make_texture_style(tex: Texture2D, margin: int = 8, content: int = 12) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	sb.content_margin_left = content
	sb.content_margin_right = content
	sb.content_margin_top = content * 0.6
	sb.content_margin_bottom = content * 0.6
	return sb


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 24
	t.set_color("font_color", "Label", INK)

	var normal := make_texture_style(TEX_BUTTON, 8, 14)
	var hover := make_texture_style(TEX_PANEL_SEL, 8, 14)
	var pressed := make_texture_style(TEX_PANEL, 8, 14)
	var disabled := make_texture_style(TEX_PANEL, 8, 14)
	disabled.modulate_color = Color(0.6, 0.6, 0.65, 0.7)
	for state in [["normal", normal], ["hover", hover], ["pressed", pressed], ["focus", hover], ["disabled", disabled]]:
		t.set_stylebox(state[0], "Button", state[1])
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", Color("#ffffff"))
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.6, 0.68))
	t.set_font_size("font_size", "Button", 24)

	t.set_stylebox("panel", "PanelContainer", make_texture_style(TEX_PANEL, 8, 14))
	t.set_stylebox("panel", "Panel", make_texture_style(TEX_PANEL, 8, 14))

	t.set_color("font_color", "RichTextLabel", INK)
	t.set_font_size("normal_font_size", "RichTextLabel", 24)
	_theme = t
	return t


static func label(text: String, size: int = 24, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, size: int = 26) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", size)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


static func panel_container(content: int = 12) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", make_texture_style(TEX_PANEL, 8, content))
	return p


static func icon(path: String, size: int = 32) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(size, size)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return t

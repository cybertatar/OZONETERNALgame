extends RefCounted
## Помощники интерфейса: пиксельные панели и надписи.

const INK := Color("#1b1420")
const PAPER := Color("#f4efe2")
const GOLD := Color("#e8c35a")
const MUTED := Color("#a89fb3")
## Размеры текста в пикселях игрового экрана 480×270 (на экране — ×3–×4, текст
## рисуется в настоящем разрешении).
const TEXT := 9
const SMALL := 8
const TITLE := 16


static func panel(dark := true) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load("res://assets/sprites/panel_dark.png" if dark else "res://assets/sprites/panel_light.png")
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		s.set_texture_margin(side, 4)
		s.set_content_margin(side, 6)
	return s


static func label(text: String, size := TEXT, color := PAPER, outline := true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	if size >= TITLE:
		l.add_theme_font_override("font", Game.font_bold)
	l.add_theme_color_override("font_color", color)
	if outline:
		l.add_theme_color_override("font_outline_color", INK)
		l.add_theme_constant_override("outline_size", 2 if size < TITLE else 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func button_styles(b: Button) -> void:
	b.add_theme_stylebox_override("normal", panel(true))
	var hover := panel(true)
	hover.modulate_color = Color(1.35, 1.25, 1.1)
	b.add_theme_stylebox_override("hover", hover)
	var focus := panel(false)
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_stylebox_override("pressed", focus)
	b.add_theme_color_override("font_color", PAPER)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_focus_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	feedback(b)


## Звук при наведении и нажатии и короткая вспышка-«пружинка» на нажатой кнопке.
static func feedback(b: Button) -> void:
	b.focus_entered.connect(func(): Fx.sfx("move"))
	b.mouse_entered.connect(func():
		if not b.disabled:
			b.grab_focus())
	b.pressed.connect(func(): press_flash(b))


static func press_flash(c: Control) -> void:
	Fx.sfx("confirm")
	c.pivot_offset = c.size * 0.5
	var t := c.create_tween()
	t.tween_property(c, "scale", Vector2(1.08, 1.08), 0.06)
	t.parallel().tween_property(c, "modulate", Color(1.6, 1.5, 1.2), 0.06)
	t.tween_property(c, "scale", Vector2.ONE, 0.12)
	t.parallel().tween_property(c, "modulate", Color.WHITE, 0.12)

extends CanvasLayer
## HUD: здоровье, вторая жизнь, способность, комната, подсказки, тосты, полоса босса.

const UI := preload("res://scripts/ui/ui.gd")

var root: Control
var bars: Control
var room_label: Label
var toast_label: Label
var controls_label: Label
var _toast_tween: Tween
var _boss := {"hp": 0, "max": 0, "name": "", "shown": false}


class Bars extends Control:
	## Рисует здоровье, способность и полосу босса пикселями.
	var hud

	func _draw() -> void:
		var w = Game.world()
		if w and w.player and not w.player.in_hub and not Game.run.is_empty():
			_draw_hp()
			if Game.run.drink != "":
				_draw_ability(w.player)
		elif w and w.player and w.player.in_hub:
			_draw_drunk()
		if hud._boss.shown:
			_draw_boss()

	func _draw_hp() -> void:
		var heart: Texture2D = preload("res://assets/sprites/icon_heart.png")
		draw_texture(heart, Vector2(8, 8))
		var x := 20.0
		var w := 70.0
		var frac := clampf(float(Game.run.hp) / float(Game.run.max_hp), 0.0, 1.0)
		draw_rect(Rect2(x - 1, 9, w + 2, 8), UI.INK)
		draw_rect(Rect2(x, 10, w, 6), Color("#4a2a33"))
		draw_rect(Rect2(x, 10, round(w * frac), 6), Color("#d8434f"))
		draw_rect(Rect2(x, 10, round(w * frac), 1), Color("#f08a8f"))
		var f: Font = Game.font
		var txt := "%d/%d" % [Game.run.hp, Game.run.max_hp]
		draw_string_outline(f, Vector2(x + w + 5, 16), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.TEXT, 2, UI.INK)
		draw_string(f, Vector2(x + w + 5, 16), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.TEXT, UI.PAPER)
		var nx := x + w + 8 + f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.TEXT).x
		if Game.run.extra_life:
			draw_texture(preload("res://assets/sprites/icon_life.png"), Vector2(nx, 7))
			var lt := "вторая жизнь"
			draw_string_outline(f, Vector2(nx + 14, 16), lt, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.SMALL, 2, UI.INK)
			draw_string(f, Vector2(nx + 14, 16), lt, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.SMALL, UI.GOLD)
			nx += 14 + f.get_string_size(lt, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.SMALL).x + 2
		if Game.run.damage > 1.0:
			var d := "урон ×%s" % str(snappedf(Game.run.damage, 0.01))
			var dx := nx + 4
			draw_string_outline(f, Vector2(dx, 16), d, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.TEXT, 2, UI.INK)
			draw_string(f, Vector2(dx, 16), d, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.TEXT, UI.GOLD)

	## Ячейки внизу слева: рывок и способность. На перезарядке ячейка темнеет снизу
	## вверх и показывает, сколько секунд осталось.
	func _draw_ability(p) -> void:
		var y := size.y - 38.0
		_draw_slot(Vector2(10, y), "res://assets/sprites/icon_dash.png", p.dash_cd, p.DASH_COOLDOWN, "dash")
		if Game.run.drink != "":
			var drink: Dictionary = Game.DRINKS[Game.run.drink]
			_draw_slot(Vector2(48, y), drink.icon, p.ability_cd, drink.cooldown, "ability")

	func _draw_slot(pos: Vector2, icon: String, left: float, total: float, action: String) -> void:
		var ready := left <= 0.0
		var since := (Time.get_ticks_msec() - int(hud.denied.get(action, -100000))) / 1000.0
		var refused := since < 0.35
		if refused:
			pos.x += roundf(sin(since * 60.0) * 2.0 * (1.0 - since / 0.35))
		draw_rect(Rect2(pos, Vector2(24, 24)), UI.INK)
		var border := Color("#d8434f") if refused else (UI.GOLD if ready else Color("#463a52"))
		draw_rect(Rect2(pos + Vector2(1, 1), Vector2(22, 22)), border)
		draw_rect(Rect2(pos + Vector2(2, 2), Vector2(20, 20)), Color("#231d29"))
		draw_texture(_icon(icon), pos + Vector2(4, 4))
		var f: Font = Game.font_bold
		if not ready:
			var h := roundf(20.0 * clampf(left / total, 0.0, 1.0))
			draw_rect(Rect2(pos + Vector2(2, 22 - h), Vector2(20, h)), Color(0.07, 0.05, 0.1, 0.75))
			var sec := ("%.1f" % left).replace(".", ",") if left < 10.0 else str(ceili(left))
			var sw := f.get_string_size(sec, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.TEXT).x
			var at := pos + Vector2(12 - sw * 0.5, 16)
			draw_string_outline(f, at, sec, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.TEXT, 3, UI.INK)
			draw_string(f, at, sec, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.TEXT, UI.PAPER)
		var key := Game.key_name(action)
		var kf: Font = Game.font
		var kw := kf.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.SMALL).x
		var kat := pos + Vector2(12 - kw * 0.5, 33)
		draw_string_outline(kf, kat, key, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.SMALL, 2, UI.INK)
		draw_string(kf, kat, key, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.SMALL, UI.PAPER if ready else UI.MUTED)

	## В квартире: что Озон выпил этим утром.
	func _draw_drunk() -> void:
		var pos := Vector2(8, 8)
		var f: Font = Game.font
		var t1: String
		var t2: String
		if Game.drunk == "":
			t1 = "Озон трезв"
			t2 = "Подойди к столу и выпей что-нибудь перед забегом"
		else:
			var d: Dictionary = Game.DRINKS[Game.drunk]
			t1 = "Выпито: " + d.name
			t2 = "В забеге: %s — %s" % [Game.key_name("ability"), d.verb]
		draw_rect(Rect2(pos, Vector2(22, 22)), UI.INK)
		draw_rect(Rect2(pos + Vector2(1, 1), Vector2(20, 20)), Color("#463a52"))
		draw_rect(Rect2(pos + Vector2(2, 2), Vector2(18, 18)), Color("#231d29"))
		if Game.drunk != "":
			draw_texture(_icon(Game.DRINKS[Game.drunk].icon), pos + Vector2(3, 3))
		var fb: Font = Game.font_bold
		draw_string_outline(fb, pos + Vector2(28, 9), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.TEXT, 2, UI.INK)
		draw_string(fb, pos + Vector2(28, 9), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.TEXT, UI.GOLD if Game.drunk != "" else UI.PAPER)
		draw_string_outline(f, pos + Vector2(28, 20), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.SMALL, 2, UI.INK)
		draw_string(f, pos + Vector2(28, 20), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.SMALL, UI.MUTED)

	var _icons := {}

	func _icon(path: String) -> Texture2D:
		if not _icons.has(path):
			_icons[path] = load(path)
		return _icons[path]

	func _draw_boss() -> void:
		var b: Dictionary = hud._boss
		var w := 220.0
		var x := roundf((size.x - w) * 0.5)
		var y := size.y - 18.0
		var f: Font = Game.font
		var nw := f.get_string_size(b.name, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.TEXT).x
		draw_string_outline(f, Vector2(round((size.x - nw) * 0.5), y - 3), b.name, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.TEXT, 2, UI.INK)
		draw_string(f, Vector2(round((size.x - nw) * 0.5), y - 3), b.name, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.TEXT, UI.PAPER)
		var frac := clampf(float(b.hp) / max(float(b.max), 1.0), 0.0, 1.0)
		draw_rect(Rect2(x - 1, y - 1, w + 2, 8), UI.INK)
		draw_rect(Rect2(x, y, w, 6), Color("#3a2433"))
		draw_rect(Rect2(x, y, round(w * frac), 6), Color("#c23b33"))
		draw_rect(Rect2(x, y, round(w * frac), 1), Color("#e8735f"))
		draw_rect(Rect2(x + w * 0.5, y, 1, 6), Color(0, 0, 0, 0.4))


func _ready() -> void:
	layer = 10
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	bars = Bars.new()
	bars.hud = self
	bars.set_anchors_preset(Control.PRESET_FULL_RECT)
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bars)

	room_label = UI.label("", UI.SMALL, UI.MUTED)
	room_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	room_label.position = Vector2(-208, 6)
	room_label.size = Vector2(200, 12)
	root.add_child(room_label)


	toast_label = UI.label("", UI.SMALL, UI.GOLD)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_label.position = Vector2(-200, 30)
	toast_label.size = Vector2(400, 12)
	toast_label.modulate.a = 0.0
	root.add_child(toast_label)

	controls_label = UI.label("", UI.SMALL, UI.MUTED)
	controls_label.position = Vector2(8, 252)
	controls_label.visible = false
	root.add_child(controls_label)

	Game.boss_hp_changed.connect(func(hp: int, mx: int, nm: String):
		_boss = {"hp": hp, "max": mx, "name": nm, "shown": true})


func _process(_delta: float) -> void:
	bars.queue_redraw()
	if controls_label.visible:
		var k := Game.key_name
		var move := "левый стик" if Game.using_pad else "WASD"
		controls_label.text = "%s — ходить   %s — удар   %s — усиленный   %s — рывок   %s — действие" % [
			move, k.call("attack"), k.call("heavy"), k.call("dash"), k.call("interact")]


func set_room_label(text: String) -> void:
	room_label.text = text


## Время, когда кнопку жали на перезарядке: ячейка вздрагивает и мигает красным.
var denied := {}


func deny(action: String) -> void:
	denied[action] = Time.get_ticks_msec()


func show_controls(on: bool) -> void:
	controls_label.visible = on


func toast(text: String, seconds := 1.6) -> void:
	toast_label.text = text
	if _toast_tween:
		_toast_tween.kill()
	toast_label.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(seconds)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.4)


func hide_boss_bar() -> void:
	_boss.shown = false


## Крупная золотая надпись посреди боя (вторая жизнь): выскакивает и гаснет.
func big_banner(big: String, small: String) -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var a := UI.label(big, 26, UI.GOLD)
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var b := UI.label(small, UI.TEXT, UI.PAPER)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(a)
	box.add_child(b)
	box.position.y = -50
	root.add_child(box)
	box.pivot_offset = Vector2(240, 135)
	box.scale = Vector2(1.6, 1.6)
	var t := create_tween()
	t.tween_property(box, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(1.4)
	t.tween_property(box, "modulate:a", 0.0, 0.5)
	t.tween_callback(box.queue_free)


## Крупная надпись по центру (пробуждение, начало игры).
func title(big: String, small: String) -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var a := UI.label(big, 16, UI.GOLD)
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var b := UI.label(small, UI.TEXT)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(a)
	box.add_child(b)
	box.position.y = -40
	root.add_child(box)
	box.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(box, "modulate:a", 1.0, 0.4)
	t.tween_interval(2.0)
	t.tween_property(box, "modulate:a", 0.0, 0.6)
	t.tween_callback(box.queue_free)


## Представление босса: чёрные полосы сверху и снизу, имя в верхней полосе,
## внизу реплика босса в игровом диалоге — печатается по буквам. Первое нажатие
## (E / A / клик) допечатывает, второе закрывает; без нажатий закроется само.
func boss_intro(name: String, line: String) -> void:
	var top := ColorRect.new()
	var bottom := ColorRect.new()
	for r in [top, bottom]:
		r.color = UI.INK
		r.size = Vector2(480, 0)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(r)
	bottom.position.y = 270
	var title := UI.label(name, UI.TITLE, UI.PAPER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(480, 24)
	title.position.y = 6
	title.modulate.a = 0.0
	root.add_child(title)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel(true))
	panel.position = Vector2(40, 192)
	panel.custom_minimum_size = Vector2(400, 66)
	panel.modulate.a = 0.0
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var who := UI.label(name.get_slice(" ", 1) if name.contains(" ") else name, UI.TEXT, UI.GOLD)
	who.add_theme_font_override("font", Game.font_bold)
	box.add_child(who)
	var text := UI.label(line, UI.TEXT + 1, UI.PAPER)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(384, 30)
	text.visible_characters = 0
	box.add_child(text)
	var hint := UI.label("[%s] дальше" % Game.key_name("interact"), UI.SMALL, UI.MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.modulate.a = 0.0
	box.add_child(hint)

	var t := create_tween().set_parallel()
	t.tween_property(top, "size:y", 34.0, 0.3)
	t.tween_property(bottom, "size:y", 80.0, 0.3)
	t.tween_property(bottom, "position:y", 190.0, 0.3)
	t.tween_property(title, "modulate:a", 1.0, 0.3).set_delay(0.2)
	t.tween_property(panel, "modulate:a", 1.0, 0.25).set_delay(0.35)
	Game.shake(3.0)
	await get_tree().create_timer(0.6).timeout

	# печать по буквам, с «бубнением» на каждой второй букве
	var shown := 0.0
	var total := line.length()
	var waited := 0.0
	var typed := false
	while true:
		await get_tree().process_frame
		var dt := get_process_delta_time()
		var pressed := Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack")
		if not typed:
			var before := int(shown)
			shown = minf(shown + dt * 28.0, total)
			if pressed:
				shown = total
			text.visible_characters = int(shown)
			if int(shown) != before and int(shown) % 2 == 0 and line[int(shown) - 1] != " ":
				Fx.sfx("move", 0.45)
			if int(shown) >= total:
				typed = true
				var ht := create_tween()
				ht.tween_property(hint, "modulate:a", 1.0, 0.2)
				Game.shake(2.0)
		else:
			waited += dt
			if pressed:
				Fx.sfx("confirm")
				break
			if waited > 6.0:
				break

	var t2 := create_tween().set_parallel()
	t2.tween_property(top, "size:y", 0.0, 0.3)
	t2.tween_property(bottom, "size:y", 0.0, 0.3)
	t2.tween_property(bottom, "position:y", 270.0, 0.3)
	t2.tween_property(title, "modulate:a", 0.0, 0.2)
	t2.tween_property(panel, "modulate:a", 0.0, 0.2)
	await t2.finished
	for n in [top, bottom, title, panel]:
		n.queue_free()

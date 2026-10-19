extends Control
## Выбор улучшения после комнаты — три алерта, как DonationAlerts на стриме:
## сверху картинка, под ней «ник — сумма» акцентом, ниже сообщение и что даёт донат.

signal chosen(id: String)

const UI := preload("res://scripts/ui/ui.gd")
const NICKS := ["ЛУДОЖОП", "ЛУНОГРЫЗ", "ГРЕЧЕСКИЙ КУПЕЦ"]
const OPTIONS := [
	{
		"id": "heal", "sum": "300 ₽", "pic": "res://assets/sprites/alert_heal.png",
		"msg": "Озон, это на шаурму. Отхилься, брат",
		"effect": "Здоровье до максимума",
	},
	{
		"id": "life", "sum": "1 000 ₽", "pic": "res://assets/sprites/alert_life.png",
		"msg": "Держи вторую жизнь, а то знаю я тебя",
		"effect": "Вторая жизнь: воскреснешь с половиной здоровья",
	},
	{
		"id": "rage", "sum": "500 ₽", "pic": "res://assets/sprites/alert_rage.png",
		"msg": "ВРЕЖЬ ИМ!!!",
		"effect": "Урон +50%, макс. здоровье −30%",
	},
]

var _buttons: Array[Button] = []
var _pics: Array[TextureRect] = []
var _t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.07, 0.05, 0.1, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var head := UI.label("Чат задонатил. Выбери один донат", UI.SMALL, UI.MUTED)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.size = Vector2(480, 12)
	head.position = Vector2(0, 22)
	add_child(head)

	var nicks := NICKS.duplicate()
	nicks.shuffle()
	for i in OPTIONS.size():
		var o: Dictionary = OPTIONS[i]
		var b := _alert(o, nicks[i])
		b.position = Vector2(12 + i * 156, 44)
		add_child(b)
		_buttons.append(b)
		if o.id == "life" and Game.run.extra_life:
			b.disabled = true
			b.modulate = Color(1, 1, 1, 0.45)
			b.get_node("Effect").text = "Вторая жизнь уже есть"
		b.pressed.connect(_pick.bind(o.id))
		b.focus_entered.connect(func(): Fx.sfx("move"))
		b.mouse_entered.connect(func():
			if not b.disabled:
				b.grab_focus())
		# алерты выскакивают по очереди
		b.pivot_offset = b.size * 0.5
		b.scale = Vector2.ZERO
		var t := create_tween()
		t.tween_interval(0.25 * i)
		t.tween_property(b, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_callback(func(): Game.voice("donation"))
	for b in _buttons:
		if not b.disabled:
			b.call_deferred("grab_focus")
			break


func _alert(o: Dictionary, nick: String) -> Button:
	var b := Button.new()
	b.size = Vector2(144, 170)
	b.focus_mode = Control.FOCUS_ALL
	# плашка алерта: тёмная, выбранная — с золотой рамкой поверх
	var card := UI.panel(true)
	card.modulate_color = Color(1, 1, 1, 0.94)
	b.add_theme_stylebox_override("normal", card)
	b.add_theme_stylebox_override("disabled", card)
	var hover := UI.panel(true)
	hover.modulate_color = Color(1.25, 1.2, 1.3)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	var focus := StyleBoxTexture.new()
	focus.texture = preload("res://assets/sprites/panel_focus.png")
	focus.draw_center = false
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		focus.set_texture_margin(side, 4)
	b.add_theme_stylebox_override("focus", focus)

	var pic := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = load(o.pic)
	atlas.region = Rect2(0, 0, 40, 40)
	pic.texture = atlas
	pic.position = Vector2(52, 6)
	pic.size = Vector2(40, 40)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pic)
	_pics.append(pic)

	# «ник — сумма»: ник и сумма акцентом, как в DonationAlerts
	var line := RichTextLabel.new()
	line.bbcode_enabled = true
	line.fit_content = true
	line.scroll_active = false
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_color_override("font_outline_color", UI.INK)
	line.add_theme_constant_override("outline_size", 2)
	line.add_theme_font_size_override("normal_font_size", UI.TEXT)
	line.position = Vector2(6, 52)
	line.size = Vector2(132, 12)
	line.text = "[center][color=#e8c35a]%s[/color] — [color=#e8c35a]%s[/color][/center]" % [nick, o.sum]
	b.add_child(line)

	var msg := UI.label(o.msg, UI.TEXT, UI.PAPER)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.position = Vector2(6, 76)
	msg.size = Vector2(132, 40)
	b.add_child(msg)

	var eff := UI.label(o.effect, UI.SMALL, Color("#8fd0ff"))
	eff.name = "Effect"
	eff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	eff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eff.position = Vector2(6, 124)
	eff.size = Vector2(132, 40)
	b.add_child(eff)
	return b


func _process(delta: float) -> void:
	_t += delta
	var f := int(_t * 3.0) % 2
	for p in _pics:
		(p.texture as AtlasTexture).region = Rect2(f * 40, 0, 40, 40)


func _pick(id: String) -> void:
	match id:
		"heal":
			Game.run.hp = Game.run.max_hp
		"life":
			Game.run.extra_life = true
		"rage":
			Game.run.damage *= 1.5
			Game.run.max_hp = max(1, int(round(Game.run.max_hp * 0.7)))
			Game.run.hp = min(Game.run.hp, Game.run.max_hp)
	Game.run_changed.emit()
	Game.voice("donation_" + id)
	Fx.sfx("coin")
	# выбранный алерт вспыхивает и подрастает, остальные гаснут
	var chosen_btn: Button = _buttons[OPTIONS.map(func(o): return o.id).find(id)]
	var t := create_tween().set_parallel()
	for b in _buttons:
		b.disabled = true
		if b == chosen_btn:
			b.pivot_offset = b.size * 0.5
			t.tween_property(b, "scale", Vector2(1.1, 1.1), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.tween_property(b, "modulate", Color(1.5, 1.4, 1.1), 0.08)
		else:
			t.tween_property(b, "modulate:a", 0.15, 0.15)
	var ok := UI.label("Донат принят!", UI.TITLE, UI.GOLD)
	ok.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ok.size = Vector2(480, 24)
	ok.position = Vector2(0, 226)
	add_child(ok)
	await get_tree().create_timer(0.7).timeout
	var t2 := create_tween()
	t2.tween_property(self, "modulate:a", 0.0, 0.25)
	await t2.finished
	chosen.emit(id)
	queue_free()

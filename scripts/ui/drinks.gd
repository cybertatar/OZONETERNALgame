extends Control
## Стол Озона: что выпить перед забегом. Напиток — способность на забег.
## closed(id) — выпитый напиток или "" если закрыли, ничего не выбрав.

signal closed(id: String)

const UI := preload("res://scripts/ui/ui.gd")

var _done := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.07, 0.05, 0.1, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel(true))
	panel.position = Vector2(80, 36)
	panel.custom_minimum_size = Vector2(320, 0)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	box.add_child(UI.label("Что выпить перед забегом?", UI.TITLE, UI.GOLD))
	var first: Button
	for id in Game.DRINKS:
		var d: Dictionary = Game.DRINKS[id]
		var have: bool = id in Game.save.drinks
		var b := Button.new()
		UI.button_styles(b)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.icon = load(d.icon) if have else null
		b.custom_minimum_size = Vector2(0, 34)
		b.add_theme_constant_override("h_separation", 6)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if have:
			var mark := "  — уже выпито" if Game.drunk == id else ""
			b.text = "%s%s\n%s В забеге: %s, перезарядка %d с" % [d.name, mark, d.desc, Game.key_name("ability"), d.cooldown]
			b.pressed.connect(_pick.bind(id))
			if first == null or Game.save.drink == id:
				first = b
		else:
			b.text = "???\nОткроется после следующего босса"
			b.disabled = true
		box.add_child(b)
	var hint := UI.label("[%s] или клик — выпить     [%s] — отойти от стола" % [Game.key_name("interact"), Game.key_name("back")], UI.SMALL, UI.MUTED)
	box.add_child(hint)
	if first:
		first.call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_finish("")
	elif event.is_action_pressed("interact"):
		# E / A выпивает то, что выделено
		get_viewport().set_input_as_handled()
		var f := get_viewport().gui_get_focus_owner() as Button
		if f and not f.disabled:
			f.pressed.emit()


func _pick(id: String) -> void:
	# дать увидеть вспышку на выбранной кнопке
	await get_tree().create_timer(0.18).timeout
	_finish(id)


func _finish(id: String) -> void:
	if _done:
		return
	_done = true
	closed.emit(id)
	queue_free()

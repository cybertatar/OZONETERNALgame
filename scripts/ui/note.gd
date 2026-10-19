extends Control
## Записка с отрывком «Тихого Дена», выпавшая с босса. Озон читает её прямо в комнате;
## E / A / клик — спрятать в карман (отрывок появится на компьютере в квартире).

const UI := preload("res://scripts/ui/ui.gd")

var index := 0
## Читают дома со стены — тогда без подсказки «на компьютере дома».
var at_home := false
var _player: Node


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var w = Game.world()
	if w and w.player:
		_player = w.player
		_player.controls = false
	var dim := ColorRect.new()
	dim.color = Color(0.07, 0.05, 0.1, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel(false))
	panel.position = Vector2(80, 30)
	panel.custom_minimum_size = Vector2(320, 0)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	box.add_child(UI.label("Записка", UI.TITLE, UI.INK, false))
	box.add_child(UI.label("«Тихий Ден», отрывок %d" % (index + 1), UI.SMALL, Color("#7a6a50"), false))
	var text := Label.new()
	text.text = "«%s»" % Game.book()[index].text
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(304, 0)
	text.add_theme_font_size_override("font_size", UI.TEXT + 1)
	text.add_theme_color_override("font_color", UI.INK)
	box.add_child(text)
	var hint := UI.label("[%s] %s" % [Game.key_name("interact"), "повесить обратно" if at_home else "забрать домой"], UI.SMALL, Color("#7a6a50"), false)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(hint)

	# листок выезжает снизу
	panel.pivot_offset = Vector2(160, 100)
	panel.position.y += 30
	panel.modulate.a = 0.0
	var t := create_tween().set_parallel()
	t.tween_property(panel, "position:y", 30.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(panel, "modulate:a", 1.0, 0.2)
	Fx.sfx("pop")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") \
			or event.is_action_pressed("ui_cancel") or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		Fx.sfx("confirm")
		if _player and is_instance_valid(_player):
			_player.controls = true
		if not at_home:
			Game.world().hud.toast("Записка будет висеть дома на стене, отрывок — на компьютере", 2.5)
		queue_free()

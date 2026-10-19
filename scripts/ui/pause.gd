extends Control
## Пауза: продолжить, сдаться (проснуться дома) или выйти из игры.

const UI := preload("res://scripts/ui/ui.gd")

var _box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.07, 0.05, 0.1, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_box = VBoxContainer.new()
	_box.position = Vector2(170, 80)
	_box.custom_minimum_size = Vector2(140, 0)
	_box.add_theme_constant_override("separation", 4)
	add_child(_box)
	var title := UI.label("Пауза", 16, UI.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(title)
	_add("Продолжить", close)
	_add("Сдаться и проснуться дома", func():
		close()
		if not Game.run.is_empty() and Game.world() and not Game.world().player.in_hub:
			Game.player_died())
	_add("Выйти из игры", func(): get_tree().quit())


func _add(text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	UI.button_styles(b)
	b.pressed.connect(cb)
	_box.add_child(b)


func open() -> void:
	visible = true
	get_tree().paused = true
	(_box.get_child(1) as Button).grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		close()

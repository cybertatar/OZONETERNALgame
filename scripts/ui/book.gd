extends Control
## Компьютер Озона: «Тихий Ден», собранный из найденных отрывков.

signal closed

const UI := preload("res://scripts/ui/ui.gd")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.07, 0.05, 0.1, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel(false))
	panel.position = Vector2(60, 20)
	panel.size = Vector2(360, 230)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var book: Array = Game.book()
	var found: Array = Game.save.pages
	box.add_child(UI.label("«Тихий Ден»", 16, UI.INK, false))
	box.add_child(UI.label("Собрано отрывков: %d из %d" % [found.size(), book.size()], UI.SMALL, Color("#7a6a50"), false))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(340, 172)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var text := Label.new()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(330, 0)
	text.add_theme_font_size_override("font_size", 11)
	text.add_theme_color_override("font_color", UI.INK)
	var parts := []
	for i in book.size():
		if i in found:
			parts.append(book[i].text)
		else:
			parts.append("[отрывок %d ещё не найден]" % (i + 1))
	text.text = "\n\n".join(parts) if not book.is_empty() else "Пусто."
	scroll.add_child(text)
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()

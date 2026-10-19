extends Node
## Корневой узел: меняет «мир» (квартира или комната забега) и держит паузу.

const WORLDS := {
	"hub": "res://scripts/hub.gd",
	"room": "res://scripts/room.gd",
}

var _current: Node
var _fade: ColorRect
var _pause: Control


func _ready() -> void:
	Game.register_main(self)
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color("#120e14")
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	_pause = preload("res://scripts/ui/pause.gd").new()
	layer.add_child(_pause)
	show_world("hub")


func show_world(kind: String) -> void:
	if _current:
		_current.queue_free()
		await _current.tree_exited
	_fade.modulate.a = 1.0
	_current = Node2D.new()
	_current.set_script(load(WORLDS[kind]))
	add_child(_current)
	Game.set_world(_current)
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 0.0, 0.6 if kind == "hub" else 0.3)


func fade_out(seconds := 0.4) -> void:
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 1.0, seconds)
	await t.finished


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not _pause.visible:
		_pause.open()
		get_viewport().set_input_as_handled()

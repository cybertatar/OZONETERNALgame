extends Node2D
## Ловушки на полу, клетка 16×16: колья ("spikes") и яд ("poison").

var kind := "spikes"
## Картинка ловушки (по уровню): колья, стекло, бамбук; яд, бензин, рисовое поле.
var texture_name := ""
var phase := 0.0
var t := 0.0
var sprite: Sprite2D
var _hit_this_cycle := false

const HIDDEN := 1.5
const WARN := 0.5
const UP := 0.6


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.texture = load("res://assets/sprites/%s.png" % (texture_name if texture_name != "" else kind))
	sprite.hframes = 3 if kind == "spikes" else 2
	add_child(sprite)
	t = phase


func _physics_process(delta: float) -> void:
	t += delta
	var area := Rect2(global_position + Vector2(1, 1), Vector2(14, 14))
	if kind == "spikes":
		var cycle := fmod(t, HIDDEN + WARN + UP)
		var st := 0 if cycle < HIDDEN else (1 if cycle < HIDDEN + WARN else 2)
		sprite.frame = st
		if st != 2:
			_hit_this_cycle = false
			return
		var p := get_tree().get_first_node_in_group("player")
		if p and area.has_point(p.global_position) and not _hit_this_cycle:
			if p.hurt(8, Vector2.ZERO, 0.0):
				_hit_this_cycle = true
		for e in get_tree().get_nodes_in_group("enemies"):
			if area.has_point(e.global_position) and e.has_method("on_hurt") and not e.get_meta("spiked", false):
				e.set_meta("spiked", true)
				e.hurt(10, Vector2.ZERO, 0.0)
				get_tree().create_timer(UP).timeout.connect(func(): if is_instance_valid(e): e.set_meta("spiked", false))
	else:
		sprite.frame = int(t * 2.0) % 2
		var p := get_tree().get_first_node_in_group("player")
		if p and area.has_point(p.global_position):
			p.slow = 0.7
			p.poison(delta)

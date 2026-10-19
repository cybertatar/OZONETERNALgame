extends Node2D
## Лужа от пива «Бояринъ»: замедляет врагов и разъедает их.

const LIFE := 6.0
const TICK := 0.5
const DAMAGE := 4.0
const RX := 30.0
const RY := 18.0

var t := 0.0
var tick := 0.0
var sprite: Sprite2D


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = preload("res://assets/sprites/puddle.png")
	sprite.hframes = 4
	add_child(sprite)


func _physics_process(delta: float) -> void:
	t += delta
	tick -= delta
	if t < 0.24:
		sprite.frame = int(t / 0.08)
	else:
		sprite.frame = 2 + int(t * 3.0) % 2
	if t > LIFE - 0.6:
		modulate.a = (LIFE - t) / 0.6
	if t >= LIFE:
		queue_free()
		return
	var do_tick := tick <= 0.0
	if do_tick:
		tick = TICK
	for e in get_tree().get_nodes_in_group("hittable"):
		var d: Vector2 = e.global_position - global_position
		if (d.x / RX) * (d.x / RX) + (d.y / RY) * (d.y / RY) <= 1.0:
			e.slow = 0.5
			if do_tick:
				e.hurt(DAMAGE * Game.run.get("damage", 1.0), Vector2.ZERO, 0.0)

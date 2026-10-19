extends Node2D
## Снаряд дальнего врага (чеснок, говно, таракан): летит прямо, бьёт Озона,
## разбивается о стены.

const SPEED := 115.0
const DAMAGE := 6

var dir := Vector2.RIGHT
var texture_name := "garlic"
var life := 3.0
var sprite: Sprite2D


func _ready() -> void:
	z_index = 2
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/sprites/%s.png" % texture_name)
	sprite.hframes = 2
	add_child(sprite)


func _physics_process(delta: float) -> void:
	position += dir * SPEED * delta
	life -= delta
	sprite.frame = int(life * 8.0) % 2
	if texture_name == "roach":
		sprite.rotation = dir.angle()  # таракан летит головой вперёд и сучит лапками
	else:
		sprite.rotation = round(life * 10.0) * PI / 4.0
	var p := get_tree().get_first_node_in_group("player")
	if p and p.global_position.distance_to(global_position + Vector2(0, 8)) < 9.0:
		if p.hurt(DAMAGE, dir, 90.0):
			_pop()
			return
	if life <= 0.0 or not Game.world().is_floor(global_position + Vector2(0, 10)):
		_pop()


func _pop() -> void:
	Fx.dust(get_parent(), global_position + Vector2(0, 8), 4)
	queue_free()

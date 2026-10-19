extends CharacterBody2D
## Общее для врагов: здоровье, получение урона, отбрасывание, вспышка, смерть.

signal died(enemy: Node)

var max_hp := 30.0
var hp := 30.0
var hit_radius := 8.0
var push := Vector2.ZERO
var slow := 1.0
var active := false
var dead := false
var sprite: Sprite2D
var shadow: Sprite2D
var knock_resist := 1.0


func setup_body(texture: Texture2D, hframes: int, vframes: int, offset_y: float, shadow_tex: Texture2D, radius: float) -> void:
	add_to_group("enemies")
	add_to_group("hittable")
	collision_layer = 4
	collision_mask = 1 | 4
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	shape.position = Vector2(0, -radius * 0.5)
	add_child(shape)
	shadow = Sprite2D.new()
	shadow.texture = shadow_tex
	add_child(shadow)
	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.hframes = hframes
	sprite.vframes = vframes
	sprite.offset = Vector2(0, offset_y)
	sprite.material = Game.flash_material()
	add_child(sprite)


## Появление: вырастает из пола.
func appear(seconds := 0.45) -> void:
	sprite.scale = Vector2(1.4, 0.0)
	Fx.dust(get_parent(), global_position, 6)
	var t := create_tween()
	t.tween_property(sprite, "scale", Vector2(1, 1), seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	active = true


func player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


func hurt(amount: float, dir: Vector2, knock: float) -> bool:
	if dead:
		return false
	hp -= amount
	push = dir * knock * knock_resist
	Fx.flash(sprite)
	Fx.number(get_parent(), global_position + Vector2(0, -sprite_height() - 4), int(round(amount)))
	on_hurt()
	if hp <= 0.0:
		_die()
	return true


func sprite_height() -> float:
	return -sprite.offset.y * 2.0


func on_hurt() -> void:
	pass


func _die() -> void:
	dead = true
	remove_from_group("enemies")
	remove_from_group("hittable")
	collision_layer = 0
	died.emit(self)
	Fx.sfx("pop")
	Fx.dust(get_parent(), global_position, 8)
	var t := create_tween()
	t.tween_property(sprite, "scale", Vector2(1.3, 0.1), 0.18)
	t.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	t.tween_callback(queue_free)


func apply_motion(delta: float) -> void:
	push = push.move_toward(Vector2.ZERO, 700.0 * delta)
	velocity = velocity * slow + push
	move_and_slide()
	slow = 1.0

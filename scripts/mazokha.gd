extends "res://scripts/enemy.gd"
## Босс Мазоха: удар двумя руками по площади, таран через всю комнату,
## призыв грязных носков. На половине здоровья злится: быстрее и больше носков.

const FRAMES := ["idle0", "idle1", "walk0", "walk1", "slam0", "slam1", "charge", "summon", "hurt"]
const NAME := "Александр Мазоха"

var state := "idle"
var t := 0.0
var anim := 0.0
var attack_cd := 1.5
var summon_timer := 4.0
var dir := Vector2.DOWN
var hit_done := false
var angry := false
var _telegraph: Node
## Через сколько секунд тишины Мазоха снова скажет свою присказку.
var taunt_t := 45.0


func _ready() -> void:
	max_hp = 450.0
	hp = max_hp
	hit_radius = 18.0
	knock_resist = 0.12
	setup_body(preload("res://assets/sprites/mazokha.png"), 9, 1, -44.0, preload("res://assets/sprites/shadow_l.png"), 12.0)
	remove_from_group("enemies")  # носки считаются отдельно
	collision_mask = 1  # таран останавливают только стены и мебель
	add_to_group("boss")


func start() -> void:
	active = true
	state = "chase"
	# в начале боя — длинная речь один раз, дальше изредка присказка
	Game.voice("boss_fight", "mazokha")
	Game.boss_hp_changed.emit(int(hp), int(max_hp), NAME)


func sprite_height() -> float:
	return 90.0


func _physics_process(delta: float) -> void:
	anim += delta
	if dead:
		return
	velocity = Vector2.ZERO
	var p := player()
	if active and p:
		t += delta
		attack_cd -= delta
		summon_timer -= delta
		if not Game.voice_playing("mazokha"):
			taunt_t -= delta
			if taunt_t <= 0.0 and Game.voice("boss_taunt", "mazokha"):
				taunt_t = randf_range(45.0, 75.0)
		_think(p)
	apply_motion(delta)
	_animate()


func _think(p: Node2D) -> void:
	var to := p.global_position - global_position
	var speed := 48.0 if angry else 38.0
	match state:
		"chase":
			velocity = to.normalized() * speed
			sprite.flip_h = to.x < 0.0
			if attack_cd <= 0.0:
				var socks := get_tree().get_nodes_in_group("enemies").size()
				if summon_timer <= 0.0 and socks < 5:
					_go("summon")
				elif to.length() < 70.0:
					_start_slam(to)
				elif to.length() > 90.0 or randf() < 0.5:
					_start_charge(to)
				else:
					attack_cd = 0.4
		"slam_wind":
			if t >= (0.6 if angry else 0.75):
				_go("slam_hit")
				var center := global_position + dir * 20.0
				Fx.ring(get_parent(), center, 46.0, Color("#f4efe2"))
				Fx.dust(get_parent(), center, 12)
				Game.shake(7.0)
				if p.global_position.distance_to(center) < 46.0:
					p.hurt(14, (p.global_position - center).normalized(), 240.0)
		"slam_hit":
			if t >= 0.6:
				_recover(1.1)
		"charge_wind":
			sprite.flip_h = dir.x < 0.0
			if t >= (0.5 if angry else 0.65):
				_go("charge")
				hit_done = false
		"charge":
			velocity = dir * 270.0
			if t > 0.05 and _int_dust():
				Fx.dust(get_parent(), global_position, 2)
			if not hit_done and global_position.distance_to(p.global_position) < 24.0:
				hit_done = true
				p.hurt(12, dir, 260.0)
			if t > 0.08 and get_slide_collision_count() > 0:
				_go("stunned")
				Game.shake(6.0)
				Fx.dust(get_parent(), global_position + dir * 12.0, 10)
				Game.voice("boss_wall", "mazokha")
			elif t >= 1.4:
				_recover(0.5)
		"stunned":
			if t >= 1.3:
				_recover(0.6)
		"summon":
			if t >= 0.5 and not hit_done:
				hit_done = true
				var n := 3 if angry else 2
				for i in n:
					var ang := randf() * TAU
					var pos := global_position + Vector2.from_angle(ang) * randf_range(50, 90)
					Game.world().spawn_sock(pos, i == n - 1)
				Game.voice("boss_summon", "mazokha")
			if t >= 0.9:
				summon_timer = 7.0 if angry else 10.0
				_recover(0.6)
		"recover":
			if t >= _recover_time:
				_go("chase")


var _recover_time := 0.5
var _dust_t := 0.0


func _int_dust() -> bool:
	_dust_t += get_physics_process_delta_time()
	if _dust_t > 0.05:
		_dust_t = 0.0
		return true
	return false


func _start_slam(to: Vector2) -> void:
	dir = to.normalized()
	_go("slam_wind")
	_telegraph = Fx.telegraph_circle(get_parent(), global_position + dir * 20.0, 46.0, 0.6 if angry else 0.75)


func _start_charge(to: Vector2) -> void:
	dir = to.normalized()
	_go("charge_wind")
	_telegraph = Fx.telegraph_line(get_parent(), global_position + Vector2(0, -6), dir, 320.0, 28.0, 0.5 if angry else 0.65)


func _recover(seconds: float) -> void:
	_go("recover")
	_recover_time = seconds
	attack_cd = 0.9 if angry else 1.3
	hit_done = false


func _go(s: String) -> void:
	state = s
	t = 0.0
	if s == "summon":
		hit_done = false


func on_hurt() -> void:
	Game.boss_hp_changed.emit(int(max(hp, 0)), int(max_hp), NAME)
	if not angry and hp < max_hp * 0.5:
		angry = true
		Game.world().hud.toast("Мазоха разозлился!")
		Game.voice("boss_angry", "mazokha")


func _die() -> void:
	dead = true
	Game.voice_stop("mazokha")
	remove_from_group("hittable")
	remove_from_group("boss")
	collision_layer = 0
	active = false
	if _telegraph and is_instance_valid(_telegraph):
		_telegraph.queue_free()
	Game.boss_hp_changed.emit(0, int(max_hp), NAME)
	Engine.time_scale = 0.3
	Game.shake(8.0)
	for i in 6:
		Fx.flash(sprite, Color.WHITE, 0.1)
		Fx.dust(get_parent(), global_position + Vector2(randf_range(-20, 20), randf_range(-60, 0)), 6)
		await get_tree().create_timer(0.12, true, false, true).timeout
	Engine.time_scale = 1.0
	sprite.frame = FRAMES.find("hurt")
	var tw := create_tween()
	tw.tween_property(sprite, "rotation", PI / 2 * (-1.0 if sprite.flip_h else 1.0), 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sprite, "position", Vector2(0, -6), 0.4)
	await tw.finished
	Game.shake(5.0)
	died.emit(self)


func _animate() -> void:
	var name := "idle%d" % (int(anim * 2.0) % 2)
	sprite.position.x = 0.0
	match state:
		"chase":
			name = "walk%d" % (int(anim * 4.0) % 2)
		"slam_wind":
			name = "slam0"
		"slam_hit":
			name = "slam1"
		"charge_wind":
			name = "charge"
			sprite.position.x = round(sin(t * 70.0))
		"charge":
			name = "charge"
		"stunned":
			name = "hurt"
		"summon":
			name = "summon"
	sprite.frame = FRAMES.find(name)

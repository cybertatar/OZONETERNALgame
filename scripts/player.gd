extends CharacterBody2D
## Озон: ходьба, комбо из трёх ударов, усиленный удар, рывок, способность-алкоголь.

const SPEED := 100.0
const DASH_SPEED := 300.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 2.0
const ATTACKS := [
	{"dmg": 10, "reach": 32, "arc": 110, "knock": 60, "time": 0.22, "frame": "punchA"},
	{"dmg": 10, "reach": 32, "arc": 110, "knock": 60, "time": 0.22, "frame": "punchB"},
	{"dmg": 16, "reach": 36, "arc": 130, "knock": 150, "time": 0.32, "frame": "punchA"},
]
const HEAVY_WINDUP := 0.32
const HEAVY_RECOVER := 0.28
const HEAVY_DMG := 28.0

const FRAMES := ["idle0", "idle1", "walk0", "walk1", "walk2", "walk3",
	"punchA", "punchB", "heavy0", "heavy1", "vomit", "hurt", "drink"]

enum S { MOVE, ATTACK, HEAVY, DASH, ABILITY, DEAD, DRINK }

var hit_radius := 7.0
var in_hub := false
var controls := true
var state := S.MOVE
var state_time := 0.0
var aim := Vector2.DOWN
var face := Vector2.DOWN
var push := Vector2.ZERO
var slow := 1.0
var invuln := 0.0
var dash_cd := 0.0
var ability_cd := 0.0
var combo := 0
var combo_reset := 0.0
var queued := ""
var hit_done := false
var dash_dir := Vector2.DOWN
var anim_time := 0.0
var interact_target: Node = null

var sprite: Sprite2D
var marker: AimMarker
var _ghost_time := 0.0


class AimMarker extends Node2D:
	var dir := Vector2.DOWN

	func _draw() -> void:
		var p := (dir * 13.0).round() + Vector2(0, -6)
		var side := dir.orthogonal()
		var col := Color(1, 1, 1, 0.55)
		draw_colored_polygon(PackedVector2Array([
			p + dir * 3.0, p + side * 2.5, p - side * 2.5]), col)


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	shape.position = Vector2(0, -3)
	add_child(shape)
	var shadow := Sprite2D.new()
	shadow.texture = preload("res://assets/sprites/shadow_m.png")
	shadow.position = Vector2(0, 0)
	add_child(shadow)
	marker = AimMarker.new()
	marker.z_index = -1
	add_child(marker)
	sprite = Sprite2D.new()
	sprite.texture = preload("res://assets/sprites/ozon.png")
	sprite.hframes = FRAMES.size()
	sprite.vframes = 3
	sprite.offset = Vector2(0, -15)
	sprite.material = Game.flash_material()
	add_child(sprite)


# --- ввод ---------------------------------------------------------------------

func _move_input() -> Vector2:
	if not controls:
		return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _update_aim(move: Vector2) -> void:
	if Game.using_pad:
		var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
		if stick.length() > 0.3:
			aim = stick.normalized()
		elif move.length() > 0.2:
			aim = move.normalized()
	else:
		var to := get_global_mouse_position() - (global_position + Vector2(0, -12))
		if to.length() > 2.0:
			aim = to.normalized()
	marker.dir = aim
	marker.visible = not in_hub and state != S.DEAD
	marker.queue_redraw()


func _pressed(action: String) -> bool:
	return controls and Input.is_action_just_pressed(action)


# --- цикл ---------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	state_time += delta
	invuln = maxf(invuln - delta, 0.0)
	dash_cd = maxf(dash_cd - delta, 0.0)
	ability_cd = maxf(ability_cd - delta, 0.0)
	combo_reset = maxf(combo_reset - delta, 0.0)
	if combo_reset <= 0.0 and state != S.ATTACK:
		combo = 0
	push = push.move_toward(Vector2.ZERO, 900.0 * delta)
	var move := _move_input()
	_update_aim(move)

	match state:
		S.MOVE:
			velocity = move * SPEED * slow
			if move.length() > 0.1:
				face = move
			# у предмета A на геймпаде — действие, а не рывок
			if interact_target and _pressed("interact"):
				interact_target.interact(self)
			elif _pressed("dash"):
				if dash_cd <= 0.0:
					_start_dash(move)
				else:
					_deny("dash")
			elif _pressed("attack"):
				_start_attack()
			elif _pressed("heavy"):
				_start_heavy()
			elif _pressed("ability"):
				_try_ability()
		S.ATTACK:
			_process_attack(move)
		S.HEAVY:
			_process_heavy(move)
		S.DASH:
			velocity = dash_dir * DASH_SPEED
			_ghost_time -= delta
			if _ghost_time <= 0.0:
				_ghost_time = 0.03
				_spawn_ghost()
			if state_time >= DASH_TIME:
				state = S.MOVE
				dash_cd = DASH_COOLDOWN
				velocity = dash_dir * SPEED
		S.ABILITY:
			_process_ability()
		S.DEAD, S.DRINK:
			velocity = Vector2.ZERO

	velocity += push
	move_and_slide()
	slow = 1.0
	_find_interactable()
	_animate(delta)


# --- атаки --------------------------------------------------------------------

func _start_attack() -> void:
	state = S.ATTACK
	state_time = 0.0
	hit_done = false
	queued = ""
	face = aim
	push += aim * 70.0


func _process_attack(move: Vector2) -> void:
	var a: Dictionary = ATTACKS[combo]
	velocity = move * SPEED * 0.25
	if not hit_done and state_time >= 0.06:
		hit_done = true
		var dmg: float = a.dmg * Game.run.get("damage", 1.0)
		var hits := Game.hit_arc(global_position, aim, a.reach, a.arc, dmg, a.knock, "hittable")
		Fx.swing(self, aim, a.reach, combo == 2)
		Fx.sfx("swing", 1.0 + combo * 0.1)
		if hits > 0:
			Fx.sfx("hit")
			Game.shake(1.5 if combo < 2 else 3.0)
			Game.hitstop(0.03 if combo < 2 else 0.06)
	if state_time > 0.08:
		if _pressed("attack"):
			queued = "attack"
		elif _pressed("heavy"):
			queued = "heavy"
		elif _pressed("dash") and dash_cd <= 0.0:
			_start_dash(move)
			return
	if state_time >= a.time:
		combo = (combo + 1) % ATTACKS.size()
		combo_reset = 0.45
		state = S.MOVE
		if queued == "attack":
			_start_attack()
		elif queued == "heavy":
			_start_heavy()


func _start_heavy() -> void:
	state = S.HEAVY
	state_time = 0.0
	hit_done = false
	face = aim
	combo = 0


func _process_heavy(move: Vector2) -> void:
	velocity = move * SPEED * 0.15
	if state_time < HEAVY_WINDUP:
		face = aim
		if _pressed("dash") and dash_cd <= 0.0:
			_start_dash(move)
		return
	if not hit_done:
		hit_done = true
		var dmg: float = HEAVY_DMG * Game.run.get("damage", 1.0)
		var center := global_position + aim * 20.0
		Game.hit_arc(center, aim, 30.0, 360.0, dmg, 190.0, "hittable")
		Fx.ring(get_parent(), center, 30.0, Color("#f4efe2"))
		Fx.dust(get_parent(), center, 6)
		Fx.sfx("slam")
		Game.shake(4.0)
		Game.hitstop(0.05)
	if state_time >= HEAVY_WINDUP + HEAVY_RECOVER:
		state = S.MOVE


## Кнопка нажата, но действие ещё на перезарядке: ячейка в HUD вздрагивает, звук отказа.
func _deny(action: String) -> void:
	Fx.sfx("deny")
	var hud = Game.world().hud
	if hud:
		hud.deny(action)


func _start_dash(move: Vector2) -> void:
	Fx.sfx("dash")
	state = S.DASH
	state_time = 0.0
	dash_dir = move.normalized() if move.length() > 0.2 else aim
	face = dash_dir
	invuln = maxf(invuln, DASH_TIME + 0.06)
	push = Vector2.ZERO
	Fx.dust(get_parent(), global_position, 3)


func _spawn_ghost() -> void:
	var g := Sprite2D.new()
	g.texture = sprite.texture
	g.hframes = sprite.hframes
	g.vframes = sprite.vframes
	g.frame = sprite.frame
	g.flip_h = sprite.flip_h
	g.offset = sprite.offset
	g.global_position = global_position
	g.modulate = Color(0.75, 0.85, 1.0, 0.5)
	get_parent().add_child(g)
	var t := g.create_tween()
	t.tween_property(g, "modulate:a", 0.0, 0.2)
	t.tween_callback(g.queue_free)


# --- способность ----------------------------------------------------------------

func _try_ability() -> void:
	if in_hub or Game.run.is_empty() or Game.run.drink == "":
		return
	if ability_cd > 0.0:
		_deny("ability")
		return
	state = S.ABILITY
	state_time = 0.0
	hit_done = false
	face = aim
	ability_cd = Game.DRINKS[Game.run.drink].cooldown
	Fx.sfx("slam" if Game.run.drink == "vodka" else "drink")
	Game.voice("drink_" + Game.run.drink)


func _process_ability() -> void:
	velocity = Vector2.ZERO
	var drink: String = Game.run.drink
	if drink == "beer":
		if not hit_done and state_time >= 0.18:
			hit_done = true
			var p := preload("res://scripts/puddle.gd").new()
			p.position = global_position + aim * 34.0
			Game.world().decals.add_child(p)
		if state_time >= 0.45:
			state = S.MOVE
	elif drink == "vodka":
		# крутится на месте и бьёт всех вокруг
		var dirs := [Vector2.DOWN, Vector2.RIGHT, Vector2.UP, Vector2.LEFT]
		face = dirs[int(state_time / 0.06) % 4]
		if not hit_done and state_time >= 0.12:
			hit_done = true
			var dmg: float = 35.0 * Game.run.damage
			Game.hit_arc(global_position, aim, 75.0, 360.0, dmg, 220.0, "hittable")
			Fx.ring(get_parent(), global_position, 75.0, Color("#d6e4ea"))
			Game.shake(5.0)
			Game.hitstop(0.06)
		if state_time >= 0.4:
			state = S.MOVE


## Выпить напиток в квартире: Озон запрокидывает банку, потом снова слушается.
func drink() -> void:
	state = S.DRINK
	state_time = 0.0
	face = Vector2.DOWN
	controls = false
	Fx.sfx("drink")
	await get_tree().create_timer(1.1).timeout
	state = S.MOVE
	controls = true
	Fx.ring(get_parent(), global_position + Vector2(0, -6), 20.0, Color("#e8c35a"))


# --- урон -----------------------------------------------------------------------

## Возвращает true, если удар прошёл.
func hurt(amount: float, dir: Vector2, knock: float) -> bool:
	if invuln > 0.0 or state == S.DEAD or in_hub:
		return false
	var dmg := int(round(amount))
	Game.run.hp = max(Game.run.hp - dmg, 0)
	Game.run_changed.emit()
	push = dir * knock
	invuln = 0.7
	Fx.flash(sprite, Color("#ff6a6a"))
	Fx.number(get_parent(), global_position + Vector2(0, -30), dmg, Color("#ff6a6a"))
	Fx.sfx("hurt")
	Game.shake(4.0)
	Game.hitstop(0.07)
	Game.voice("hurt")
	if Game.run.hp <= 0:
		_die()
	return true


var _poison_acc := 0.0


## Яд на полу: 3 урона каждые полсекунды, без отбрасывания и неуязвимости.
func poison(delta: float) -> void:
	if state == S.DEAD or state == S.DASH or in_hub:
		return
	_poison_acc += delta
	if _poison_acc < 0.5:
		return
	_poison_acc = 0.0
	Game.run.hp = max(Game.run.hp - 3, 0)
	Game.run_changed.emit()
	Fx.flash(sprite, Color("#8fd04a"))
	Fx.number(get_parent(), global_position + Vector2(0, -30), 3, Color("#8fd04a"))
	if Game.run.hp <= 0:
		_die()


func _die() -> void:
	if Game.run.extra_life:
		_revive()
		return
	state = S.DEAD
	controls = false
	Game.voice("death")
	sprite.rotation = -PI / 2
	sprite.offset = Vector2(0, -15)
	sprite.position = Vector2(10, -4)
	Engine.time_scale = 0.4
	await get_tree().create_timer(1.4, true, false, true).timeout
	Engine.time_scale = 1.0
	Game.player_died()


## Вторая жизнь: Озон падает, мир на миг замирает, золотая вспышка — и он встаёт
## с половиной здоровья; ударная волна отбрасывает всех вокруг.
func _revive() -> void:
	Game.run.extra_life = false
	Game.run.hp = maxi(1, int(Game.run.max_hp / 2))
	Game.run_changed.emit()
	invuln = 3.0
	state = S.DEAD
	controls = false
	sprite.rotation = -PI / 2
	sprite.position = Vector2(10, -4)
	Engine.time_scale = 0.15
	Fx.sfx("hurt")
	await get_tree().create_timer(0.7, true, false, true).timeout
	Engine.time_scale = 1.0
	sprite.rotation = 0.0
	sprite.position = Vector2.ZERO
	Fx.flash(sprite, Color("#e8c35a"), 0.6)
	Fx.ring(get_parent(), global_position + Vector2(0, -8), 80.0, Color("#e8c35a"))
	Fx.ring(get_parent(), global_position + Vector2(0, -8), 40.0, Color("#fff2b0"))
	Fx.sfx("coin")
	Fx.sfx("slam")
	Game.shake(6.0)
	for e in get_tree().get_nodes_in_group("hittable"):
		var d: Vector2 = e.global_position - global_position
		if d.length() < 90.0 and "push" in e:
			e.push = d.normalized() * 320.0 * e.knock_resist
	var hud = Game.world().hud
	if hud:
		hud.big_banner("ВТОРАЯ ЖИЗНЬ!", "Донат сработал — Озон встаёт")
	Game.voice("revive")
	state = S.MOVE
	state_time = 0.0
	controls = true


# --- взаимодействие ---------------------------------------------------------

func _find_interactable() -> void:
	var best: Node = null
	var best_d := INF
	if controls and state == S.MOVE:
		for n in get_tree().get_nodes_in_group("interactables"):
			var d: float = n.global_position.distance_to(global_position)
			if d < n.radius and d < best_d:
				best = n
				best_d = d
	if best != interact_target:
		if is_instance_valid(interact_target):
			interact_target.focused = false
		interact_target = best
		if best:
			best.focused = true


# --- анимация ---------------------------------------------------------------

func _row_for(v: Vector2) -> int:
	if absf(v.x) > absf(v.y) * 0.9:
		sprite.flip_h = v.x < 0.0
		return 2
	sprite.flip_h = false
	return 0 if v.y >= 0.0 else 1


func _animate(delta: float) -> void:
	anim_time += delta
	var name := "idle0"
	match state:
		S.MOVE:
			if velocity.length() > 10.0:
				name = "walk%d" % (int(anim_time * 9.0) % 4)
			else:
				name = "idle%d" % (int(anim_time * 2.0) % 2)
		S.ATTACK:
			name = ATTACKS[combo].frame if state_time < 0.16 else "idle0"
		S.HEAVY:
			name = "heavy0" if state_time < HEAVY_WINDUP else "heavy1"
		S.DASH:
			name = "walk0"
		S.ABILITY:
			name = "vomit" if Game.run.get("drink", "") == "beer" else "punchA"
		S.DEAD:
			name = "hurt"
		S.DRINK:
			name = "drink" if int(state_time * 4.0) % 4 != 3 else "idle0"
	var row := _row_for(face)
	sprite.frame = row * FRAMES.size() + FRAMES.find(name)
	# мигание неуязвимости после удара (не во время рывка)
	if invuln > 0.0 and state != S.DASH and state != S.DEAD:
		sprite.visible = int(invuln * 20.0) % 2 == 0
	else:
		sprite.visible = true

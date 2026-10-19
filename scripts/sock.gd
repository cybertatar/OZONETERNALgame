extends "res://scripts/enemy.gd"
## Рядовой враг. ranged = false — подбирается и бьёт вблизи, true — держит дистанцию
## и кидается. skin — кто это: носок (подвал, кухня), бомж (улица), вьетконговец (Вьетнам).

const FRAMES := ["idle0", "idle1", "hop0", "hop1", "windup", "attack", "hurt"]

var ranged := false
var skin := "sock"

## Внешность и сила по виду: лист спрайтов, сдвиг до ног, здоровье ближнего/дальнего,
## урон вблизи, снаряд дальнего, высота прыжка при шаге (носки скачут, люди идут).
const SKINS := {
	"sock": {"tex": "socks", "offset": -8.0, "hp": [30.0, 22.0], "dmg": 6, "shot": "garlic", "hop": 6.0},
	"bum": {"tex": "bums", "offset": -15.0, "hp": [34.0, 24.0], "dmg": 7, "shot": "poop_shot", "hop": 1.0},
	"vc": {"tex": "vc", "offset": -15.0, "hp": [40.0, 28.0], "dmg": 8, "shot": "roach", "hop": 1.0},
}
var state := "wait"
var t := 0.0
var wait_for := 0.4
var dir := Vector2.ZERO
var hit_done := false
var shot_timer := 1.5
var anim := 0.0


func _ready() -> void:
	var sk: Dictionary = SKINS[skin]
	max_hp = sk.hp[1] if ranged else sk.hp[0]
	hp = max_hp
	setup_body(load("res://assets/sprites/%s.png" % sk.tex), 7, 2, sk.offset, preload("res://assets/sprites/shadow_s.png"), 5.0)
	if skin != "sock":
		hit_radius = 9.0
	wait_for = randf_range(0.2, 0.6)
	shot_timer = randf_range(1.2, 2.2)
	appear()


func _physics_process(delta: float) -> void:
	anim += delta
	if dead:
		return
	velocity = Vector2.ZERO
	var p := player()
	if active and p:
		t += delta
		var to := p.global_position - global_position
		if ranged:
			_ranged(delta, to, p)
		else:
			_melee(to, p)
		if state != "lunge":
			sprite.flip_h = to.x < 0.0
	apply_motion(delta)
	_animate()


func _melee(to: Vector2, p: Node2D) -> void:
	match state:
		"wait":
			if t >= wait_for:
				_go("windup" if to.length() < 24.0 else "hop")
				dir = to.normalized()
		"hop":
			velocity = dir * 80.0
			if t >= 0.35:
				_go("windup" if to.length() < 26.0 else "wait")
				wait_for = randf_range(0.05, 0.25)
				dir = to.normalized()
		"windup":
			if t >= 0.4:
				_go("lunge")
				hit_done = false
				dir = to.normalized()
		"lunge":
			velocity = dir * 190.0
			if not hit_done and global_position.distance_to(p.global_position) < 14.0:
				hit_done = true
				p.hurt(SKINS[skin].dmg, dir, 140.0)
			if t >= 0.15:
				_go("recover")
		"recover":
			if t >= 0.55:
				_go("wait")
				wait_for = randf_range(0.2, 0.5)


func _ranged(delta: float, to: Vector2, p: Node2D) -> void:
	shot_timer -= delta
	match state:
		"wait":
			if shot_timer <= 0.0 and to.length() < 220.0:
				_go("windup")
			elif t >= wait_for:
				_go("hop")
				var d := to.length()
				if d < 80.0:
					dir = -to.normalized()
				elif d > 150.0:
					dir = to.normalized()
				else:
					dir = to.normalized().orthogonal() * (1.0 if randf() < 0.5 else -1.0)
		"hop":
			velocity = dir * 70.0
			if t >= 0.35:
				_go("wait")
				wait_for = randf_range(0.3, 0.8)
		"windup":
			if t >= 0.5:
				var g := preload("res://scripts/garlic.gd").new()
				g.texture_name = SKINS[skin].shot
				g.position = global_position + Vector2(0, -10)
				g.dir = (p.global_position + Vector2(0, -8) - g.position).normalized()
				get_parent().add_child(g)
				shot_timer = randf_range(1.8, 2.6)
				_go("recover")
		"recover":
			if t >= 0.3:
				_go("wait")


func _go(s: String) -> void:
	state = s
	t = 0.0


func _animate() -> void:
	var name := "idle%d" % (int(anim * 3.0) % 2)
	sprite.position.y = 0.0
	match state:
		"hop":
			name = "hop0" if t < 0.17 else "hop1"
			sprite.position.y = -round(sin(clampf(t / 0.35, 0, 1) * PI) * SKINS[skin].hop)
		"windup":
			name = "windup"
			sprite.position.x = round(sin(t * 60.0)) if not ranged else 0.0
		"lunge":
			name = "attack"
		"recover":
			name = "idle1"
	if state != "windup":
		sprite.position.x = 0.0
	if dead:
		name = "hurt"
	sprite.frame = (1 if ranged else 0) * 7 + FRAMES.find(name)
	shadow.scale = Vector2.ONE * (1.0 + sprite.position.y / 20.0)

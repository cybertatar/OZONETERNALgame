extends "res://scripts/arena.gd"
## Квартира Озона: старт забега, выбор напитка, «Тихий Ден» на компьютере,
## трофеи на стене и телевизор, который можно разбить.

const INTERACT := preload("res://scripts/interactable.gd")

var _beer: Sprite2D
var _vodka: Sprite2D


class Tv extends Node2D:
	## Телевизор: три удара — и экран вдребезги. Ничего не даёт.
	var hit_radius := 12.0
	var hp := 3
	var sprite: Sprite2D

	func hurt(_amount: float, _dir: Vector2, _knock: float) -> bool:
		if hp <= 0:
			return false
		hp -= 1
		Fx.flash(sprite)
		Game.shake(2.0)
		var tw := sprite.create_tween()
		tw.tween_property(sprite, "position:x", 2.0, 0.04)
		tw.tween_property(sprite, "position:x", -2.0, 0.04)
		tw.tween_property(sprite, "position:x", 0.0, 0.04)
		if hp == 0:
			sprite.frame = 1
			Game.save.tvs += 1
			Game.write_save()
			Game.shake(5.0)
			Fx.dust(get_parent(), global_position, 10)
			Game.voice("tv_break")
			var n: int = Game.save.tvs
			Game.world().hud.toast("Телевизор разбит. Это ничего не дало." if n == 1 else "Телевизоров разбито: %d. Это всё ещё ничего не даёт." % n, 2.5)
		return true


func _ready() -> void:
	build("hub", preload("res://assets/sprites/floor_wood.png"), preload("res://assets/sprites/wall_wallpaper.png"))
	# левый верхний угол пола; дальше всё в координатах комнаты 224×128
	var o := Vector2(cell_center(Vector2i(2, 3))) - Vector2(TILE, TILE) * 0.5

	# стена: дверь, плакат, веер, трофеи, окно
	flat(preload("res://assets/sprites/door.png"), o + Vector2(4, -WALL_H), ground, 2).z_index = 1
	flat(preload("res://assets/sprites/poster.png"), o + Vector2(46, -37)).z_index = 1
	flat(preload("res://assets/sprites/fan.png"), o + Vector2(104, -37)).z_index = 1
	flat(preload("res://assets/sprites/window.png"), o + Vector2(180, -37)).z_index = 1
	var slots := ["mazokha"]
	for i in slots.size():
		var at := o + Vector2(149 + i * 28, -38)
		if slots[i] in Game.save.trophies:
			flat(preload("res://assets/sprites/trophy_mazokha.png"), at).z_index = 1
		else:
			var hole := ColorRect.new()
			hole.color = Color(0, 0, 0, 0.12)
			hole.position = at
			hole.size = Vector2(26, 28)
			hole.z_index = 1
			ground.add_child(hole)

	# мебель
	prop(preload("res://assets/sprites/chair.png"), o + Vector2(60, 24), Vector2(14, 6))
	var desk := prop(preload("res://assets/sprites/desk.png"), o + Vector2(60, 52), Vector2(54, 12))
	_beer = Sprite2D.new()
	_beer.texture = preload("res://assets/sprites/beer_can.png")
	_beer.position = Vector2(-20, -3)
	desk.add_child(_beer)
	_vodka = Sprite2D.new()
	_vodka.texture = preload("res://assets/sprites/vodka.png")
	_vodka.position = Vector2(-12, -6)
	desk.add_child(_vodka)
	_refresh_drinks()

	var tv_at := o + Vector2(124, 14)
	var tv_sprite := prop(preload("res://assets/sprites/tv.png"), tv_at, Vector2(30, 8), 2)
	var tv := Tv.new()
	tv.sprite = tv_sprite
	tv.position = tv_at
	tv.add_to_group("hittable")
	entities.add_child(tv)

	prop(preload("res://assets/sprites/bed.png"), o + Vector2(178, 126), Vector2(62, 22))

	# точки взаимодействия
	_point(o + Vector2(18, 8), 18, "Выйти на забег", _start_run, Vector2(0, -54))
	_point(o + Vector2(40, 62), 13, "Выпить", _open_drinks, Vector2(0, -52))
	_point(o + Vector2(76, 62), 13, "«Тихий Ден»", _open_book, Vector2(0, -52))

	# записка с отрывком «Тихого Дена», выпавшая с Мазохи, приколота к стене
	if 0 in Game.save.pages:
		flat(preload("res://assets/sprites/note_paper.png"), o + Vector2(78, -32)).z_index = 1
		_point(o + Vector2(85, 10), 14, "Записка", _read_note, Vector2(0, -40))

	spawn_player(o + Vector2(132, 114), true)
	Game.music("hub")
	hud.show_controls(true)
	_wake_up()


func _point(pos: Vector2, r: float, text: String, cb: Callable, offset: Vector2) -> void:
	var p := INTERACT.new()
	p.marker_offset = offset
	p.position = pos
	p.radius = r
	p.prompt = text
	p.action = cb
	entities.add_child(p)


## На столе стоит всё открытое, кроме того, что Озон уже выпил этим утром.
func _refresh_drinks() -> void:
	var have: Array = Game.save.drinks
	_beer.visible = "beer" in have and Game.drunk != "beer"
	_vodka.visible = "vodka" in have and Game.drunk != "vodka"


func _wake_up() -> void:
	Game.drunk = ""
	_refresh_drinks()
	player.controls = false
	player.face = Vector2.DOWN
	match Game.wake_reason:
		"first":
			hud.title("OZON ETERNAL", "Озон просыпается. Где-то там Меддисон.")
			Game.voice("wake_first")
		"death":
			hud.title("Похмелье", "Озон проснулся в своей кровати. Опять.")
			Game.voice("wake_hangover")
			# комната «плывёт»
			var tw := create_tween()
			for i in 4:
				tw.tween_property(camera, "rotation", 0.02 * (1 if i % 2 == 0 else -1), 0.35)
			tw.tween_property(camera, "rotation", 0.0, 0.3)
		"victory":
			hud.title("Дома", "Мазоха повержен. Трофей уже на стене.")
			Game.voice("home_victory")
	await get_tree().create_timer(1.2).timeout
	player.controls = true


func _start_run() -> void:
	if Game.drunk == "":
		hud.toast("Озон трезв. Сначала выпей что-нибудь со стола", 2.2)
		Game.voice("door_sober")
		return
	player.controls = false
	hud.show_controls(false)
	Game.start_run()


func _open_drinks() -> void:
	var m := preload("res://scripts/ui/drinks.gd").new()
	player.controls = false
	hud.add_child(m)
	var id: String = await m.closed
	if id == "":
		player.controls = true
		return
	if Game.drunk != "" and Game.drunk != id:
		hud.toast("Озон передумал и допил ещё и это")
	Game.drunk = id
	Game.save.drink = id
	Game.write_save()
	_refresh_drinks()
	Game.voice("choose_" + id)
	await player.drink()
	var d: Dictionary = Game.DRINKS[id]
	hud.toast("Озон выпил: %s. В забеге — %s, чтобы %s" % [d.name, Game.key_name("ability"), d.verb], 3.0)


func _read_note() -> void:
	var n := preload("res://scripts/ui/note.gd").new()
	n.index = 0
	n.at_home = true
	hud.add_child(n)


func _open_book() -> void:
	var m := preload("res://scripts/ui/book.gd").new()
	player.controls = false
	hud.add_child(m)
	await m.closed
	player.controls = true

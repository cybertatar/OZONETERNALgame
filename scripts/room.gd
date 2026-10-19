extends "res://scripts/arena.gd"
## Комната забега: волны носков и ловушки, после зачистки — донаты и дверь дальше.
## Последняя комната — Мазоха.

const SOCK := preload("res://scripts/sock.gd")
const TRAP := preload("res://scripts/trap.gd")

## Карты — data/rooms/<map>.txt. В волнах 0 — носок ближнего боя, 1 — дальнего.
const LAYOUTS := [
	{"map": "room1", "theme": "basement", "waves": [[0, 0, 0, 0], [0, 0, 0, 1, 1], [0, 0, 1, 1, 1]]},
	{"map": "room2", "theme": "street", "waves": [[0, 0, 1, 1], [0, 0, 0, 1, 1], [0, 0, 0, 0, 1, 1]]},
	{"map": "room3", "theme": "vietnam", "waves": [[0, 0, 0, 1, 1], [0, 0, 1, 1, 1, 1], [0, 0, 0, 0, 1, 1, 1]]},
]
const BOSS_LAYOUT := {"map": "boss", "theme": "kitchen", "waves": []}

## Оформление уровней: пол и стена (тайлы), пустота за краем, мебель на клетках c и b,
## картинки ловушек (^ — колья, ~ — яд), мелочи на полу и подпись в HUD.
const THEMES := {
	"basement": {
		"enemy": "sock",
		"name": "Подвал", "floor": "floor_concrete", "wall": "wall_brick",
		"void": "#16111a", "rim": "#3a2f42", "c": "crate", "b": "basket",
		"spikes": "spikes", "poison": "poison", "decor": [],
	},
	"street": {
		"enemy": "bum",
		"name": "Улица", "floor": "floor_asphalt", "wall": "wall_panel",
		"void": "#141a2e", "rim": "#3a4466", "c": "trash_bin", "b": "bench",
		"spikes": "glass", "poison": "fuel",
		"decor": ["decor_manhole", "decor_butts", "decor_crack", "decor_leaf"],
	},
	"vietnam": {
		"enemy": "vc",
		"name": "Вьетнам", "floor": "floor_terracotta", "wall": "wall_bamboo",
		"void": "#0e1a10", "rim": "#2e4a26", "c": "jar", "b": "rice_sack",
		"spikes": "punji", "poison": "paddy",
		"decor": ["decor_lotus", "decor_stones", "decor_sprout", "decor_petals"],
	},
	"kitchen": {
		"enemy": "sock",
		"name": "Логово Мазохи", "floor": "floor_checker", "wall": "wall_kitchen",
		"void": "#1e1612", "rim": "#5a4434", "c": "washer", "b": "washer",
		"spikes": "spikes", "poison": "poison",
		"decor": ["decor_cans", "decor_crumbs", "decor_sock", "decor_spill"],
	},
}

var index := 0
var layout: Dictionary
var wave := -1
var spawning := false
var cleared := false
var boss: Node
var door: Sprite2D
var door_open := false
## Середина двери у подножия стены.
var door_pos := Vector2.ZERO
var pickups := []
var _props := []


func _ready() -> void:
	index = Game.run.room
	var is_boss := index >= Game.ROOMS_BEFORE_BOSS
	layout = BOSS_LAYOUT if is_boss else LAYOUTS[index]
	var th: Dictionary = THEMES[layout.theme]
	build(layout.map, _tex(th.floor), _tex(th.wall), Color(th.void), Color(th.rim))
	for ch in ["c", "b"]:
		for c in marks.get(ch, []):
			var tex: Texture2D = _tex(th[ch])
			var pos := cell_center(c) + Vector2(0, 6)
			prop(tex, pos, Vector2(tex.get_width() - 2, 9))
			_props.append(pos)
	var spikes: Array = marks.get("^", [])
	for i in spikes.size():
		var t := TRAP.new()
		t.kind = "spikes"
		t.texture_name = th.spikes
		t.phase = float(i % 2) * 0.9
		t.position = Vector2(spikes[i] * TILE)
		decals.add_child(t)
	for c in marks.get("~", []):
		var t := TRAP.new()
		t.kind = "poison"
		t.texture_name = th.poison
		t.position = Vector2(c * TILE)
		decals.add_child(t)
	_scatter_decor(th.decor)
	door_pos = Vector2(cell("D") * TILE) + Vector2(TILE, 0)
	door = flat(preload("res://assets/sprites/door.png"), door_pos + Vector2(-14, -WALL_H), ground, 2)
	door.z_index = 1
	spawn_player(cell_center(cell("@")))
	Game.music("boss" if is_boss else "fight")
	player.face = Vector2.UP
	hud.set_room_label(th.name if is_boss else "%s · %d из %d" % [th.name, index + 1, Game.ROOMS_BEFORE_BOSS])
	await get_tree().create_timer(0.7).timeout
	if is_boss:
		_start_boss()
	else:
		if index == 0:
			Game.voice("room_first")
		_next_wave()


func _tex(name: String) -> Texture2D:
	return load("res://assets/sprites/%s.png" % name)


## Мелочи на полу (окурки, лотосы, банки) — без столкновений, раскиданы по свободным
## клеткам; одинаково при каждом заходе в эту комнату.
func _scatter_decor(names: Array) -> void:
	if names.is_empty():
		return
	var rnd := RandomNumberGenerator.new()
	rnd.seed = hash(layout.map)
	var count := floor_cells.size() / 14
	for i in count:
		var c: Vector2i = floor_cells[rnd.randi_range(0, floor_cells.size() - 1)]
		var name: String = names[rnd.randi_range(0, names.size() - 1)]
		var s := flat(_tex(name), Vector2(c * TILE), decals)
		s.z_index = -1
		s.flip_h = rnd.randf() < 0.5


# --- волны ----------------------------------------------------------------------

func _next_wave() -> void:
	wave += 1
	if wave >= layout.waves.size():
		_on_cleared()
		return
	spawning = true
	for kind in layout.waves[wave]:
		spawn_sock(_free_spot(), kind == 1)
		await get_tree().create_timer(0.15).timeout
	spawning = false


func _free_spot() -> Vector2:
	## Случайная свободная клетка пола: не у Озона, но и не на другом конце карты.
	for i in 60:
		var p := cell_center(floor_cells.pick_random())
		var d := p.distance_to(player.global_position)
		if d < 90.0 or d > 300.0:
			continue
		var ok := true
		for q in _props:
			if p.distance_to(q) < 22.0:
				ok = false
		if ok:
			return p
	return cell_center(floor_cells.pick_random())


func spawn_sock(pos: Vector2, ranged: bool) -> void:
	var s := SOCK.new()
	s.ranged = ranged
	s.skin = THEMES[layout.theme].enemy
	if not is_floor(pos):
		pos = _free_spot()
	s.position = pos
	entities.add_child(s)


func _physics_process(_delta: float) -> void:
	if cleared or boss or spawning or wave < 0:
		_check_door_and_pickups()
		return
	if get_tree().get_nodes_in_group("enemies").is_empty():
		spawning = true
		await get_tree().create_timer(0.6).timeout
		_next_wave()


func _on_cleared() -> void:
	cleared = true
	Game.voice("room_clear")
	hud.toast("Комната зачищена")
	await get_tree().create_timer(0.8).timeout
	var r := preload("res://scripts/ui/donations.gd").new()
	hud.add_child(r)
	player.controls = false
	await r.chosen
	player.controls = true
	_open_door()


func _open_door() -> void:
	door.frame = 1
	door_open = true
	Fx.sfx("door")
	Fx.dust(decals, door_pos + Vector2(0, 2), 6)
	hud.toast("Дверь открыта" if not boss else "Пора домой")


func _check_door_and_pickups() -> void:
	if player == null:
		return
	for p in pickups.duplicate():
		if is_instance_valid(p) and p.global_position.distance_to(player.global_position) < 14.0:
			pickups.erase(p)
			p.collect()
			if pickups.is_empty():
				_victory()
	if door_open and player.controls and player.global_position.y < door_pos.y + 16.0 and absf(player.global_position.x - door_pos.x) < 18.0:
		door_open = false
		player.controls = false
		if boss:
			Game.go_home_after_victory()
		else:
			Game.next_room()


# --- босс -----------------------------------------------------------------------

func _start_boss() -> void:
	boss = preload("res://scripts/mazokha.gd").new()
	boss.position = cell_center(cell("M"))
	entities.add_child(boss)
	boss.died.connect(_on_boss_died)
	player.controls = false
	Game.voice("boss_intro", "mazokha")
	# пока Мазоха говорит, камера на нём (выше середины — снизу диалог)
	cam_focus = boss.global_position + Vector2(0, -22)
	await hud.boss_intro("Александр Мазоха", "Постирай носки дура бляяяя. И за пивом метнись.")
	cam_focus = null
	player.controls = true
	boss.start()


func _on_boss_died(_b: Node) -> void:
	for s in get_tree().get_nodes_in_group("enemies"):
		s.hurt(999, Vector2.ZERO, 0.0)
	Game.voice("boss_win")
	hud.hide_boss_bar()
	var page := preload("res://scripts/pickup.gd").new()
	page.kind = "page"
	page.page_index = 0  # записка Мазохи — отрывок про лавочку
	page.position = boss.position + Vector2(-20, 16)
	entities.add_child(page)
	var drink := preload("res://scripts/pickup.gd").new()
	drink.kind = "vodka"
	drink.position = boss.position + Vector2(20, 16)
	entities.add_child(drink)
	pickups = [page, drink]


func _victory() -> void:
	Game.boss_defeated("mazokha", "vodka")
	await get_tree().create_timer(0.6).timeout
	hud.toast("Мазоха повержен. Продолжение следует…", 3.0)
	_open_door()

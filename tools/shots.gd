extends Node
## Автопрогон для проверки: проходит игру читами и снимает скриншоты.
## Запуск: godot --path . -- --shots <папка>

var out := "user://shots"
var n := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--shots")
	if i >= 0 and i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	_run()


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%02d_%s.png" % [out, n, name])
	n += 1


func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func player() -> Node:
	return Game.world().player


## Вся карта целиком: камера отъезжает в центр и уменьшает масштаб.
func overview(name: String) -> void:
	var w = Game.world()
	w.fixed_camera = true
	var full := Vector2(w.map_size * w.TILE)
	w.camera.zoom = Vector2.ONE * minf(480.0 / full.x, 270.0 / (full.y + 40.0))
	w._cam_pos = full * 0.5 + Vector2(0, -20)
	await wait(0.1)
	await shot(name)
	w.camera.zoom = Vector2.ONE
	w.fixed_camera = false


## Нажатие как от игрока: событие проходит через _unhandled_input, в отличие от action_press.
func press(action: String) -> void:
	for down in [true, false]:
		var e := InputEventAction.new()
		e.action = action
		e.pressed = down
		Input.parse_input_event(e)
		await get_tree().process_frame
	await wait(0.3)


func kill_all() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.hurt(999, Vector2.RIGHT, 0)


func _run() -> void:
	Game.save = Game._default_save()
	await wait(1.0)
	await shot("hub_wake")
	await wait(2.0)
	for it in get_tree().get_nodes_in_group("interactables"):
		if it.prompt == "Выпить":
			player().position = it.global_position + Vector2(0, 4)
	await wait(0.4)
	print("SHOTS: music playing = ", Game._music != null and Game._music.playing)
	await shot("hub_desk")
	Game.world()._open_drinks()
	await wait(0.2)
	await shot("drinks")
	Game.world().hud.get_child(-1)._pick("beer")
	await wait(0.6)
	await shot("hub_drinking")
	await wait(1.0)
	await shot("hub_drunk")

	Game.start_run()
	await wait(2.2)
	await shot("room1_spawn")
	await overview("room1_map")
	# немного подраться настоящим вводом
	Input.action_press("attack")
	await wait(0.1)
	Input.action_release("attack")
	await wait(0.05)
	await shot("room1_punch")
	Input.action_press("heavy")
	await wait(0.1)
	Input.action_release("heavy")
	await wait(0.4)
	await shot("room1_heavy")
	Input.action_press("ability")
	await wait(0.1)
	Input.action_release("ability")
	await wait(0.6)
	await shot("room1_beer")
	await wait(1.5)
	await shot("room1_fight")
	for k in 8:
		kill_all()
		await wait(1.0)
	await wait(0.8)
	await shot("donations")
	await wait(0.3)
	await shot("donations2")
	Game.world().hud.get_child(-1)._pick("rage")
	await wait(0.8)
	await shot("door_open")
	# в дверь входим ногами, а не переносом: так ловится дверь, до которой не дойти
	player().position = Game.world().door_pos + Vector2(0, 40)
	Input.action_press("move_up")
	await wait(1.6)
	Input.action_release("move_up")
	await wait(0.6)
	print("SHOTS: after door, room index = ", Game.run.room)
	assert(Game.run.room == 1, "в дверь первой комнаты не войти")

	await wait(1.4)
	await overview("room2_map")
	await shot("room2")
	Game.run.room = 2
	Game.goto("room")
	await wait(2.0)
	await overview("room3_map")
	await shot("room3")
	for k in 8:
		kill_all()
		await wait(1.0)
	Game.world().hud.get_child(-1)._pick("life")
	await wait(0.6)

	Game.run.room = 3
	Game.goto("room")
	await wait(1.6)
	await shot("boss_intro")
	await overview("boss_map")
	await wait(2.6)
	await shot("boss_fight")
	await wait(1.5)
	await shot("boss_fight2")
	var bb = get_tree().get_first_node_in_group("boss")
	while not bb.active:
		await wait(0.2)
	await wait(0.3)
	print("SHOTS: бой начался, Мазоха говорит = ", Game.voice_playing("mazokha"))
	var boss = get_tree().get_first_node_in_group("boss")
	boss.hurt(300, Vector2.ZERO, 0)
	await wait(2.0)
	await shot("boss_angry")
	boss.hurt(999, Vector2.ZERO, 0)
	await wait(2.5)
	await shot("boss_dead")
	for p in Game.world().pickups.duplicate():
		if p.kind == "page":
			player().position = p.position
			await wait(0.6)
			await shot("note")
			await press("interact")
	for p in Game.world().pickups.duplicate():
		player().position = p.position
		await wait(0.3)
	await wait(1.2)
	print("SHOTS: страницы ", Game.save.pages, " управление ", player().controls)
	await shot("victory")
	player().position = Game.world().door_pos + Vector2(0, 40)
	Input.action_press("move_up")
	await wait(1.6)
	Input.action_release("move_up")
	await wait(2.0)
	await shot("home_victory")
	for it in get_tree().get_nodes_in_group("interactables"):
		if it.prompt == "Записка":
			player().position = it.global_position + Vector2(0, 4)
	await wait(0.5)
	await shot("home_note_marker")
	await press("interact")
	await wait(0.3)
	await shot("home_note")
	await press("interact")
	await wait(1.5)
	Game.world()._open_book()
	await wait(0.2)
	await shot("book")
	Game.world().hud.get_child(-1).closed.emit()
	Game.world().hud.get_child(-1).queue_free()

	# смерть
	Game.start_run()
	await wait(2.0)
	Game.run.hp = 1
	player().hurt(5, Vector2.LEFT, 50)
	await wait(0.5)
	await shot("death")
	await wait(3.0)
	await shot("hangover")
	get_tree().quit()

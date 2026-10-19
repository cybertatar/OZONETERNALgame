extends Node
## Глобальное состояние: сохранение (мета), текущий забег, переходы между сценами,
## управление и общие помощники боя.

signal run_changed
signal boss_hp_changed(hp: int, max_hp: int, name: String)

const SAVE_PATH := "user://save.json"

## Алкоголь — способность на забег.
const DRINKS := {
	"beer": {
		"name": "Пиво «Бояринъ»",
		"desc": "Озон блюёт перед собой. Лужа замедляет врагов и разъедает их.",
		"icon": "res://assets/sprites/icon_beer.png",
		"cooldown": 7.0,
		"verb": "блевануть",
	},
	"vodka": {
		"name": "Водка",
		"desc": "Удар на 360° вокруг себя по большой площади.",
		"icon": "res://assets/sprites/icon_vodka.png",
		"cooldown": 8.0,
		"verb": "крутануться",
	},
}

const BASE_MAX_HP := 50
## Комнаты забега: три боевые и босс.
const ROOMS_BEFORE_BOSS := 3

var save := {}
var run := {}
## Как Озон попал в квартиру: "first", "death", "victory".
var wake_reason := "first"
## Что Озон выпил этим утром ("" — ещё трезв). Сбрасывается при каждом пробуждении.
var drunk := ""
var using_pad := false

var _world: Node
var _main: Node
var _shake := 0.0
var _flash_shader: Shader
var _book: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_setup_theme()
	_load()
	_flash_shader = Shader.new()
	_flash_shader.code = """
shader_type canvas_item;
uniform float flash = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
void fragment() {
	vec4 c = COLOR;
	COLOR = vec4(mix(c.rgb, flash_color.rgb, flash), c.a);
}
"""
	if "--shots" in OS.get_cmdline_user_args():
		add_child(load("res://tools/shots.gd").new())
	var f := FileAccess.open("res://data/book.json", FileAccess.READ)
	if f:
		_book = JSON.parse_string(f.get_as_text())


# --- шрифты ---------------------------------------------------------------------

var font: FontFile
var font_bold: FontFile


func _load_font(path: String) -> FontFile:
	var f: FontFile = load(path)
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	f.hinting = TextServer.HINTING_LIGHT
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return f


func _setup_theme() -> void:
	## Rubik: интерфейс рисуется в настоящем разрешении экрана (stretch canvas_items),
	## пиксельные шрифты в 5–8 px читались плохо.
	font = _load_font("res://assets/fonts/Rubik-Regular.ttf")
	font_bold = _load_font("res://assets/fonts/Rubik-SemiBold.ttf")
	# тема окна не доходит до интерфейса под CanvasLayer — задаём шрифт по умолчанию глобально
	ThemeDB.fallback_font = font
	ThemeDB.fallback_font_size = 9
	var t := ThemeDB.get_default_theme()
	t.default_font = font
	t.default_font_size = 9


# --- управление --------------------------------------------------------------

func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"dash": [KEY_SPACE, KEY_SHIFT],
		"ability": [KEY_Q],
		"interact": [KEY_E],
		"pause": [KEY_ESCAPE],
	}
	var mouse := {"attack": MOUSE_BUTTON_LEFT, "heavy": MOUSE_BUTTON_RIGHT}
	# Геймпад в раскладке Xbox: X — атака, Y — усиленная, A — рывок, а рядом с предметом
	# в квартире — действие (подтверждение), RB/RT — способность, B — назад, Start — пауза.
	var pad := {
		"attack": JOY_BUTTON_X,
		"heavy": JOY_BUTTON_Y,
		"dash": JOY_BUTTON_A,
		"ability": JOY_BUTTON_RIGHT_SHOULDER,
		"interact": JOY_BUTTON_A,
		"pause": JOY_BUTTON_START,
	}
	var axes := {
		"move_left": [JOY_AXIS_LEFT_X, -1.0],
		"move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0],
		"move_down": [JOY_AXIS_LEFT_Y, 1.0],
		"aim_left": [JOY_AXIS_RIGHT_X, -1.0],
		"aim_right": [JOY_AXIS_RIGHT_X, 1.0],
		"aim_up": [JOY_AXIS_RIGHT_Y, -1.0],
		"aim_down": [JOY_AXIS_RIGHT_Y, 1.0],
	}
	var dpad := {
		"move_left": JOY_BUTTON_DPAD_LEFT, "move_right": JOY_BUTTON_DPAD_RIGHT,
		"move_up": JOY_BUTTON_DPAD_UP, "move_down": JOY_BUTTON_DPAD_DOWN,
	}
	var names := {}
	for d in [keys, mouse, pad, axes, dpad]:
		for a in d:
			names[a] = true
	# Правый триггер — тоже способность.
	names["ability"] = true
	for a in names:
		if not InputMap.has_action(a):
			InputMap.add_action(a, 0.25)
	for a in keys:
		for k in keys[a]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(a, e)
	for a in mouse:
		var e := InputEventMouseButton.new()
		e.button_index = mouse[a]
		InputMap.action_add_event(a, e)
	for a in pad:
		var e := InputEventJoypadButton.new()
		e.button_index = pad[a]
		InputMap.action_add_event(a, e)
	for a in dpad:
		var e := InputEventJoypadButton.new()
		e.button_index = dpad[a]
		InputMap.action_add_event(a, e)
	for a in axes:
		var e := InputEventJoypadMotion.new()
		e.axis = axes[a][0]
		e.axis_value = axes[a][1]
		InputMap.action_add_event(a, e)
	# подтверждение и «назад» в меню: A и B (на всякий случай явно, поверх встроенных)
	for pair in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B], ["ui_accept", KEY_E]]:
		var ev: InputEvent
		if pair[0] == "ui_accept" and pair[1] == KEY_E:
			ev = InputEventKey.new()
			ev.physical_keycode = KEY_E
		else:
			ev = InputEventJoypadButton.new()
			ev.button_index = pair[1]
		if not InputMap.action_has_event(pair[0], ev):
			InputMap.action_add_event(pair[0], ev)
	var rt := InputEventJoypadMotion.new()
	rt.axis = JOY_AXIS_TRIGGER_RIGHT
	rt.axis_value = 1.0
	InputMap.action_add_event("ability", rt)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.4):
		using_pad = true
	elif event is InputEventMouseMotion or event is InputEventKey or event is InputEventMouseButton:
		using_pad = false


## Подсказка для кнопки в зависимости от устройства.
func key_name(action: String) -> String:
	var kb := {"attack": "ЛКМ", "heavy": "ПКМ", "dash": "Пробел", "ability": "Q", "interact": "E", "back": "Esc", "pause": "Esc"}
	var gp := {"attack": "X", "heavy": "Y", "dash": "A", "ability": "RB", "interact": "A", "back": "B", "pause": "Start"}
	return (gp if using_pad else kb).get(action, action)


# --- сохранение ---------------------------------------------------------------

func _default_save() -> Dictionary:
	return {
		"drinks": ["beer"],
		"drink": "beer",
		"pages": [],
		"trophies": [],
		"runs": 0,
		"deaths": 0,
		"tvs": 0,
	}


func _load() -> void:
	save = _default_save()
	if FileAccess.file_exists(SAVE_PATH):
		var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if data is Dictionary:
			for k in data:
				save[k] = data[k]


func write_save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save, "\t"))


func book() -> Array:
	return _book


# --- забег ------------------------------------------------------------------

func start_run() -> void:
	save.runs += 1
	write_save()
	run = {
		"room": 0,
		"hp": BASE_MAX_HP,
		"max_hp": BASE_MAX_HP,
		"damage": 1.0,
		"extra_life": false,
		"drink": drunk,
	}
	voice("run_start")
	goto("room")


func next_room() -> void:
	run.room += 1
	goto("room")


func player_died() -> void:
	save.deaths += 1
	write_save()
	wake_reason = "death"
	goto("hub")


func boss_defeated(boss_id: String, drink_unlock: String) -> void:
	if boss_id not in save.trophies:
		save.trophies.append(boss_id)
	if drink_unlock not in save.drinks:
		save.drinks.append(drink_unlock)
	write_save()


## Отмечает отрывок «Тихого Дена» найденным. index — конкретный отрывок (у каждого
## босса свой), -1 — следующий ещё не найденный. Возвращает номер отрывка или -1.
func add_page(index := -1) -> int:
	if index < 0:
		for i in _book.size():
			if i not in save.pages:
				index = i
				break
	if index < 0 or index >= _book.size():
		return -1
	if index not in save.pages:
		save.pages.append(index)
		write_save()
	return index


func go_home_after_victory() -> void:
	wake_reason = "victory"
	goto("hub")


# --- сцены ------------------------------------------------------------------

func register_main(main: Node) -> void:
	_main = main


func goto(kind: String, fade := 0.4) -> void:
	if _changing:
		return
	_changing = true
	get_tree().paused = false
	Engine.time_scale = 1.0
	voice_stop_all()
	await _main.fade_out(fade)
	await _main.show_world(kind)
	_changing = false


var _changing := false


func set_world(w: Node) -> void:
	_world = w


func world() -> Node:
	return _world


# --- бой: общие помощники --------------------------------------------------

func flash_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _flash_shader
	return m


## Удар по дуге. Цели — узлы группы `group` с методом hurt(amount, dir, knock)
## и свойством hit_radius.
func hit_arc(origin: Vector2, dir: Vector2, reach: float, arc_deg: float, amount: float, knock: float, group := "enemies") -> int:
	var hits := 0
	for t in get_tree().get_nodes_in_group(group):
		if not is_instance_valid(t) or not t.has_method("hurt"):
			continue
		var to: Vector2 = t.global_position - origin
		var r: float = t.hit_radius
		if to.length() > reach + r:
			continue
		if to.length() > r + 4.0 and absf(rad_to_deg(dir.angle_to(to))) > arc_deg * 0.5:
			continue
		var kdir := to.normalized() if to.length() > 0.1 else dir
		if t.hurt(amount, kdir, knock):
			hits += 1
	return hits


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func take_shake(delta: float) -> Vector2:
	_shake = maxf(_shake - delta * 30.0, 0.0)
	if _shake <= 0.0:
		return Vector2.ZERO
	return Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)).round()


func hitstop(seconds: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(seconds, true, false, true).timeout
	Engine.time_scale = 1.0


# --- озвучка -----------------------------------------------------------------

var _voice_players := {}
var _voice_cache := {}


## Фраза персонажа: assets/voice/<event>.ogg (или .mp3) или случайная из <event>_1, _2…
## У каждого говорящего (speaker) свой канал: пока он договаривает, новая фраза
## того же персонажа не начинается. Музыка на время реплики приглушается.
## Нет файла — тишина. Возвращает true, если фраза пошла.
func voice(event: String, speaker := "ozon") -> bool:
	if not _voice_cache.has(event):
		var list := []
		for ext in ["ogg", "mp3"]:
			var single := "res://assets/voice/%s.%s" % [event, ext]
			if ResourceLoader.exists(single):
				list.append(single)
			for i in range(1, 10):
				var p := "res://assets/voice/%s_%d.%s" % [event, i, ext]
				if ResourceLoader.exists(p):
					list.append(p)
		_voice_cache[event] = list
	var files: Array = _voice_cache[event]
	if files.is_empty():
		return false
	if not _voice_players.has(speaker):
		var vp := AudioStreamPlayer.new()
		vp.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(vp)
		vp.finished.connect(_duck_music)
		_voice_players[speaker] = vp
	var player: AudioStreamPlayer = _voice_players[speaker]
	if player.playing:
		return false
	player.stream = load(files.pick_random())
	player.play()
	_duck_music()
	return true


func voice_playing(speaker := "ozon") -> bool:
	return _voice_players.has(speaker) and _voice_players[speaker].playing


func voice_stop(speaker: String) -> void:
	if _voice_players.has(speaker):
		_voice_players[speaker].stop()
		_duck_music()


## Остановить все фразы (смена сцены: мёртвый Мазоха не договаривает в квартире).
func voice_stop_all() -> void:
	for p in _voice_players.values():
		p.stop()
	_duck_music()


const MUSIC_DB := -9.0
const MUSIC_DUCKED_DB := -19.0


func _duck_music() -> void:
	if _music == null or not _music.playing:
		return
	var talking := false
	for p in _voice_players.values():
		if p.playing:
			talking = true
	var t := create_tween()
	t.tween_property(_music, "volume_db", MUSIC_DUCKED_DB if talking else MUSIC_DB, 0.3)


# --- музыка ---------------------------------------------------------------------

var _music: AudioStreamPlayer
var _music_name := ""


## Фоновая музыка по кругу: assets/music/<name>.mp3 (или .ogg). Нет такого файла —
## берётся main.mp3, нет и его — тишина. Смена трека — с плавным переходом.
func music(name: String) -> void:
	var path := ""
	for n in [name, "main"]:
		for ext in ["mp3", "ogg"]:
			var p := "res://assets/music/%s.%s" % [n, ext]
			if path == "" and ResourceLoader.exists(p):
				path = p
	if path == _music_name:
		return
	_music_name = path
	if _music == null:
		_music = AudioStreamPlayer.new()
		_music.volume_db = -80.0
		add_child(_music)
	var t := create_tween()
	if _music.playing:
		t.tween_property(_music, "volume_db", -40.0, 0.4)
	t.tween_callback(func():
		_music.stop()
		if path == "":
			return
		var st = load(path)
		if "loop" in st:
			st.loop = true
		_music.stream = st
		_music.volume_db = -30.0
		_music.play())
	if path != "":
		t.tween_property(_music, "volume_db", MUSIC_DB, 0.8)
		t.tween_callback(_duck_music)

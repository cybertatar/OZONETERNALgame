extends Node2D
## Основа для квартиры и комнат забега: карта из клеток (data/rooms/*.txt), стены,
## слои, камера, Озон, HUD. Обозначения клеток — в tools/rooms/gen.py.

const TILE := 16
const WALL_H := 40.0
const VIEW := Vector2(480, 270)

var cells: Array[String] = []
var map_size := Vector2i.ZERO
## Прямоугольник всей карты в пикселях.
var floor_rect: Rect2
## Клетки по символу: "@", "D", "M", "^", "~", "c", "b".
var marks := {}
var floor_cells: Array[Vector2i] = []
var ground: Node2D
var decals: Node2D
var entities: Node2D
var camera: Camera2D
var player: CharacterBody2D
var hud: CanvasLayer
## true — камера стоит на месте (карта влезает в экран), false — следует за Озоном.
var fixed_camera := false

var _floor_tex: Texture2D
var _wall_tex: Texture2D
## Цвет пустоты за краем арены и кромки у обрыва — у каждого уровня свои.
var void_color := Color("#16111a")
var rim_color := Color("#3a2f42")


class MapDraw extends Node2D:
	## Рисует пол, стены над краями пола, пустоту и кромки.
	var arena

	func _draw() -> void:
		var a = arena
		var void_col: Color = a.void_color
		var rim: Color = a.rim_color
		var ledge := Color("#0d0a10")
		var fw: int = a._floor_tex.get_width()
		var fh: int = a._floor_tex.get_height()
		var ww: int = a._wall_tex.get_width()
		for y in a.map_size.y:
			for x in a.map_size.x:
				var r := Rect2(x * TILE, y * TILE, TILE, TILE)
				if a.is_void_cell(Vector2i(x, y)):
					draw_rect(r, void_col)
				else:
					draw_texture_rect_region(a._floor_tex, r, Rect2((x * TILE) % fw, (y * TILE) % fh, TILE, TILE))
		for y in a.map_size.y:
			for x in a.map_size.x:
				var c := Vector2i(x, y)
				if a.is_void_cell(c):
					continue
				var px: int = x * TILE
				var py: int = y * TILE
				if a.is_void_cell(c + Vector2i.UP):
					# стена над краем пола
					draw_texture_rect_region(a._wall_tex, Rect2(px, py - WALL_H, TILE, WALL_H), Rect2(px % ww, 0, TILE, WALL_H))
					draw_rect(Rect2(px, py - WALL_H - 2, TILE, 2), rim)
					draw_rect(Rect2(px, py, TILE, 4), Color(0.08, 0.05, 0.1, 0.25))
				if a.is_void_cell(c + Vector2i.DOWN):
					draw_rect(Rect2(px, py + TILE, TILE, 4), ledge)  # толщина пола у обрыва
					draw_rect(Rect2(px, py + TILE - 1, TILE, 1), rim)
				if a.is_void_cell(c + Vector2i.LEFT):
					draw_rect(Rect2(px - 2, py, 2, TILE), rim)
				if a.is_void_cell(c + Vector2i.RIGHT):
					draw_rect(Rect2(px + TILE, py, 2, TILE), rim)


func load_map(name: String) -> void:
	var text := FileAccess.get_file_as_string("res://data/rooms/%s.txt" % name)
	cells.clear()
	for line in text.split("\n"):
		if line.strip_edges() != "":
			cells.append(line)
	map_size = Vector2i(cells[0].length(), cells.size())
	floor_rect = Rect2(Vector2.ZERO, Vector2(map_size * TILE))
	for y in map_size.y:
		for x in map_size.x:
			var ch := cells[y][x]
			if ch == "#":
				continue
			if ch != ".":
				if not marks.has(ch):
					marks[ch] = []
				marks[ch].append(Vector2i(x, y))
			if ch in [".", "@", "D", "M"]:
				floor_cells.append(Vector2i(x, y))


func cell(ch: String) -> Vector2i:
	return marks[ch][0] if marks.has(ch) else Vector2i(-1, -1)


func cell_center(c: Vector2i) -> Vector2:
	return Vector2(c * TILE) + Vector2(TILE, TILE) * 0.5


func is_void_cell(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= map_size.x or c.y >= map_size.y:
		return true
	return cells[c.y][c.x] == "#"


func is_floor(pos: Vector2) -> bool:
	return not is_void_cell(Vector2i(floori(pos.x / TILE), floori(pos.y / TILE)))


func build(map_name: String, floor_tex: Texture2D, wall_tex: Texture2D, void_col := Color("#16111a"), rim_col := Color("#3a2f42")) -> void:
	void_color = void_col
	rim_color = rim_col
	load_map(map_name)
	_floor_tex = floor_tex
	_wall_tex = wall_tex
	ground = Node2D.new()
	ground.z_index = -20
	add_child(ground)
	var md := MapDraw.new()
	md.arena = self
	ground.add_child(md)
	decals = Node2D.new()
	decals.z_index = -10
	add_child(decals)
	entities = Node2D.new()
	entities.y_sort_enabled = true
	add_child(entities)

	# столкновения: пустые клетки, склеенные по строкам
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	for y in map_size.y:
		var x := 0
		while x < map_size.x:
			if is_void_cell(Vector2i(x, y)):
				var start := x
				while x < map_size.x and is_void_cell(Vector2i(x, y)):
					x += 1
				_add_rect_shape(body, Rect2(start * TILE, y * TILE, (x - start) * TILE, TILE))
			else:
				x += 1

	# поверх краёв карты — запас пустоты, чтобы камера не показывала серый фон
	var bg := ColorRect.new()
	bg.color = void_color
	bg.position = Vector2(-600, -600)
	bg.size = floor_rect.size + Vector2(1200, 1200)
	bg.z_index = -30
	add_child(bg)

	var full := Vector2(map_size * TILE)
	fixed_camera = full.x <= VIEW.x and full.y <= VIEW.y
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()

	hud = preload("res://scripts/ui/hud.gd").new()
	add_child(hud)


func _add_rect_shape(body: StaticBody2D, r: Rect2) -> void:
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	cs.shape = rs
	cs.position = r.position + r.size * 0.5
	body.add_child(cs)


func spawn_player(pos: Vector2, hub := false) -> void:
	player = preload("res://scripts/player.gd").new()
	player.in_hub = hub
	player.position = pos
	entities.add_child(player)
	_cam_pos = _cam_target()
	camera.position = _cam_pos


## Предмет обстановки: спрайт стоит «ногами» на pos, коллизия — прямоугольник у основания.
func prop(tex: Texture2D, pos: Vector2, base: Vector2 = Vector2.ZERO, frames := 1) -> Sprite2D:
	var holder := Node2D.new()
	holder.position = pos
	entities.add_child(holder)
	var s := Sprite2D.new()
	s.texture = tex
	s.hframes = frames
	s.offset = Vector2(0, -tex.get_height() * 0.5)
	holder.add_child(s)
	if base != Vector2.ZERO:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		holder.add_child(body)
		_add_rect_shape(body, Rect2(Vector2(-base.x * 0.5, -base.y), base))
	return s


## Картинка на стене или на полу без сортировки по глубине.
func flat(tex: Texture2D, pos: Vector2, layer: Node = null, frames := 1) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.hframes = frames
	s.centered = false
	s.position = pos
	(layer if layer else ground).add_child(s)
	return s


var _cam_pos := Vector2.ZERO
var _lead := Vector2.ZERO
## Если задано — камера смотрит на эту точку (например, на говорящего босса).
var cam_focus = null


func _cam_target() -> Vector2:
	if cam_focus != null:
		return cam_focus
	if fixed_camera or player == null:
		return Vector2(map_size * TILE) * 0.5 + Vector2(0, -WALL_H * 0.5)
	# как в Hades: камера держится за Озоном и чуть забегает туда, куда он смотрит
	return player.global_position + Vector2(0, -14) + _lead


func _process(delta: float) -> void:
	if camera == null:
		return
	if player and not fixed_camera:
		var want: Vector2 = player.aim * 28.0 if player.state != player.S.DEAD else Vector2.ZERO
		# с боссом камера тянется к нему, чтобы он не терялся за краем экрана
		var boss := get_tree().get_first_node_in_group("boss") as Node2D
		if boss:
			want = (want + (boss.global_position - player.global_position) * 0.35).limit_length(100.0)
		_lead = _lead.lerp(want, 1.0 - exp(-3.0 * delta))
	_cam_pos = _cam_pos.lerp(_cam_target(), 1.0 - exp(-7.0 * delta))
	camera.position = _cam_pos.round() + Game.take_shake(delta)

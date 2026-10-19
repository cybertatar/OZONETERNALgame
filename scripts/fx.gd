extends Node
## Эффекты: взмах, кольцо удара, пыль, вспышка спрайта, всплывающие цифры.


class Drawn extends Node2D:
	## Узел, который рисует себя через переданную функцию, пока живёт `life` секунд.
	var life := 0.2
	var t := 0.0
	var painter: Callable

	func _process(delta: float) -> void:
		t += delta
		if t >= life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		painter.call(self, t / life)


func _spawn(parent: Node, pos: Vector2, life: float, painter: Callable, z := 5) -> Drawn:
	var d := Drawn.new()
	d.life = life
	d.painter = painter
	d.position = pos
	d.z_index = z
	parent.add_child(d)
	return d


## Дуга взмаха кулака.
func swing(owner: Node2D, dir: Vector2, reach: float, big: bool) -> void:
	var ang := dir.angle()
	var col := Color(1, 1, 1, 0.8)
	var width := 3.0 if big else 2.0
	_spawn(owner.get_parent(), owner.global_position + Vector2(0, -10), 0.1, func(n: Node2D, k: float):
		var r := reach * (0.7 + 0.3 * k)
		col.a = 0.8 * (1.0 - k)
		n.draw_arc(Vector2.ZERO, r, ang - 0.9, ang + 0.9, 7, col, width))


## Расходящееся кольцо (усиленный удар, водка, приземление).
func ring(parent: Node, center: Vector2, radius: float, color: Color) -> void:
	_spawn(parent, center, 0.25, func(n: Node2D, k: float):
		var c := color
		c.a = 1.0 - k
		var r := radius * (0.4 + 0.6 * k)
		n.draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, c, 2.0)
		n.draw_arc(Vector2.ZERO, r * 0.5, 0.0, TAU, 16, Color(c, c.a * 0.4), 1.0), -1)


## Клубы пыли.
func dust(parent: Node, pos: Vector2, count: int) -> void:
	var parts := []
	for i in count:
		parts.append([Vector2.from_angle(randf() * TAU) * randf_range(8, 18), randf_range(1.5, 3.0)])
	_spawn(parent, pos, 0.35, func(n: Node2D, k: float):
		for p in parts:
			var s: float = p[1] * (1.0 - k) + 0.5
			var at: Vector2 = (p[0] * k).round() + Vector2(0, -2)
			n.draw_rect(Rect2(at - Vector2(s, s) * 0.5, Vector2(s, s)), Color(0.85, 0.82, 0.75, 0.8 * (1.0 - k))))


## Вспышка спрайта цветом (через шейдер Game.flash_material).
func flash(sprite: CanvasItem, color := Color.WHITE, seconds := 0.12) -> void:
	var m := sprite.material as ShaderMaterial
	if m == null:
		return
	m.set_shader_parameter("flash_color", color)
	m.set_shader_parameter("flash", 1.0)
	var t := sprite.create_tween()
	t.tween_method(func(v: float): m.set_shader_parameter("flash", v), 1.0, 0.0, seconds)


## Всплывающая цифра урона.
func number(parent: Node, pos: Vector2, value: int, color := Color.WHITE) -> void:
	var l := Label.new()
	l.text = str(value)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("#1b1420"))
	l.add_theme_constant_override("outline_size", 2)
	l.position = pos + Vector2(randf_range(-6, 2), 0)
	l.z_index = 60
	parent.add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "position:y", l.position.y - 14, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.25).set_delay(0.35)
	t.tween_callback(l.queue_free)


## Предупреждение об атаке: красный круг на полу, заполняется к моменту удара.
func telegraph_circle(parent: Node, center: Vector2, radius: float, seconds: float) -> Drawn:
	return _spawn(parent, center, seconds, func(n: Node2D, k: float):
		n.draw_circle(Vector2.ZERO, radius, Color(0.85, 0.2, 0.2, 0.18))
		n.draw_circle(Vector2.ZERO, radius * k, Color(0.85, 0.2, 0.2, 0.25))
		n.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, Color(0.95, 0.3, 0.3, 0.8), 1.0), -2)


## Предупреждение о таране: полоса по направлению.
func telegraph_line(parent: Node, from: Vector2, dir: Vector2, length: float, width: float, seconds: float) -> Drawn:
	return _spawn(parent, from, seconds, func(n: Node2D, k: float):
		var side := dir.orthogonal() * width * 0.5
		var end := dir * length
		var poly := PackedVector2Array([side, end + side, end - side, -side])
		n.draw_colored_polygon(poly, Color(0.85, 0.2, 0.2, 0.15 + 0.15 * k))
		n.draw_polyline(PackedVector2Array([side, end + side, end - side, -side, side]), Color(0.95, 0.3, 0.3, 0.8), 1.0), -2)


# --- звуки --------------------------------------------------------------------
# Короткие 8-битные эффекты собираются в коде при запуске: прямоугольная волна и шум.

const RATE := 22050
var _sounds := {}
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# [частота от, частота до, длительность, громкость, шум 0..1]; несколько — подряд
	var defs := {
		"move": [[880, 880, 0.035, 0.18, 0.0]],
		"confirm": [[660, 660, 0.06, 0.25, 0.0], [990, 990, 0.09, 0.25, 0.0]],
		"deny": [[150, 110, 0.16, 0.28, 0.0]],
		"interact": [[520, 780, 0.08, 0.25, 0.0]],
		"swing": [[900, 300, 0.07, 0.12, 0.9]],
		"hit": [[180, 60, 0.09, 0.35, 0.6]],
		"slam": [[120, 40, 0.18, 0.45, 0.7]],
		"dash": [[300, 900, 0.1, 0.14, 0.8]],
		"hurt": [[300, 120, 0.15, 0.35, 0.3]],
		"pop": [[400, 900, 0.08, 0.2, 0.2]],
		"drink": [[180, 140, 0.07, 0.25, 0.0], [170, 130, 0.07, 0.25, 0.0], [160, 120, 0.09, 0.25, 0.0]],
		"door": [[220, 440, 0.12, 0.25, 0.1], [440, 660, 0.1, 0.2, 0.0]],
		"coin": [[988, 988, 0.06, 0.22, 0.0], [1319, 1319, 0.14, 0.22, 0.0]],
	}
	for k in defs:
		_sounds[k] = _make(defs[k])
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func _make(parts: Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	var phase := 0.0
	for part in parts:
		var n := int(RATE * float(part[2]))
		for i in n:
			var k := float(i) / n
			var freq: float = lerpf(part[0], part[1], k)
			phase = fmod(phase + freq / RATE, 1.0)
			var sq := 1.0 if phase < 0.5 else -1.0
			var v: float = lerpf(sq, randf_range(-1.0, 1.0), part[4])
			var env := minf(1.0, i / (RATE * 0.004)) * (1.0 - k) * float(part[3])
			var s := int(clampf(v * env, -1.0, 1.0) * 32000.0)
			data.append(s & 0xFF)
			data.append((s >> 8) & 0xFF)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	return w


func sfx(name: String, pitch := 1.0) -> void:
	if not _sounds.has(name):
		return
	for p in _players:
		if not p.playing:
			p.stream = _sounds[name]
			p.pitch_scale = pitch * randf_range(0.95, 1.05)
			p.play()
			return

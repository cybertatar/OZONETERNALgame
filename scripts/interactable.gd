extends Node2D
## Точка взаимодействия. Когда Озон рядом (ближе radius), над ней висит плашка
## «[кнопка] что будет»; по кнопке «действие» плашка подпрыгивает, вспышка,
## звук — и вызывается action.

const UI := preload("res://scripts/ui/ui.gd")

var prompt := ""
var radius := 20.0
## Где висит плашка относительно точки.
var marker_offset := Vector2(0, -34)
var action: Callable
var focused := false:
	set(v):
		if v != focused:
			focused = v
			_show(v)

var _t := 0.0
var _pop := 0.0
var _alpha := 0.0


func _ready() -> void:
	add_to_group("interactables")
	z_index = 40


func interact(_who: Node) -> void:
	_pop = 1.0
	Fx.sfx("interact")
	Fx.ring(get_parent(), global_position + marker_offset * 0.5, 14.0, UI.GOLD)
	action.call()


func _show(v: bool) -> void:
	var t := create_tween()
	t.tween_property(self, "_alpha", 1.0 if v else 0.0, 0.12)


func _process(delta: float) -> void:
	_t += delta
	_pop = maxf(_pop - delta * 4.0, 0.0)
	if _alpha > 0.0 or _pop > 0.0:
		queue_redraw()


func _draw() -> void:
	if _alpha <= 0.01:
		return
	var f: Font = Game.font_bold
	var key := Game.key_name("interact")
	var size := UI.SMALL
	var kw := f.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var tw := f.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var w := kw + 8 + tw + 10
	var h := 13.0
	var bob := roundf(sin(_t * 4.0) * 1.0) - _pop * 6.0
	var s := 1.0 + _pop * 0.25
	draw_set_transform(marker_offset + Vector2(0, bob), 0.0, Vector2(s, s))
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	var a := _alpha
	draw_rect(r.grow(1), Color(UI.INK, a))
	draw_rect(r, Color(Color("#231d29"), a * 0.95))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color(UI.GOLD, a * (0.5 + _pop * 0.5)))
	# кнопка в золотой рамке
	var kr := Rect2(r.position + Vector2(3, 2), Vector2(kw + 4, h - 4))
	draw_rect(kr, Color(UI.GOLD, a))
	draw_string(f, kr.position + Vector2(2, 7.5), key, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(UI.INK, a))
	draw_string(f, Vector2(kr.end.x + 4, r.position.y + 9.5), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(UI.PAPER, a))
	# стрелочка вниз к предмету
	draw_colored_polygon(PackedVector2Array([Vector2(-3, h * 0.5), Vector2(3, h * 0.5), Vector2(0, h * 0.5 + 3)]), Color(Color("#231d29"), a))

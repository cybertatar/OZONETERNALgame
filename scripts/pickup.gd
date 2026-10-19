extends Node2D
## Награда с босса: отрывок «Тихого Дена» ("page") или новый напиток ("vodka").

var kind := "page"
## Какой отрывок «Тихого Дена» лежит в записке (-1 — следующий ненайденный).
var page_index := -1
var t := 0.0
var sprite: Sprite2D


func _ready() -> void:
	var sh := Sprite2D.new()
	sh.texture = preload("res://assets/sprites/shadow_s.png")
	add_child(sh)
	sprite = Sprite2D.new()
	sprite.texture = preload("res://assets/sprites/book_page.png") if kind == "page" else preload("res://assets/sprites/vodka.png")
	add_child(sprite)
	scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	t += delta
	sprite.position.y = -12.0 + round(sin(t * 3.0) * 2.0)


func collect() -> void:
	var hud = Game.world().hud
	if kind == "page":
		var i := Game.add_page(page_index)
		Game.voice("pick_book")
		if i >= 0:
			var note := preload("res://scripts/ui/note.gd").new()
			note.index = i
			hud.add_child(note)
	else:
		hud.toast("Новый напиток на столе: водка", 2.5)
		Game.voice("pick_vodka")
	Fx.ring(get_parent(), global_position, 18.0, Color("#e8c35a"))
	Fx.sfx("coin")
	queue_free()

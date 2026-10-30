class_name SeedShot
extends Node2D
## Slow homing-ish seed spat by the Corrupted Pumpkin King.

const TEX := preload("res://assets/generated/fx/seed_shot.png")

var dir := Vector2.DOWN
var speed := 46.0
var ttl := 3.6
var game: Node
var sprite: Sprite2D
var _spin := 0.0
var thorn := false


func setup(at: Vector2, towards: Vector2, game_ref: Node) -> void:
	position = at
	dir = towards.normalized()
	game = game_ref


func _ready() -> void:
	z_index = 2600
	sprite = Sprite2D.new()
	sprite.texture = TEX
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if thorn:
		sprite.modulate = Color(0.55, 1.0, 0.55)
		scale = Vector2(0.7, 0.7)
		speed = 74.0
		ttl = 2.6
	add_child(sprite)


func _process(delta: float) -> void:
	ttl -= delta
	if ttl <= 0.0:
		queue_free()
		return
	position += dir * speed * delta
	_spin += delta * 9.0
	sprite.rotation = _spin
	if game == null or game.player == null or game.player.dead:
		return
	if position.distance_to(game.player.position) < 7.0:
		game.player.hurt(1, self)
		game.burst(position, Color("#7ee3a0") if thorn else Color("#e8893a"), 6)
		queue_free()

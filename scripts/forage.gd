class_name Forage
extends Node2D
## A little shell or starfish on the beach. Walk over it to collect gold.

const SHELL := preload("res://assets/generated/items/shell.png")
const STAR := preload("res://assets/generated/items/star.png")

var game: Node
var kind := "shell"
var value := 3
var sprite: Sprite2D
var _t := 0.0
var collected := false


func setup(game_ref: Node, forage_kind: String, amount: int) -> void:
	game = game_ref
	kind = forage_kind
	value = amount


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = SHELL if kind == "shell" else STAR
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	z_index = 900
	scale = Vector2(1.0, 1.0)


func _process(delta: float) -> void:
	if collected or game == null or game.player == null:
		return
	_t += delta
	sprite.position.y = sin(_t * 3.2) * 1.5
	z_index = int(position.y) + 3
	if global_position.distance_to(game.player.global_position) < 9.0:
		collected = true
		game.collect_forage(self)

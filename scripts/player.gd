class_name Player
extends CharacterBody2D
## The farmer. Moves with WASD/arrows, swings the scythe with space or mouse.

signal died

const SHEET := preload("res://assets/generated/chars/player.png")
const SHADOW := preload("res://assets/generated/chars/shadow.png")
const SLASH := preload("res://assets/generated/fx/slash.png")

const BASE_SPEED := 62.0
const BASE_HP := 6

var game: Node
var sprite: Sprite2D
var shadow: Sprite2D
var rune: Sprite2D
var speed := BASE_SPEED
var hp := BASE_HP
var max_hp := BASE_HP
var facing := Vector2.DOWN
var attack_cd := 0.0
var invuln := 0.0
var hurt_flash := 0.0
var step_t := 0.0
var moving := false
var dead := false
var last_aim := Vector2.ZERO
var foot_t := 0.0
var has_move_target := false
var move_target := Vector2.ZERO


func setup(game_ref: Node) -> void:
	game = game_ref


func _ready() -> void:
	collision_layer = 1
	collision_mask = 4
	z_index = 2000
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, 2)
	add_child(cs)
	shadow = Sprite2D.new()
	shadow.texture = SHADOW
	shadow.position = Vector2(0, 6)
	shadow.modulate = Color(1, 1, 1, 0.8)
	add_child(shadow)
	sprite = Sprite2D.new()
	sprite.texture = SHEET
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, -4)
	sprite.frame = 0
	add_child(sprite)


func _physics_process(delta: float) -> void:
	attack_cd = maxf(0.0, attack_cd - delta)
	invuln = maxf(0.0, invuln - delta)
	if hurt_flash > 0.0:
		hurt_flash = maxf(0.0, hurt_flash - delta)
		sprite.self_modulate = Color(1.0, 0.6, 0.6, 1.0) if int(hurt_flash * 20.0) % 2 == 0 else Color.WHITE
	else:
		sprite.self_modulate = Color.WHITE
	if dead:
		return
	if not game.can_control():
		velocity = Vector2.ZERO
		return
	var dir := Vector2.ZERO
	var keyboard := Vector2.ZERO
	if game.is_mobile and game.mobile != null and game.mobile.move_vector.length() > 0.01:
		dir = game.mobile.move_vector
		has_move_target = false
	else:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			keyboard.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			keyboard.x += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			keyboard.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			keyboard.y += 1.0
		if keyboard != Vector2.ZERO:
			has_move_target = false
			dir = keyboard
		elif has_move_target:
			var to_target := move_target - position
			if to_target.length() <= 2.0:
				has_move_target = false
				dir = Vector2.ZERO
			else:
				dir = to_target.normalized()
	moving = dir != Vector2.ZERO
	speed = BASE_SPEED * float(game.move_mult())
	if moving:
		var strength := minf(1.0, dir.length())
		dir = dir.normalized()
		velocity = dir * speed * strength
		if absf(dir.x) > absf(dir.y):
			facing = Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
		else:
			facing = Vector2.DOWN if dir.y > 0 else Vector2.UP
		var target_aim := dir
		last_aim = target_aim
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	# clamp inside the island walkway (walls also exist; this is a safety net)
	position.x = clampf(position.x, -8.0, 248.0)
	position.y = clampf(position.y, -8.0, 136.0)
	if moving:
		foot_t -= delta
		if foot_t <= 0.0:
			foot_t = 0.30
			game.burst(position + Vector2(0, 7), Color(0.82, 0.76, 0.60, 0.7), 2)
	_animate(delta)
	# attack input: space held, right mouse held (desktop), or the touch button
	if Input.is_key_pressed(KEY_SPACE) or game.touch_attack_held \
			or (not game.is_mobile and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)):
		attack()


func _animate(delta: float) -> void:
	var row := 0
	if absf(facing.x) > absf(facing.y):
		row = 2 if facing.x > 0 else 1
	elif facing.y < 0:
		row = 3
	else:
		row = 0
	if moving:
		step_t += delta * 9.0
	else:
		step_t = 0.0
	var col := int(step_t) % 4 if moving else 0
	sprite.frame = row * 4 + col
	shadow.scale = Vector2(1, 1) if moving else Vector2(1.05, 1.0)


func attack() -> void:
	if attack_cd > 0.0 or dead or not game.can_control():
		return
	attack_cd = 0.38 / float(game.aspd_mult())
	var dir := facing
	if SaveGame.auto_aim:
		var best: Enemy = null
		var best_d := 90.0
		for e in game.enemies:
			if not is_instance_valid(e) or e.dead:
				continue
			var d: float = global_position.distance_to(e.global_position)
			if d < best_d:
				best_d = d
				best = e
		if best != null:
			dir = (best.global_position - global_position).normalized()
			facing = _snap_facing(dir)
	elif not game.is_mobile:
		var m := get_global_mouse_position()
		var d := m - global_position
		if d.length() > 2.0:
			dir = d.normalized()
			facing = _snap_facing(dir)
	var slash := Sprite2D.new()
	slash.texture = SLASH
	slash.position = position + dir * 12.0 + Vector2(0, -2)
	slash.rotation = dir.angle()
	slash.scale = Vector2(0.9, 0.9) * (1.0 + 0.1 * float(game.range_mult()))
	slash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	slash.z_index = 2100
	get_parent().add_child(slash)
	var tw := slash.create_tween()
	tw.set_parallel(true)
	tw.tween_property(slash, "modulate:a", 0.0, 0.16)
	tw.tween_property(slash, "scale", slash.scale * 1.25, 0.16)
	tw.chain().tween_callback(slash.queue_free)
	game.player_attack(self, dir)


func move_to(point: Vector2) -> void:
	move_target = point
	has_move_target = true


func stop_moving() -> void:
	has_move_target = false


func _snap_facing(d: Vector2) -> Vector2:
	if absf(d.x) > absf(d.y) * 1.3:
		return Vector2.RIGHT if d.x > 0 else Vector2.LEFT
	if absf(d.y) > absf(d.x) * 1.3:
		return Vector2.DOWN if d.y > 0 else Vector2.UP
	return facing


func hurt(amount: int, source: Node = null) -> void:
	if dead or invuln > 0.0:
		return
	hp -= amount
	invuln = 0.9
	hurt_flash = 0.5
	game.on_player_hurt(amount, source)
	if hp <= 0:
		hp = 0
		die()


func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)
	game.hud.refresh_hearts(hp, max_hp)


func die() -> void:
	if dead:
		return
	dead = true
	velocity = Vector2.ZERO
	died.emit()


func set_max_hp(value: int, heal_amount: int = 0) -> void:
	max_hp = value
	hp = clampi(hp + heal_amount, 1, max_hp)

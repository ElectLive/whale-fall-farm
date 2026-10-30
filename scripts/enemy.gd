class_name Enemy
extends CharacterBody2D
## Night invader. Slimes and vines chase the farmer; crows go for the crops first.

var kind := "slime"
var game: Node
var sprite: Sprite2D
var shadow: Sprite2D
var hp := 3
var max_hp := 3
var speed := 20.0
var damage := 1
var gold := 2
var armor := 0
var dead := false
var flash := 0.0
var anim_t := 0.0
var atk_cd := 0.0
var knock := Vector2.ZERO
var target_crop: Crop = null
var retarget_cd := 0.0
var eat_t := 0.0
var frame_count := 1
var enraged := false
var is_boss := false
var boss_phase := 0
var boss_mod := ""
var regen_acc := 0.0
var elite := false
var shoot_cd := 2.2
var sprite_size := 16
var hop_clock := 0.8
var leap_time := 0.0
var dash_cd := 1.5
var dash_time := 0.0
var dash_dir := Vector2.ZERO


func setup(enemy_kind: String, at: Vector2, game_ref: Node, hp_mult: float = 1.0) -> void:
	kind = enemy_kind
	game = game_ref
	var info: Dictionary = GameData.ENEMIES[kind]
	is_boss = bool(info.get("boss", false))
	sprite_size = int(info.get("size", 16))
	max_hp = maxi(1, roundi(float(info["hp"]) * hp_mult))
	hp = max_hp
	speed = float(info["speed"])
	damage = int(info["damage"])
	gold = int(info["gold"])
	armor = int(info.get("armor", 0))
	position = at


func _ready() -> void:
	speed *= float(game.enemy_speed_mult())
	collision_layer = 2
	collision_mask = 4
	z_index = int(position.y) + 1
	var info: Dictionary = GameData.ENEMIES[kind]
	var shape := CircleShape2D.new()
	shape.radius = 8.0 if is_boss else 5.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	shadow = Sprite2D.new()
	shadow.texture = preload("res://assets/generated/chars/shadow.png")
	shadow.position = Vector2(0, 5 if not is_boss else 12)
	shadow.modulate = Color(1, 1, 1, 0.7)
	if is_boss:
		shadow.scale = Vector2(1.8, 1.5)
	add_child(shadow)
	sprite = Sprite2D.new()
	sprite.texture = load(info["texture"])
	frame_count = int(info["frames"])
	sprite.hframes = frame_count
	sprite.vframes = 1
	sprite.frame = 0
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, -3) if not is_boss else Vector2(0, -10)
	var enemy_scale := 1.18 if kind == "vine" else float(info.get("scale", 1.0))
	if is_boss:
		enemy_scale = 1.15
	sprite.scale = Vector2(enemy_scale, enemy_scale)
	if kind == "gull":
		sprite.modulate = Color(0.86, 0.92, 1.0)
	add_child(sprite)
	queue_redraw()
	if is_boss:
		game.burst(position, Color("#e8893a"), 18)


func _physics_process(delta: float) -> void:
	if dead:
		return
	z_index = int(position.y) + 1
	anim_t += delta
	sprite.frame = int(anim_t * 7.0) % frame_count
	atk_cd = maxf(0.0, atk_cd - delta)
	retarget_cd = maxf(0.0, retarget_cd - delta)
	if flash > 0.0:
		flash = maxf(0.0, flash - delta)
		sprite.self_modulate = Color(1.0, 0.55, 0.55) if int(flash * 30.0) % 2 == 0 else Color.WHITE
	else:
		sprite.self_modulate = Color.WHITE
	var player: Player = game.player
	if player == null or player.dead:
		velocity = Vector2.ZERO
		return
	var desired := Vector2.ZERO
	if is_boss:
		desired = _boss_behaviour(delta)
	elif kind == "slime":
		desired = _slime_behaviour(delta, player)
	elif kind == "vine":
		desired = _vine_behaviour(delta, player)
	elif kind == "frog":
		desired = _frog_behaviour(delta)
	elif kind == "crow" or kind == "gull":
		desired = _crow_behaviour(delta)
	else:
		desired = (player.global_position - global_position)
		if desired.length() < 4.0:
			desired = Vector2.ZERO
		else:
			desired = desired.normalized() * speed * (0.7 if kind == "vine" and sin(anim_t * 2.0) > 0.6 else 1.0)
	# separation so monsters don't stack into a single pixel
	if not is_boss:
		for other in game.enemies:
			if other == self or other.dead:
				continue
			var d: Vector2 = global_position - other.global_position
			if d.length() < 11.0 and d.length() > 0.01:
				desired += d.normalized() * 14.0
	if knock.length() > 1.0:
		desired += knock
		knock = knock.move_toward(Vector2.ZERO, 220.0 * delta)
	velocity = desired
	move_and_slide()
	# contact damage
	var dist := global_position.distance_to(player.global_position)
	var reach := 16.0 if is_boss else 11.0
	if dist < reach and atk_cd <= 0.0:
		atk_cd = 1.2 if is_boss else 1.0
		player.hurt(damage, self)


func _slime_behaviour(delta: float, player: Player) -> Vector2:
	var to_player: Vector2 = player.global_position - global_position
	if dash_time > 0.0:
		dash_time -= delta
		return dash_dir * speed * 3.2
	if GameData.diff_index() >= 2 and to_player.length() < 78.0:
		dash_cd -= delta
		if dash_cd <= 0.0:
			dash_cd = 2.6 if GameData.diff_index() >= 3 else 3.2
			dash_time = 0.30
			dash_dir = to_player.normalized()
			return dash_dir * speed * 1.2
	if to_player.length() < 4.0:
		return Vector2.ZERO
	return to_player.normalized() * speed


func _vine_behaviour(delta: float, player: Player) -> Vector2:
	var to_player: Vector2 = player.global_position - global_position
	shoot_cd -= delta
	if GameData.diff_index() >= 2 and shoot_cd <= 0.0 and to_player.length() < 150.0 and to_player.length() > 36.0:
		shoot_cd = 2.8 if GameData.diff_index() >= 3 else 3.6
		game.enemy_shoot(self)
	if to_player.length() < 12.0:
		return Vector2.ZERO
	return to_player.normalized() * speed


func _frog_behaviour(delta: float) -> Vector2:
	if leap_time > 0.0:
		leap_time -= delta
		sprite.frame = 1
		var d: Vector2 = game.player.global_position - global_position
		if d.length() < 4.0:
			return Vector2.ZERO
		return d.normalized() * speed
	sprite.frame = 0
	hop_clock -= delta
	if hop_clock <= 0.0:
		hop_clock = 1.25
		leap_time = 0.42
	return Vector2.ZERO


func _boss_behaviour(delta: float) -> Vector2:
	var to_player: Vector2 = game.player.global_position - global_position
	var desired := Vector2.ZERO
	if to_player.length() > 24.0:
		desired = to_player.normalized() * speed
	if boss_mod == "regen" and hp < max_hp:
		regen_acc += delta
		if regen_acc >= 1.0:
			regen_acc -= 1.0
			hp = mini(max_hp, hp + 1)
			queue_redraw()
	shoot_cd -= delta
	if shoot_cd <= 0.0:
		shoot_cd = maxf(1.4, 3.2 - boss_phase * 0.6)
		game.boss_shoot(self)
	if boss_phase == 0 and hp <= max_hp * 0.66:
		boss_phase = 1
		game.boss_summon(self)
		game.boss_radial(self, 8)
		shoot_cd = minf(shoot_cd, 1.2)
	elif boss_phase == 1 and hp <= max_hp * 0.33:
		boss_phase = 2
		game.boss_summon(self)
		game.boss_radial(self, 12)
		shoot_cd = 0.6
	return desired


func _crow_behaviour(delta: float) -> Vector2:
	if target_crop != null and (not is_instance_valid(target_crop) or target_crop.is_queued_for_deletion()):
		target_crop = null
	if target_crop == null and retarget_cd <= 0.0:
		retarget_cd = 1.6
		target_crop = _nearest_crop()
	if target_crop != null and is_instance_valid(target_crop):
		var d := target_crop.global_position - global_position
		if d.length() < 6.0:
			eat_t += delta
			if eat_t > 1.4:
				eat_t = 0.0
				var victim := target_crop
				target_crop = null
				game.crow_eat_crop(self, victim)
			return Vector2.ZERO
		eat_t = 0.0
		return d.normalized() * speed
	eat_t = 0.0
	var to_player: Vector2 = game.player.global_position - global_position
	return to_player.normalized() * speed


func _nearest_crop() -> Crop:
	var best: Crop = null
	var best_d := 1e20
	for c in game.crops:
		if not is_instance_valid(c) or c.is_queued_for_deletion():
			continue
		var d: float = global_position.distance_squared_to(c.global_position)
		if c.mature:
			d *= 0.5
		if d < best_d:
			best_d = d
			best = c
	return best


func take_damage(amount: int, from_dir: Vector2) -> void:
	if dead:
		return
	if armor > 0:
		amount = maxi(1, amount - armor)
	hp -= amount
	flash = 0.22
	knock = from_dir.normalized() * (26.0 if is_boss else 70.0)
	game.on_enemy_damaged(self, amount)
	queue_redraw()
	if hp <= 0:
		die()


func die() -> void:
	if dead:
		return
	dead = true
	game.on_enemy_died(self)
	queue_free()


func enrage() -> void:
	if enraged:
		return
	enraged = true
	speed *= 1.25
	sprite.modulate = Color(1.0, 0.72, 0.72)
	queue_redraw()


func apply_boss_mod(id: String) -> void:
	boss_mod = id
	match id:
		"rage":
			speed *= 1.3
			sprite.modulate = Color(1.25, 0.72, 0.65)
		"regen":
			sprite.modulate = Color(0.72, 1.2, 0.85)
		"summon":
			sprite.modulate = Color(1.1, 0.8, 1.25)


func make_elite() -> void:
	if elite or is_boss:
		return
	elite = true
	max_hp *= 2
	hp = max_hp
	gold *= 2
	speed *= 1.1
	if sprite:
		sprite.scale *= 1.22
		sprite.modulate = Color(1.25, 1.02, 0.55)
	queue_redraw()


func _draw() -> void:
	if hp >= max_hp:
		return
	var w := 30.0 if is_boss else 16.0
	var y := -30.0 if is_boss else -13.0
	draw_rect(Rect2(-w * 0.5 - 1, y - 1, w + 2, 4), Color(0.04, 0.05, 0.09, 0.85))
	draw_rect(Rect2(-w * 0.5, y, w * clampf(float(hp) / float(max_hp), 0.0, 1.0), 2), Color("#e2556b"))

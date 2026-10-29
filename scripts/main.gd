extends Node2D
## Whale Fall Farm — main game controller.
##
## Day: tend the farm. Night: survive the tide of monsters. Every dawn you pick
## one blessing, and the run is different every time (random map, waves, relics).

enum State { TITLE, DAY, NIGHT, DAWN, GAMEOVER, VICTORY, PAUSED }

const DAY_LENGTH := 75.0
const SPAWN_INTERVAL_BASE := 1.9

var state: int = State.TITLE
var prev_state: int = State.DAY

var world: Node2D
var sea: Sea
var island: Island
var farm: Farm
var crops_root: Node2D
var entities: Node2D
var fx: Node2D
var fireflies: CPUParticles2D
var rain_particles: CPUParticles2D
var camera: Camera2D
var ambient: CanvasModulate
var ui_layer: CanvasLayer
var overlay_layer: CanvasLayer
var hud: Hud
var title_screen: TitleScreen
var dawn_screen: DawnScreen
var end_screen: EndScreen
var pause_screen: PauseScreen

var player: Player
var enemies: Array[Enemy] = []
var crops: Array[Crop] = []
var relic_ids: Array[String] = []
var boss: Enemy = null
var boss_ending := false
var shop_offers: Array = []
var shop_sold: Array[bool] = []
var mobile: MobileControls
var mobile_layer: CanvasLayer
var is_mobile := false
var touch_attack_held := false

var day := 1
var gold := 0
var run_gold := 0
var day_gold := 0
var kills := 0
var day_kills := 0
var seeds := {"radish": 4, "pumpkin": 1, "star": 0, "moonwheat": 0}
var selected_seed := 0
var rainy := false
var mods := {}
var rng := RandomNumberGenerator.new()

var phase_time := 0.0
var phase_total := 1.0
var night_queue: Array[String] = []
var spawn_timer := 0.0
var enrage_done := false
var run_active := false
var endless := false
var _run_recorded := false
var test_mode := false
var _shake := 0.0
var _ambient_tween: Tween
var _seeds_dirty := true
var _hearts_dirty := true


func _ready() -> void:
	rng.randomize()
	is_mobile = OS.has_feature("mobile")
	if "--touch" in OS.get_cmdline_user_args():
		is_mobile = true
	mods = _fresh_mods()
	_build_world()
	_build_ui()
	_connect_ui()
	if is_mobile:
		_enable_mobile()
	Audio.set_music_on(SaveGame.music_on)
	Audio.set_sfx_on(SaveGame.sfx_on)
	show_title()

func _fresh_mods() -> Dictionary:
	return {
		"move": 1.0, "dmg": 1.0, "aspd": 1.0, "growth": 1.0, "gold": 1.0,
		"range": 1.0, "lifesteal": 0.0, "thorns": 0, "luck": 0.0,
		"dawn_heal": 0, "night_move": 1.0, "maxhp": 0,
		"slow": 1.0, "water_boost": 0.0,
	}


# ------------------------------------------------------------------ setup
func _build_world() -> void:
	world = Node2D.new()
	world.name = "World"
	add_child(world)

	sea = Sea.new()
	world.add_child(sea)

	island = Island.new()
	world.add_child(island)

	farm = Farm.new()
	world.add_child(farm)
	farm.setup(1)

	crops_root = Node2D.new()
	crops_root.name = "Crops"
	world.add_child(crops_root)

	entities = Node2D.new()
	entities.name = "Entities"
	world.add_child(entities)

	fx = Node2D.new()
	fx.name = "Fx"
	fx.z_index = 3000
	world.add_child(fx)

	fireflies = CPUParticles2D.new()
	fireflies.name = "Fireflies"
	fireflies.texture = preload("res://assets/generated/fx/glow.png")
	fireflies.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fireflies.amount = 34
	fireflies.lifetime = 4.0
	fireflies.preprocess = 2.0
	fireflies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fireflies.emission_rect_extents = Vector2(126, 66)
	fireflies.position = Vector2(120, 64)
	fireflies.direction = Vector2.UP
	fireflies.spread = 180.0
	fireflies.initial_velocity_min = 1.0
	fireflies.initial_velocity_max = 5.0
	fireflies.gravity = Vector2.ZERO
	fireflies.scale_amount_min = 0.05
	fireflies.scale_amount_max = 0.12
	fireflies.color = Color(1.0, 0.94, 0.6, 0.75)
	fireflies.emitting = false
	fireflies.z_index = 1500
	world.add_child(fireflies)

	rain_particles = CPUParticles2D.new()
	rain_particles.name = "Rain"
	rain_particles.texture = preload("res://assets/generated/fx/rain.png")
	rain_particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rain_particles.amount = 160
	rain_particles.lifetime = 1.15
	rain_particles.preprocess = 1.0
	rain_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain_particles.emission_rect_extents = Vector2(152, 82)
	rain_particles.position = Vector2(120, 40)
	rain_particles.direction = Vector2.DOWN
	rain_particles.spread = 6.0
	rain_particles.initial_velocity_min = 145.0
	rain_particles.initial_velocity_max = 195.0
	rain_particles.gravity = Vector2(0, 90)
	rain_particles.scale_amount_min = 0.8
	rain_particles.scale_amount_max = 1.25
	rain_particles.color = Color(0.72, 0.86, 0.95, 0.55)
	rain_particles.emitting = false
	rain_particles.z_index = 2600
	world.add_child(rain_particles)

	camera = Camera2D.new()
	camera.position = Vector2(120, 64)
	camera.zoom = Vector2(4, 4)
	camera.enabled = true
	world.add_child(camera)

	ambient = CanvasModulate.new()
	ambient.color = Color(1, 1, 1)
	world.add_child(ambient)

	# invisible walls at the island edge
	var walls := StaticBody2D.new()
	walls.collision_layer = 4
	walls.collision_mask = 0
	world.add_child(walls)
	for spec in [
		[Vector2(120, -18), Vector2(300, 8)],
		[Vector2(120, 146), Vector2(300, 8)],
		[Vector2(-18, 64), Vector2(8, 180)],
		[Vector2(258, 64), Vector2(8, 180)],
	]:
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = spec[1]
		cs.shape = shape
		cs.position = spec[0]
		walls.add_child(cs)
	world.visible = false


func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	hud = Hud.new()
	ui_layer.add_child(hud)
	hud.visible = false

	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 20
	add_child(overlay_layer)
	title_screen = TitleScreen.new()
	overlay_layer.add_child(title_screen)
	dawn_screen = DawnScreen.new()
	overlay_layer.add_child(dawn_screen)
	end_screen = EndScreen.new()
	overlay_layer.add_child(end_screen)
	pause_screen = PauseScreen.new()
	overlay_layer.add_child(pause_screen)


func _connect_ui() -> void:
	title_screen.start_requested.connect(func() -> void: start_new_run())
	title_screen.quit_requested.connect(func() -> void: get_tree().quit())
	dawn_screen.relic_chosen.connect(_on_relic_chosen)
	dawn_screen.continue_pressed.connect(_on_dawn_continue)
	dawn_screen.shop_buy.connect(_on_shop_buy)
	end_screen.restart_requested.connect(func() -> void: start_new_run())
	end_screen.title_requested.connect(show_title)
	end_screen.endless_requested.connect(_on_endless_requested)
	pause_screen.resume_requested.connect(_toggle_pause)
	pause_screen.title_requested.connect(show_title)
	pause_screen.toggle_music.connect(_toggle_music)
	pause_screen.toggle_sfx.connect(_toggle_sfx)
	pause_screen.toggle_fullscreen.connect(_toggle_fullscreen_from_pause)
	hud.seed_selected.connect(_select_seed)


func _enable_mobile() -> void:
	if mobile != null:
		mobile.set_active(true)
		hud.set_mobile(true)
		return
	is_mobile = true
	mobile_layer = CanvasLayer.new()
	mobile_layer.layer = 15
	add_child(mobile_layer)
	mobile = MobileControls.new()
	mobile_layer.add_child(mobile)
	mobile.attack_changed.connect(func(held: bool) -> void:
		touch_attack_held = held)
	mobile.attack_tap.connect(_on_mobile_attack)
	mobile.interact_pressed.connect(func() -> void:
		if can_control():
			interact())
	mobile.pause_pressed.connect(func() -> void:
		if state == State.DAY or state == State.NIGHT or state == State.PAUSED:
			_toggle_pause())
	hud.set_mobile(true)
	mobile.set_active(false)


func _on_mobile_attack() -> void:
	if can_control() and player != null:
		player.attack()


func show_title() -> void:
	run_active = false
	state = State.TITLE
	world.visible = false
	hud.visible = false
	title_screen.visible = true
	dawn_screen.visible = false
	end_screen.visible = false
	pause_screen.visible = false
	_clear_run()
	Audio.stop_ambience()
	if mobile:
		mobile.set_active(false)
	Audio.play_music("title")

func start_new_run(seed_value: int = 0) -> void:
	_clear_run()
	run_active = true
	fireflies.emitting = false
	day = 1
	gold = 18
	run_gold = 0
	day_gold = 0
	kills = 0
	day_kills = 0
	endless = false
	_run_recorded = false
	seeds = {"radish": 4, "pumpkin": 1, "star": 0, "moonwheat": 0}
	selected_seed = 0
	rainy = false
	relic_ids.clear()
	mods = _fresh_mods()
	boss = null
	shop_offers.clear()
	shop_sold.clear()
	if seed_value == 0:
		seed_value = rng.randi()
	farm.setup(seed_value)
	world.visible = true
	hud.visible = true
	hud.hide_boss()
	if mobile:
		mobile.set_active(true)
	title_screen.visible = false
	dawn_screen.visible = false
	end_screen.visible = false
	pause_screen.visible = false

	player = Player.new()
	player.setup(self)
	player.position = farm.tile_center(Vector2i(7, 4))
	entities.add_child(player)
	player.died.connect(_on_player_signal_died)

	state = State.DAY
	day_setup()
	Audio.play_music("day")
	Audio.sfx("dawn", 1.0, -6.0)
	_seeds_dirty = true
	_hearts_dirty = true
	_update_hud(true)


func _clear_run() -> void:
	_clear_shots()
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	boss = null
	boss_ending = false
	if hud != null:
		hud.hide_boss()
	for c in crops:
		if is_instance_valid(c):
			c.queue_free()
	crops.clear()
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = null
	for child in fx.get_children():
		child.queue_free()
	night_queue.clear()


func _clear_shots() -> void:
	for n in get_tree().get_nodes_in_group("seed_shots"):
		if is_instance_valid(n):
			n.queue_free()


func day_setup() -> void:
	state = State.DAY
	phase_total = DAY_LENGTH
	phase_time = DAY_LENGTH
	day_gold = 0
	day_kills = 0
	fireflies.emitting = false
	sea.set_night(false)
	if rainy:
		for c in crops:
			if is_instance_valid(c) and not c.mature:
				c.water()
		rain_particles.emitting = true
		Audio.play_ambience("rain")
		_tween_ambient(Color(0.84, 0.88, 0.97))
		hud.banner("第 %d 天 · 雨天" % day, Color("#8fd3d6"), 1.0)
	else:
		rain_particles.emitting = false
		Audio.stop_ambience()
		_tween_ambient(Color(1, 1, 1))
		if endless:
			hud.banner("无尽 · 第 %d 天" % day, Color("#f2c94c"), 0.9)
		else:
			hud.banner("第 %d 天 · 天亮" % day, Color("#f6e7b4"), 0.9)
	hud.set_day(day, "白天", Color("#8fe0b0"))
	_seeds_dirty = true


func _roll_weather() -> void:
	rainy = day > 1 and rng.randf() < 0.30


# ------------------------------------------------------------------ state flow
func can_control() -> bool:
	return state == State.DAY or state == State.NIGHT


func move_mult() -> float:
	var m := float(mods["move"])
	if state == State.NIGHT:
		m *= float(mods["night_move"])
	return m


func aspd_mult() -> float:
	return float(mods["aspd"])


func growth_mult() -> float:
	return float(mods["growth"])


func range_mult() -> float:
	return float(mods["range"])


func enemy_speed_mult() -> float:
	return float(mods["slow"])


func is_night_phase() -> bool:
	return state == State.NIGHT


func is_raining() -> bool:
	return rainy and state == State.DAY


func _is_boss_night(d: int) -> bool:
	return d >= GameData.WIN_DAY and (d - GameData.WIN_DAY) % 3 == 0


func _process(delta: float) -> void:
	_tick_shake(delta)
	if state == State.DAY:
		phase_time -= delta
		if phase_time <= 0.0:
			start_night()
	elif state == State.NIGHT:
		phase_time -= delta
		spawn_timer -= delta
		_tick_spawning()
		if phase_time <= 0.0 and not enrage_done:
			enrage_done = true
			for e in enemies:
				if is_instance_valid(e) and not e.dead:
					e.enrage()
		if phase_time < -12.0 and boss == null:
			_flee_enemies()
			_end_night()
		elif night_queue.is_empty() and enemies.is_empty() and phase_time < phase_total - 1.0 and not boss_ending:
			_end_night()
	if run_active and state in [State.DAY, State.NIGHT]:
		_update_hud(false)


func start_night() -> void:
	if state != State.DAY:
		return
	state = State.NIGHT
	phase_total = GameData.night_duration(day)
	phase_time = phase_total
	enrage_done = false
	boss = null
	boss_ending = false
	_clear_shots()
	hud.hide_boss()
	night_queue.clear()
	var plan := GameData.night_plan(day)
	for entry in plan:
		for i in range(int(entry["count"])):
			night_queue.append(entry["kind"])
	night_queue.shuffle()
	spawn_timer = 1.1
	rainy = false
	rain_particles.emitting = false
	Audio.stop_ambience()
	fireflies.emitting = true
	sea.set_night(true)
	_tween_ambient(Color(0.60, 0.65, 0.88))
	Audio.play_music("night")
	Audio.sfx("horn", 1.0, -4.0)
	hud.set_day(day, "夜晚", Color("#9a8fe0"))
	hud.banner("第 %d 夜 · 涨潮了" % day, Color("#9a8fe0"), 1.0)
	if _is_boss_night(day):
		get_tree().create_timer(1.8).timeout.connect(_spawn_boss)
	_update_hud(true)


func _spawn_boss() -> void:
	if state != State.NIGHT or boss != null:
		return
	var e := Enemy.new()
	e.setup("boss", Vector2(120, -14), self, GameData.hp_scale(day))
	entities.add_child(e)
	enemies.append(e)
	boss = e
	hud.show_boss(String(GameData.ENEMIES["boss"]["name"]), e.hp, e.max_hp)
	hud.banner("腐化南瓜王苏醒了", Color("#ff9a5c"), 1.8)
	Audio.play_music("boss")
	Audio.sfx("boss_roar")
	shake(9.0)
	burst(e.position + Vector2(0, 10), Color("#e8893a"), 20)


func _tick_spawning() -> void:
	var interval := maxf(0.7, SPAWN_INTERVAL_BASE - day * 0.09)
	while spawn_timer <= 0.0 and not night_queue.is_empty():
		var kind: String = night_queue.pop_front()
		_spawn_enemy(kind)
		spawn_timer += interval


func _spawn_enemy(kind: String) -> Enemy:
	return _spawn_enemy_at(kind, _edge_position())


func _spawn_enemy_at(kind: String, pos: Vector2) -> Enemy:
	var e := Enemy.new()
	e.setup(kind, pos, self, GameData.hp_scale(day))
	entities.add_child(e)
	enemies.append(e)
	burst(pos, Color("#9a8fe0"), 6)
	return e


func boss_shoot(b: Enemy) -> void:
	if player == null or player.dead or not is_instance_valid(b):
		return
	var aim := (player.position - b.position).normalized()
	aim = aim.rotated(rng.randf_range(-0.08, 0.08))
	var shot := SeedShot.new()
	shot.setup(b.position + Vector2(0, -10), aim, self)
	entities.add_child(shot)
	shot.add_to_group("seed_shots")
	Audio.sfx("seed", 0.9, -5.0)


func boss_summon(b: Enemy) -> void:
	if state != State.NIGHT:
		return
	hud.banner("南瓜王召唤了潮泥怪", Color("#9a8fe0"), 1.2)
	Audio.sfx("horn", 1.25, -7.0)
	for i in range(2):
		_spawn_enemy_at("slime", b.position + Vector2(rng.randf_range(-26, 26), rng.randf_range(-6, 18)))
	burst(b.position, Color("#9a8fe0"), 12)


func _edge_position() -> Vector2:
	for attempt in range(8):
		var pos := Vector2.ZERO
		match rng.randi_range(0, 3):
			0:
				pos = Vector2(rng.randf_range(-10, 250), -8)
			1:
				pos = Vector2(rng.randf_range(-10, 250), 136)
			2:
				pos = Vector2(-8, rng.randf_range(-8, 136))
			_:
				pos = Vector2(248, rng.randf_range(-8, 136))
		if player == null:
			return pos
		if pos.distance_to(player.position) > 46.0:
			return pos
	return Vector2(-8, 64)


func _flee_enemies() -> void:
	var keep: Array[Enemy] = []
	for e in enemies.duplicate():
		if not is_instance_valid(e):
			continue
		if e == boss:
			keep.append(e)
			continue
		burst(e.global_position, Color("#9a8fe0"), 6)
		e.queue_free()
	enemies = keep


func _end_night() -> void:
	if state != State.NIGHT:
		return
	_clear_shots()
	_flee_enemies()
	boss = null
	boss_ending = false
	hud.hide_boss()
	state = State.DAWN
	Audio.sfx("dawn")
	sea.set_night(false)
	_tween_ambient(Color(1, 1, 1))
	if day >= GameData.WIN_DAY and not endless:
		_finish_run(true)
		return
	var earned := day_gold
	var killed := day_kills
	day += 1
	rainy = false
	rain_particles.emitting = false
	Audio.stop_ambience()
	day_setup()
	state = State.DAWN
	var choices: Array = _roll_relics()
	var offers: Array = _roll_shop()
	hud.visible = false
	if mobile:
		mobile.set_active(false)
	dawn_screen.show_dawn(day - 1, choices, earned, killed, day, offers, gold)


func _roll_shop() -> Array:
	var pool: Array = GameData.SHOP_OFFERS.duplicate(true)
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	shop_offers = pool.slice(0, 3)
	shop_sold = [false, false, false]
	return shop_offers


func _roll_relics() -> Array:
	var pool: Array = []
	for r in GameData.RELICS:
		if not relic_ids.has(r["id"]):
			pool.append(r)
	pool.shuffle()
	var out: Array = []
	for i in range(mini(3, pool.size())):
		out.append(pool[i])
	if out.is_empty():
		out.append({
			"id": "supply", "name": "潮汐补给", "desc": "回复 3 点生命",
			"icon": "relic_tideheart", "color": "#7ee3d4",
		})
	return out


func _on_relic_chosen(id: String) -> void:
	if id == "":
		return
	if id == "supply":
		if player:
			player.heal(3)
		return
	var relic := GameData.relic_by_id(id)
	if relic.is_empty() or relic_ids.has(id):
		return
	relic_ids.append(id)
	_apply_relic(id)
	hud.set_relic_count(relic_ids.size())


func _apply_relic(id: String) -> void:
	match id:
		"boots":
			mods["move"] *= 1.2
		"whetstone":
			mods["dmg"] += 1.0
		"blubber":
			mods["maxhp"] += 2
			if player:
				player.set_max_hp(player.max_hp + 2, 2)
				_hearts_dirty = true
		"metronome":
			mods["aspd"] *= 1.25
		"rainbell":
			mods["growth"] *= 1.3
		"goldseed":
			mods["gold"] *= 1.25
		"fang":
			mods["lifesteal"] += 0.15
		"thorns":
			mods["thorns"] += 1
		"clover":
			mods["luck"] += 0.15
		"tideheart":
			mods["dawn_heal"] += 1
		"longhandle":
			mods["range"] *= 1.3
		"nightglass":
			mods["night_move"] *= 1.2
		"slowcharm":
			mods["slow"] *= 0.88
		"greenthumb":
			mods["water_boost"] += 0.15
	_update_hud(true)


func _on_dawn_continue() -> void:
	if state != State.DAWN:
		return
	dawn_screen.visible = false
	hud.visible = true
	if mobile:
		mobile.set_active(true)
	if float(mods["dawn_heal"]) > 0 and player:
		player.heal(int(mods["dawn_heal"]))
	state = State.DAY
	_roll_weather()
	day_setup()
	Audio.play_music("day")
	_update_hud(true)


func _finish_run(victory: bool) -> void:
	if state == State.GAMEOVER or state == State.VICTORY:
		return
	state = State.VICTORY if victory else State.GAMEOVER
	run_active = false
	touch_attack_held = false
	if mobile:
		mobile.set_active(false)
	fireflies.emitting = false
	Audio.stop_music()
	Audio.stop_ambience()
	Audio.sfx("victory" if victory else "gameover", 1.0, -2.0)
	var is_best := day > SaveGame.best_day
	if not _run_recorded:
		if not test_mode:
			SaveGame.record_run(day, kills, run_gold)
		_run_recorded = true
	else:
		if not test_mode:
			SaveGame.update_best(day, kills)
	hud.visible = false
	await get_tree().create_timer(0.7).timeout
	if state != State.GAMEOVER and state != State.VICTORY:
		return
	end_screen.show_result("victory" if victory else "gameover", day, kills, run_gold, is_best,
		victory and not endless)


func _on_endless_requested() -> void:
	if state != State.VICTORY or endless:
		return
	end_screen.visible = false
	endless = true
	day = GameData.WIN_DAY + 1
	run_active = true
	hud.visible = true
	if mobile:
		mobile.set_active(true)
	state = State.DAY
	_roll_weather()
	day_setup()
	Audio.play_music("day")
	_seeds_dirty = true
	_hearts_dirty = true
	_update_hud(true)
	hud.banner("无尽模式 · 第 %d 天" % day, Color("#f2c94c"), 1.6)


func _on_shop_buy(index: int) -> void:
	if state != State.DAWN or index < 0 or index >= shop_offers.size():
		return
	if index < shop_sold.size() and shop_sold[index]:
		return
	var offer: Dictionary = shop_offers[index]
	var price := int(offer["price"])
	if gold < price:
		Audio.sfx("click", 0.7)
		dawn_screen.notify("金币不够，去卖掉几颗作物吧。")
		return
	gold -= price
	if index < shop_sold.size():
		shop_sold[index] = true
	match String(offer["id"]):
		"seed_radish":
			seeds["radish"] = int(seeds["radish"]) + 3
		"seed_pumpkin":
			seeds["pumpkin"] = int(seeds["pumpkin"]) + 2
		"seed_star":
			seeds["star"] = int(seeds["star"]) + 1
		"seed_moon":
			seeds["moonwheat"] = int(seeds["moonwheat"]) + 1
		"heal":
			if player:
				player.heal(2)
		"maxhp":
			if player:
				player.set_max_hp(player.max_hp + 1, 1)
				_hearts_dirty = true
	Audio.sfx("buy")
	hud.set_gold(gold)
	_seeds_dirty = true
	dawn_screen.refresh_shop(gold, shop_sold)


func _tween_ambient(target: Color) -> void:
	if _ambient_tween != null and _ambient_tween.is_valid():
		_ambient_tween.kill()
	_ambient_tween = create_tween()
	_ambient_tween.tween_property(ambient, "color", target, 1.2)


# ------------------------------------------------------------------ input
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		if state == State.DAY or state == State.NIGHT or state == State.PAUSED:
			_toggle_pause()
		return
	if state == State.DAWN:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if dawn_screen.ready_to_continue():
				dawn_screen.continue_pressed.emit()
		return
	if event.keycode == KEY_M:
		_toggle_music()
		return
	if not can_control():
		return
	match event.keycode:
		KEY_E:
			interact()
		KEY_1:
			_select_seed(0)
		KEY_2:
			_select_seed(1)
		KEY_3:
			_select_seed(2)
		KEY_4:
			_select_seed(3)
		KEY_F:
			toggle_fullscreen()


func _select_seed(i: int) -> void:
	if selected_seed == i:
		return
	selected_seed = i
	Audio.sfx("click")
	_seeds_dirty = true
	_update_hud(true)


func toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _toggle_music() -> void:
	SaveGame.music_on = not SaveGame.music_on
	Audio.set_music_on(SaveGame.music_on)
	Audio.sfx("click")
	SaveGame.save_data()
	if hud.visible:
		hud.banner("音乐：%s" % ("开" if SaveGame.music_on else "关"), Color("#8fd3d6"), 0.6)
	_sync_pause_toggles()


func _toggle_sfx() -> void:
	SaveGame.sfx_on = not SaveGame.sfx_on
	Audio.set_sfx_on(SaveGame.sfx_on)
	if SaveGame.sfx_on:
		Audio.sfx("click")
	SaveGame.save_data()
	_sync_pause_toggles()


func _toggle_fullscreen_from_pause() -> void:
	toggle_fullscreen()
	_sync_pause_toggles()


func _sync_pause_toggles() -> void:
	if pause_screen.visible:
		pause_screen.set_toggles(SaveGame.music_on, SaveGame.sfx_on,
			DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)


func _toggle_pause() -> void:
	if state == State.PAUSED:
		state = prev_state
		pause_screen.visible = false
		if mobile:
			mobile.set_active(true)
	elif state == State.DAY or state == State.NIGHT:
		prev_state = state
		state = State.PAUSED
		touch_attack_held = false
		if mobile:
			mobile.set_active(false)
		var chosen: Array = []
		for id in relic_ids:
			chosen.append(GameData.relic_by_id(id))
		pause_screen.show_pause(chosen, SaveGame.music_on, SaveGame.sfx_on, is_mobile)
		Audio.sfx("click")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if state == State.DAY or state == State.NIGHT or state == State.PAUSED:
			_toggle_pause()
		elif state == State.TITLE:
			get_tree().quit()


# ------------------------------------------------------------------ farming
func target_tile() -> Vector2i:
	if player == null:
		return Vector2i(-1, -1)
	var probe: Vector2 = player.position + player.facing * 14.0
	var t := farm.world_to_tile(probe)
	if not farm.in_bounds(t):
		t = farm.world_to_tile(player.position)
	return t


func crop_at(t: Vector2i) -> Crop:
	for c in crops:
		if is_instance_valid(c) and not c.is_queued_for_deletion() and c.cell == t:
			return c
	return null


func current_action() -> Dictionary:
	if player == null or not farm.in_bounds(target_tile()):
		return {"type": "none", "label": "E · 走到田里开始干活", "color": Color(0.7, 0.8, 0.9, 0.7)}
	var t := target_tile()
	var c := crop_at(t)
	if c != null:
		if c.mature:
			return {"type": "harvest", "crop": c, "label": "E · 收获%s" % GameData.CROPS[c.kind]["name"], "color": Color("#f2c94c")}
		if not c.watered:
			return {"type": "water", "crop": c, "label": "E · 给%s浇水" % GameData.CROPS[c.kind]["name"], "color": Color("#7ee3d4")}
		if c.night_only and state != State.NIGHT:
			return {"type": "wait", "crop": c, "label": "%s 在等夜晚…" % GameData.CROPS[c.kind]["name"], "color": Color("#9a8fe0")}
		return {"type": "wait", "crop": c, "label": "%s 正在生长…" % GameData.CROPS[c.kind]["name"], "color": Color(0.7, 0.8, 0.9, 0.75)}
	if farm.is_tilled(t):
		var id: String = GameData.CROP_ORDER[selected_seed]
		if int(seeds[id]) <= 0:
			return {"type": "no_seed", "label": "%s种子用完了" % GameData.CROPS[id]["name"], "color": Color("#e2556b")}
		return {"type": "plant", "label": "E · 种下%s（剩 %d）" % [GameData.CROPS[id]["name"], int(seeds[id])], "color": Color("#8fe0b0")}
	return {"type": "till", "label": "E · 松土", "color": Color("#d8b48a")}


func interact() -> void:
	if not can_control() or player == null:
		return
	var act := current_action()
	var t := target_tile()
	match act.get("type", "none"):
		"till":
			farm.till(t)
			Audio.sfx("hoe")
			burst(farm.tile_center(t), Color("#8a5e3a"), 6)
		"plant":
			var id: String = GameData.CROP_ORDER[selected_seed]
			if int(seeds[id]) <= 0:
				return
			seeds[id] = int(seeds[id]) - 1
			_plant(id, t)
			_seeds_dirty = true
		"water":
			var c: Crop = act["crop"]
			c.water()
			if float(mods["water_boost"]) > 0.0 and not c.mature:
				c.growth = minf(c.grow_time, c.growth + c.grow_time * float(mods["water_boost"]))
			Audio.sfx("water")
			burst(c.position + Vector2(0, -2), Color("#7ec8e3"), 8)
		"harvest":
			var c2: Crop = act["crop"]
			c2.harvest()
		"wait":
			float_text("还在长大", player.position + Vector2(0, -22), Color("#9fb0c8"), 9)
		"no_seed":
			float_text("没有种子了", player.position + Vector2(0, -22), Color("#e2556b"), 9)
			Audio.sfx("click", 0.7)
	_update_hud(true)


func _plant(id: String, t: Vector2i) -> void:
	var c := Crop.new()
	c.setup(id, t, farm, self)
	crops_root.add_child(c)
	crops.append(c)
	farm.set_wet(t, false)
	if is_raining():
		c.water()
	Audio.sfx("plant")
	burst(c.position, Color("#8fe0b0"), 5)


func on_crop_harvested(c: Crop) -> void:
	crops.erase(c)
	farm.set_wet(c.cell, false)
	var value := int(round(float(c.value) * float(mods["gold"])))
	gold += value
	run_gold += value
	day_gold += value
	Audio.sfx("harvest")
	Audio.sfx("coin", 1.1, -4.0)
	float_text("+%d" % value, c.position + Vector2(0, -10), Color("#f2c94c"), 10)
	burst(c.position, Color(GameData.CROPS[c.kind]["color"]), 12)
	if rng.randf() < float(c.seed_drop) + float(mods["luck"]) * 0.5:
		seeds[c.kind] = int(seeds[c.kind]) + 1
		float_text("+1 种子", c.position + Vector2(0, -20), Color("#8fe0b0"), 8)
		_seeds_dirty = true
	_update_hud(true)


func on_crop_eaten(c: Crop) -> void:
	crops.erase(c)
	farm.set_wet(c.cell, false)
	float_text("作物被吃了！", c.position + Vector2(0, -12), Color("#e2556b"), 9)
	burst(c.position, Color("#e2556b"), 10)
	Audio.sfx("die", 1.2, -8.0)


func on_crop_matured(c: Crop) -> void:
	burst(c.position, Color("#f2c94c"), 4)


func crow_eat_crop(_crow: Enemy, c: Crop) -> void:
	if is_instance_valid(c):
		c.eaten()


# ------------------------------------------------------------------ combat
func player_attack(p: Player, dir: Vector2) -> void:
	var reach := (26.0 + 6.0) * range_mult()
	var dmg := int(round(float(mods["dmg"])))
	var hit_any := false
	for e in enemies.duplicate():
		if not is_instance_valid(e) or e.dead:
			continue
		var d: Vector2 = e.global_position - p.global_position
		if d.length() <= reach and (d.length() < 10.0 or dir.dot(d.normalized()) > 0.15):
			e.take_damage(dmg, d)
			hit_any = true
	if hit_any:
		Audio.sfx("hit")
		shake(2.0)

func on_enemy_damaged(e: Enemy, amount: int) -> void:
	float_text("%d" % amount, e.global_position + Vector2(0, -14), Color("#ffe9a8"), 10)
	burst(e.global_position, Color("#e2556b"), 4)
	if e == boss:
		hud.show_boss(String(GameData.ENEMIES["boss"]["name"]), e.hp, e.max_hp)
	shake(1.0)


func on_enemy_died(e: Enemy) -> void:
	enemies.erase(e)
	kills += 1
	day_kills += 1
	var value := int(round(float(e.gold) * float(mods["gold"])))
	gold += value
	run_gold += value
	day_gold += value
	float_text("+%d" % value, e.global_position + Vector2(0, -10), Color("#f2c94c"), 9)
	burst(e.global_position, Color("#9a8fe0"), 12)
	Audio.sfx("die")
	if e == boss:
		boss = null
		boss_ending = true
		hud.hide_boss()
		hud.banner("南瓜王倒下了", Color("#f2c94c"), 1.4)
		Audio.sfx("explosion")
		shake(12.0)
		burst(e.global_position, Color("#f2c94c"), 26)
		_clear_shots()
		night_queue.clear()
		get_tree().create_timer(1.6).timeout.connect(_on_boss_death_delay)
	if float(mods["lifesteal"]) > 0.0 and rng.randf() < float(mods["lifesteal"]) and player:
		player.heal(1)
		float_text("+1", player.position + Vector2(0, -22), Color("#8fe0b0"), 9)
	if rng.randf() < 0.16 + float(mods["luck"]):
		var pick: String = GameData.CROP_ORDER[rng.randi_range(0, GameData.CROP_ORDER.size() - 1)]
		seeds[pick] = int(seeds[pick]) + 1
		_seeds_dirty = true
	if rng.randf() < 0.07 and player:
		player.heal(1)
	_update_hud(true)


func _on_boss_death_delay() -> void:
	if state == State.NIGHT:
		_end_night()


func on_player_hurt(amount: int, source: Node) -> void:
	shake(5.0)
	hud.flash_damage()
	Audio.sfx("hurt")
	hud.refresh_hearts(player.hp, player.max_hp)
	if source != null and is_instance_valid(source) and source is Enemy and int(mods["thorns"]) > 0:
		(source as Enemy).take_damage(int(mods["thorns"]), source.global_position - player.global_position)


func _on_player_signal_died() -> void:
	_finish_run(false)


# ------------------------------------------------------------------ helpers
func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _tick_shake(delta: float) -> void:
	if _shake > 0.05:
		camera.offset = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * _shake
		_shake = move_toward(_shake, 0.0, delta * 28.0)
	else:
		camera.offset = Vector2.ZERO


func burst(pos: Vector2, color: Color, count: int = 8) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = count
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = 0.45
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = 16.0
	p.initial_velocity_max = 46.0
	p.gravity = Vector2(0, 60)
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.8
	p.color = color
	p.texture = preload("res://assets/generated/fx/spark.png")
	fx.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func float_text(text: String, pos: Vector2, color: Color, size: int = 9) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UiKit.font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.1, 0.9))
	l.position = pos - Vector2(12, 8)
	l.z_index = 4000
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 14.0, 0.75)
	tw.tween_property(l, "modulate:a", 0.0, 0.75).set_delay(0.15)
	tw.chain().tween_callback(l.queue_free)


func _update_hud(force: bool) -> void:
	if hud == null or not hud.visible:
		return
	if player:
		if _hearts_dirty or force:
			hud.refresh_hearts(player.hp, player.max_hp)
			_hearts_dirty = false
	if _seeds_dirty or force:
		var counts: Array = []
		for id in GameData.CROP_ORDER:
			counts.append(int(seeds.get(id, 0)))
		hud.refresh_seeds(counts, selected_seed)
		_seeds_dirty = false
	hud.set_gold(gold)
	hud.set_relic_count(relic_ids.size())
	if state == State.DAY or state == State.NIGHT or state == State.PAUSED:
		var night := state == State.NIGHT
		var phase_text := "夜晚" if night else "白天"
		if not night and rainy:
			phase_text = "白天 · 雨"
		if endless:
			phase_text += " · 无尽"
		hud.set_day(day, phase_text, Color("#9a8fe0") if night else Color("#8fe0b0"))
		hud.set_timer(phase_time, phase_total, night)
		if night:
			hud.set_wave("怪物 %d 只" % (enemies.size() + night_queue.size()))
		else:
			hud.set_wave("作物 %d 株" % crops.size())
		var act := current_action()
		hud.set_prompt(String(act.get("label", "")), act.get("color", UiKit.GOLD))


# ------------------------------------------------------------------ dev hooks
func setup_shot(name: String) -> void:
	match name:
		"title":
			show_title()
		"day":
			start_new_run(20261029)
			day = 3
			gold = 37
			player.position = farm.tile_center(Vector2i(5, 4))
			player.facing = Vector2.RIGHT
			plants_at(Vector2i(6, 4), "pumpkin", 0.7)
			plants_at(Vector2i(7, 4), "radish", 1.0)
			plants_at(Vector2i(8, 4), "star", 0.5)
			plants_at(Vector2i(9, 4), "moonwheat", 0.65)
			plants_at(Vector2i(6, 5), "radish", 0.35)
			phase_time = 46.0
			_update_hud(true)
		"rain":
			start_new_run(20261029)
			day = 4
			rainy = true
			gold = 67
			day_setup()
			player.position = farm.tile_center(Vector2i(5, 4))
			player.facing = Vector2.RIGHT
			plants_at(Vector2i(6, 4), "radish", 1.0)
			plants_at(Vector2i(7, 4), "moonwheat", 0.7)
			plants_at(Vector2i(8, 4), "pumpkin", 0.5)
			phase_time = 52.0
			_update_hud(true)
		"mobile":
			start_new_run(20261029)
			day = 3
			gold = 52
			_enable_mobile()
			if mobile:
				mobile.set_active(true)
				mobile._update_joystick(MobileControls.JOY_CENTER + Vector2(52, 12))
			player.position = farm.tile_center(Vector2i(5, 4))
			player.facing = Vector2.RIGHT
			plants_at(Vector2i(6, 4), "pumpkin", 0.7)
			plants_at(Vector2i(7, 4), "radish", 1.0)
			phase_time = 48.0
			_update_hud(true)
		"night":
			start_new_run(20261029)
			day = 4
			start_night()
			phase_time = 14.0
			player.position = farm.tile_center(Vector2i(7, 4))
			player.facing = Vector2.DOWN
			player.invuln = 99.0
			var spots := [Vector2(52, 32), Vector2(188, 40), Vector2(60, 120), Vector2(184, 118), Vector2(120, 120)]
			for i in range(5):
				var e := _spawn_enemy(["slime", "crow", "vine", "slime", "frog"][i])
				e.position = spots[i]
			_update_hud(true)
		"dawn":
			start_new_run(20261029)
			day = 2
			state = State.DAWN
			hud.visible = false
			var choices: Array = []
			for id in ["boots", "rainbell", "goldseed"]:
				choices.append(GameData.relic_by_id(id))
			var offers: Array = _roll_shop()
			gold = 48
			dawn_screen.show_dawn(2, choices, 48, 9, 3, offers, gold)
		"shop":
			start_new_run(20261029)
			day = 2
			state = State.DAWN
			hud.visible = false
			var choices2: Array = []
			for id in ["boots", "rainbell", "goldseed"]:
				choices2.append(GameData.relic_by_id(id))
			var offers2: Array = _roll_shop()
			gold = 48
			dawn_screen.show_dawn(2, choices2, 48, 9, 3, offers2, gold)
			dawn_screen._on_card(choices2[0])
		"boss":
			start_new_run(20261029)
			day = 7
			state = State.NIGHT
			phase_total = 34.0
			phase_time = 18.0
			night_queue.clear()
			player.position = farm.tile_center(Vector2i(7, 6))
			player.facing = Vector2.UP
			player.invuln = 99.0
			_spawn_boss()
			if boss != null:
				boss.position = Vector2(120, 34)
			_spawn_enemy_at("slime", Vector2(56, 84))
			_spawn_enemy_at("crow", Vector2(184, 88))
			_update_hud(true)
		"gameover":
			start_new_run(20261029)
			hud.visible = false
			end_screen.show_result("gameover", 4, 17, 83, false)
		"victory":
			start_new_run(20261029)
			hud.visible = false
			end_screen.show_result("victory", 7, 42, 210, true, true)
		"endless":
			start_new_run(20261029)
			endless = true
			day = 9
			gold = 96
			day_setup()
			player.position = farm.tile_center(Vector2i(6, 4))
			player.facing = Vector2.RIGHT
			plants_at(Vector2i(7, 4), "star", 1.0)
			plants_at(Vector2i(8, 4), "pumpkin", 0.6)
			plants_at(Vector2i(7, 5), "radish", 0.8)
			_update_hud(true)
		"pause":
			start_new_run(20261029)
			day = 3
			state = State.PAUSED
			var chosen: Array = []
			for id in ["boots", "rainbell"]:
				relic_ids.append(id)
				chosen.append(GameData.relic_by_id(id))
			pause_screen.show_pause(chosen)


func plants_at(t: Vector2i, kind: String, ratio: float) -> void:
	farm.till(t)
	var c := Crop.new()
	c.setup(kind, t, farm, self)
	c.watered = true
	c.growth = c.grow_time * ratio
	c.stage = clampi(int(c.growth / c.grow_time * 3.0), 0, 3)
	c.mature = ratio >= 1.0
	crops_root.add_child(c)
	crops.append(c)


func run_selftest() -> int:
	_test_failures = 0
	_test_checks = 0
	test_mode = true

	start_new_run(4242)
	_check(state == State.DAY, "run starts in DAY state")
	_check(farm.tiles.size() == GameData.FARM_W * GameData.FARM_H, "farm grid size")
	_check(player != null, "player spawned")
	_check(gold == 18, "starting gold is 18")

	# farming chain: till -> plant -> water -> grow -> harvest
	player.position = farm.tile_center(Vector2i(2, 3))
	player.facing = Vector2.RIGHT
	var t := Vector2i(3, 3)
	interact()
	_check(farm.is_tilled(t), "E tills grass")
	seeds["radish"] = 5
	selected_seed = 0
	interact()
	_check(crops.size() == 1, "E plants a seed")
	_check(int(seeds["radish"]) == 4, "seed count decremented")
	var crop: Crop = crops[0]
	interact()
	_check(crop.watered, "E waters the crop")
	crop.growth = crop.grow_time
	crop._process(0.02)
	_check(crop.mature, "crop matures")
	var gold_before := gold
	var count_before := crops.size()
	interact()
	_check(crops.size() == count_before - 1, "harvest removes crop")
	_check(gold > gold_before, "harvest pays gold")

	# moonwheat only grows at night
	seeds["moonwheat"] = 2
	selected_seed = 3
	interact()
	_check(crops.size() == 1 and crops[0].kind == "moonwheat", "fourth seed slot plants moonwheat")
	var moon: Crop = crops[0]
	interact()
	_check(moon.watered, "moonwheat can be watered in the day")
	state = State.DAY
	moon._process(1.0)
	_check(moon.growth == 0.0, "moonwheat waits during the day")
	state = State.NIGHT
	moon._process(1.0)
	_check(moon.growth > 0.0, "moonwheat grows at night")
	state = State.DAY

	# rain auto-waters newly planted crops
	rainy = true
	farm.till(Vector2i(6, 3))
	_plant("radish", Vector2i(6, 3))
	var rain_crop: Crop = crops[crops.size() - 1]
	_check(rain_crop.watered, "rain waters newly planted crops")
	rainy = false

	# frog enemy
	var frog := _spawn_enemy_at("frog", Vector2(52, 52))
	_check(frog.kind == "frog", "frog enemy spawns")
	frog.take_damage(999, Vector2.RIGHT)
	_check(enemies.is_empty(), "frog can be killed")

	# night + enemy death + dawn
	start_night()
	_check(state == State.NIGHT, "night begins")
	var e := _spawn_enemy("slime")
	_check(enemies.size() >= 1, "enemy spawns")
	var kills_before := kills
	e.take_damage(99, Vector2.RIGHT)
	_check(enemies.is_empty(), "enemy dies")
	_check(kills == kills_before + 1, "kill counter increments")
	night_queue.clear()
	phase_time = 1.0
	_process(1.1)
	_check(state == State.DAWN, "night ends into dawn")
	_check(day == 2, "day advances")
	_check(dawn_screen.visible, "dawn screen visible")

	# relic selection + shop + continue
	_on_relic_chosen("boots")
	_check(relic_ids.has("boots"), "relic applied")
	_check(is_equal_approx(float(mods["move"]), 1.2), "boots mod applied")
	_on_relic_chosen("slowcharm")
	_check(is_equal_approx(float(mods["slow"]), 0.88), "slowcharm nerfs night monsters")
	_on_relic_chosen("greenthumb")
	_check(is_equal_approx(float(mods["water_boost"]), 0.15), "greenthumb adds watering boost")
	Audio.set_music_on(false)
	_check(is_equal_approx(Audio.music_level, 0.0), "music can be muted")
	Audio.set_music_on(true)
	_check(is_equal_approx(Audio.music_level, 1.0), "music can be unmuted")
	_check(shop_offers.size() == 3, "dawn offers three shop items")
	var gold_keep := gold
	gold = 100
	shop_sold = [false, false, false]
	_on_shop_buy(0)
	_check(gold < 100, "shop purchase costs gold")
	_check(bool(shop_sold[0]), "shop item marked sold")
	var gold_after := gold
	_on_shop_buy(0)
	_check(gold == gold_after, "sold item cannot be bought twice")
	gold = gold_keep
	_on_dawn_continue()
	_check(state == State.DAY, "dawn continue returns to day")
	_check(day == 2, "second day active")

	# boss finale
	day = 7
	state = State.NIGHT
	phase_total = 34.0
	phase_time = 20.0
	night_queue.clear()
	_spawn_boss()
	_check(boss != null, "boss spawns")
	_check(hud.boss_panel.visible, "boss hp bar visible")
	if boss != null:
		player.position = boss.position + Vector2(0, 20)
		var boss_hp := boss.hp
		player_attack(player, Vector2.UP)
		_check(boss.hp < boss_hp, "scythe damages boss")
		boss.take_damage(999, Vector2.RIGHT)
	_check(boss == null, "boss dies")
	await get_tree().create_timer(3.0).timeout
	_check(state == State.VICTORY, "boss death wins the run")

	# endless mode
	_check(_is_boss_night(7) and _is_boss_night(10) and not _is_boss_night(8),
		"boss night every third day after victory")
	_on_endless_requested()
	_check(endless, "endless mode enabled")
	_check(state == State.DAY and day == 8, "endless starts at day 8")
	_check(_run_recorded, "run recorded once")

	# mobile controls (touch simulation)
	_enable_mobile()
	mobile.set_active(true)
	_check(mobile.visible, "mobile controls can be enabled")
	player.position = farm.tile_center(Vector2i(7, 4))
	var px := player.position.x
	mobile._update_joystick(MobileControls.JOY_CENTER + Vector2(62, 0))
	for i in range(6):
		await get_tree().physics_frame
	_check(player.position.x > px + 1.0, "virtual joystick moves the player")
	mobile._release_joystick()
	player.attack_cd = 0.0
	mobile.attack_tap.emit()
	_check(player.attack_cd > 0.0, "touch attack swings the scythe")

	# save/load roundtrip in memory
	var old_best := SaveGame.best_day
	SaveGame.best_day = 9
	SaveGame.save_data()
	SaveGame.best_day = 0
	SaveGame.load_data()
	_check(SaveGame.best_day == 9, "save/load roundtrip")
	SaveGame.best_day = old_best
	SaveGame.save_data()

	test_mode = false
	print("SELFTEST ", "OK" if _test_failures == 0 else "FAILED", " ", _test_checks - _test_failures, "/", _test_checks)
	return 0 if _test_failures == 0 else 1


var _test_failures := 0
var _test_checks := 0


func _check(ok: bool, msg: String) -> void:
	_test_checks += 1
	if ok:
		print("PASS  ", msg)
	else:
		_test_failures += 1
		print("FAIL  ", msg)


func run_smoke() -> int:
	## Real-time smoke test: farm, fight, survive a night, reach dawn.
	start_new_run(777)
	await get_tree().create_timer(0.3).timeout
	player.position = farm.tile_center(Vector2i(2, 3))
	player.facing = Vector2.RIGHT
	interact()
	await get_tree().create_timer(0.1).timeout
	seeds["radish"] = 3
	selected_seed = 0
	interact()
	await get_tree().create_timer(0.1).timeout
	interact()
	await get_tree().create_timer(0.1).timeout
	if not crops.is_empty():
		crops[0].growth = crops[0].grow_time
		crops[0]._process(0.02)
		await get_tree().create_timer(0.1).timeout
		interact()
	start_night()
	await get_tree().create_timer(2.0).timeout
	var attacks := 0
	for i in range(50):
		if state != State.NIGHT or player == null or player.dead:
			break
		if not enemies.is_empty() and is_instance_valid(enemies[0]):
			var target: Enemy = enemies[0]
			player.position = target.position + Vector2(0, 18)
			player_attack(player, (target.global_position - player.global_position).normalized())
			attacks += 1
		if player.hp <= 2:
			player.heal(1)
		await get_tree().create_timer(0.12).timeout
	var kills_before_cleanup := kills
	print("SMOKE  attacks=%d kills=%d hp=%d/%d enemies=%d state=%d gold=%d"
		% [attacks, kills, player.hp if player else -1, player.max_hp if player else -1,
		   enemies.size(), state, gold])
	# clean up the rest of the wave and force dawn
	for e in enemies.duplicate():
		if is_instance_valid(e):
			e.take_damage(999, Vector2.RIGHT)
	night_queue.clear()
	phase_time = 0.5
	await get_tree().create_timer(0.7).timeout
	print("SMOKE  after_night state=%d day=%d dawn_visible=%s" % [state, day, dawn_screen.visible])
	var ok := state == State.DAWN and dawn_screen.visible and attacks > 0 and kills_before_cleanup > 0
	print("SMOKE ", "OK" if ok else "FAILED")
	return 0 if ok else 1

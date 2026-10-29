class_name CodexScreen
extends Control
## Farm codex: discovered crops, monsters and tide blessings.

signal closed


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	visible = false


func show_codex() -> void:
	for c in get_children():
		c.queue_free()
	visible = true
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.07, 0.86)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var panel := UiKit.panel_container(18)
	panel.position = Vector2(90, 30)
	panel.size = Vector2(1100, 660)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var title := UiKit.label("农场图鉴", 42, Color("#f6e7b4"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var summary := UiKit.label(
		"已发现：作物 %d/%d · 怪物 %d/%d · 祝福 %d/%d" % [
			SaveGame.discovered_crops.size(), GameData.CROPS.size(),
			SaveGame.discovered_enemies.size(), GameData.ENEMIES.size(),
			SaveGame.discovered_relics.size(), GameData.RELICS.size(),
		], 20, Color("#9fb0c8"))
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(summary)
	v.add_child(HSeparator.new())

	v.add_child(UiKit.label("作物", 22, UiKit.GOLD))
	var crops_row := HBoxContainer.new()
	crops_row.add_theme_constant_override("separation", 8)
	crops_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(crops_row)
	for id in GameData.CROP_ORDER:
		crops_row.add_child(_crop_card(id))

	v.add_child(UiKit.label("怪物", 22, UiKit.GOLD))
	var enemies_row := HBoxContainer.new()
	enemies_row.add_theme_constant_override("separation", 8)
	enemies_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(enemies_row)
	for id in GameData.ENEMIES:
		enemies_row.add_child(_enemy_card(String(id)))

	v.add_child(UiKit.label("潮汐祝福", 22, UiKit.GOLD))
	var relics_grid := GridContainer.new()
	relics_grid.columns = 6
	relics_grid.add_theme_constant_override("h_separation", 8)
	relics_grid.add_theme_constant_override("v_separation", 4)
	v.add_child(relics_grid)
	for relic in GameData.RELICS:
		relics_grid.add_child(_relic_cell(relic))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	v.add_child(buttons)
	var stats_btn := UiKit.button("统计", 24)
	stats_btn.custom_minimum_size = Vector2(180, 52)
	stats_btn.pressed.connect(func() -> void:
		Audio.sfx("click")
		_show_stats())
	buttons.add_child(stats_btn)
	var close := UiKit.button("返回", 26)
	close.custom_minimum_size = Vector2(200, 52)
	close.pressed.connect(func() -> void:
		Audio.sfx("click")
		closed.emit())
	buttons.add_child(close)


func _show_stats() -> void:
	for c in get_children():
		c.queue_free()
	visible = true
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.07, 0.86)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var panel := UiKit.panel_container(20)
	panel.position = Vector2(260, 70)
	panel.size = Vector2(760, 580)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var title := UiKit.label("农场档案", 42, Color("#f6e7b4"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	v.add_child(HSeparator.new())
	var rows := [
		["游玩局数", str(SaveGame.runs)],
		["最佳存活", "第 %d 天" % SaveGame.best_day],
		["最高击杀", str(SaveGame.best_kills)],
		["累计金币", str(SaveGame.total_gold)],
		["累计收获", str(SaveGame.crops_harvested)],
		["累计击杀", str(SaveGame.enemies_killed)],
		["金色作物", str(SaveGame.golden_harvested)],
		["成就", "%d / %d" % [SaveGame.achievements.size(), GameData.ACHIEVEMENTS.size()]],
		["图鉴", "作物 %d/%d · 怪物 %d/%d · 祝福 %d/%d" % [
			SaveGame.discovered_crops.size(), GameData.CROPS.size(),
			SaveGame.discovered_enemies.size(), GameData.ENEMIES.size(),
			SaveGame.discovered_relics.size(), GameData.RELICS.size()]],
	]
	for row in rows:
		var h := HBoxContainer.new()
		v.add_child(h)
		var k := UiKit.label(String(row[0]), 22, Color("#9fb0c8"))
		k.custom_minimum_size = Vector2(200, 0)
		h.add_child(k)
		var val := UiKit.label(String(row[1]), 22, Color("#f6e7b4"))
		val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(val)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	v.add_child(buttons)
	var back := UiKit.button("返回图鉴", 22)
	back.custom_minimum_size = Vector2(180, 52)
	back.pressed.connect(func() -> void:
		Audio.sfx("click")
		show_codex())
	buttons.add_child(back)
	var home := UiKit.button("返回标题", 24)
	home.custom_minimum_size = Vector2(180, 52)
	home.pressed.connect(func() -> void:
		Audio.sfx("click")
		closed.emit())
	buttons.add_child(home)


func _crop_card(id: String) -> Control:
	var known := SaveGame.discovered_crops.has(id)
	var p := UiKit.panel_container(6)
	p.custom_minimum_size = Vector2(196, 128)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	p.add_child(v)
	var ic := UiKit.icon("res://assets/generated/crops/%s_3.png" % id, 44)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if not known:
		ic.modulate = Color(0.18, 0.2, 0.28, 1)
	v.add_child(ic)
	var nm := UiKit.label(GameData.CROPS[id]["name"] if known else "？？？", 18,
		Color("#e8eef8") if known else Color("#5c6a80"))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	var info := UiKit.label(
		"%d金 · %ds" % [GameData.CROPS[id]["value"], GameData.CROPS[id]["grow"]] if known else "未发现",
		14, Color("#9fb0c8"))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(info)
	return p


func _enemy_card(id: String) -> Control:
	var known := SaveGame.discovered_enemies.has(id)
	var info: Dictionary = GameData.ENEMIES[id]
	var p := UiKit.panel_container(6)
	p.custom_minimum_size = Vector2(168, 86)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	p.add_child(h)
	var ic := _sheet_icon(String(info["texture"]), 32 if id == "boss" else 16, 32 if id == "boss" else 16)
	if not known:
		ic.modulate = Color(0.18, 0.2, 0.28, 1)
	h.add_child(ic)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	h.add_child(v)
	v.add_child(UiKit.label(("BOSS " if id == "boss" else "") + (String(info["name"]) if known else "？？？"),
		16, Color("#e8eef8") if known else Color("#5c6a80")))
	v.add_child(UiKit.label("生命 %d · %d金" % [info["hp"], info["gold"]] if known else "未发现",
		13, Color("#9fb0c8")))
	return p


func _relic_cell(relic: Dictionary) -> Control:
	var known := SaveGame.discovered_relics.has(String(relic["id"]))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	h.custom_minimum_size = Vector2(168, 34)
	var ic := UiKit.icon("res://assets/generated/ui/%s.png" % relic["icon"], 26)
	if not known:
		ic.modulate = Color(0.18, 0.2, 0.28, 1)
	h.add_child(ic)
	var nm := UiKit.label(String(relic["name"]) if known else "？？？", 15,
		Color(relic["color"]) if known else Color("#5c6a80"))
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(nm)
	return h


func _sheet_icon(path: String, w: int, h: int) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(path)
	atlas.region = Rect2(0, 0, w, h)
	var tr := TextureRect.new()
	tr.texture = atlas
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(34, 34)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return tr

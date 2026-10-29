class_name Hud
extends Control
## In-game HUD: day, timer, gold, hearts, seed belt and context prompt.

signal seed_selected(index: int)

const HEART_FULL := preload("res://assets/generated/ui/heart_full.png")
const HEART_EMPTY := preload("res://assets/generated/ui/heart_empty.png")
const COIN := preload("res://assets/generated/ui/coin.png")
const SUN := preload("res://assets/generated/ui/sun.png")
const MOON := preload("res://assets/generated/ui/moon.png")

var day_label: Label
var phase_label: Label
var relic_label: Label
var time_label: Label
var time_icon: TextureRect
var gold_label: Label
var wave_label: Label
var prompt_label: Label
var hearts: HBoxContainer
var seed_panels: Array[Button] = []
var seed_counts: Array[Label] = []
var _seed_keys: Array[Label] = []
var _hint: Label
var progress: ProgressBar
var damage_flash: ColorRect
var banner_label: Label
var boss_panel: PanelContainer
var boss_name: Label
var boss_bar: ProgressBar
var boss_fill: StyleBoxFlat
var _progress_fill: StyleBoxFlat
var _banner_tween: Tween
var _low_rects: Array[ColorRect] = []
var _low_active := false
var _pulse_t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiKit.theme()
	_build()


func _build() -> void:
	# day / phase
	var day_panel := UiKit.panel_container(12)
	day_panel.position = Vector2(16, 16)
	day_panel.size = Vector2(250, 104)
	add_child(day_panel)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 0)
	day_panel.add_child(dv)
	day_label = UiKit.label("第 1 天", 34, Color("#f6e7b4"))
	dv.add_child(day_label)
	phase_label = UiKit.label("白天", 22, Color("#8fe0b0"))
	dv.add_child(phase_label)
	relic_label = UiKit.label("祝福 × 0", 18, Color("#9fb0c8"))
	dv.add_child(relic_label)

	# timer
	var timer_panel := UiKit.panel_container(10)
	timer_panel.position = Vector2(470, 16)
	timer_panel.size = Vector2(340, 104)
	add_child(timer_panel)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 2)
	timer_panel.add_child(tv)
	var th := HBoxContainer.new()
	th.alignment = BoxContainer.ALIGNMENT_CENTER
	th.add_theme_constant_override("separation", 10)
	tv.add_child(th)
	time_icon = UiKit.icon("res://assets/generated/ui/sun.png", 40)
	th.add_child(time_icon)
	time_label = UiKit.label("1:30", 38, Color("#f6e7b4"))
	th.add_child(time_label)
	progress = ProgressBar.new()
	progress.custom_minimum_size = Vector2(280, 8)
	progress.show_percentage = false
	progress.max_value = 1.0
	progress.value = 1.0
	progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.09, 0.14, 0.9)
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3
	bg.corner_radius_bottom_right = 3
	_progress_fill = StyleBoxFlat.new()
	_progress_fill.bg_color = Color("#7fd8c8")
	_progress_fill.corner_radius_top_left = 3
	_progress_fill.corner_radius_top_right = 3
	_progress_fill.corner_radius_bottom_left = 3
	_progress_fill.corner_radius_bottom_right = 3
	progress.add_theme_stylebox_override("background", bg)
	progress.add_theme_stylebox_override("fill", _progress_fill)
	tv.add_child(progress)

	# gold / wave
	var gold_panel := UiKit.panel_container(10)
	gold_panel.position = Vector2(980, 16)
	gold_panel.size = Vector2(284, 104)
	add_child(gold_panel)
	var gv := VBoxContainer.new()
	gv.add_theme_constant_override("separation", 0)
	gold_panel.add_child(gv)
	var gh := HBoxContainer.new()
	gh.alignment = BoxContainer.ALIGNMENT_END
	gh.add_theme_constant_override("separation", 8)
	gv.add_child(gh)
	var coin := UiKit.icon("res://assets/generated/ui/coin.png", 36)
	gh.add_child(coin)
	gold_label = UiKit.label("0", 38, Color("#f2c94c"))
	gh.add_child(gold_label)
	wave_label = UiKit.label("作物 0 株", 18, Color("#9fb0c8"))
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gv.add_child(wave_label)

	# hearts
	var heart_panel := UiKit.panel_container(8)
	heart_panel.position = Vector2(16, 636)
	heart_panel.size = Vector2(320, 68)
	add_child(heart_panel)
	hearts = HBoxContainer.new()
	hearts.add_theme_constant_override("separation", 3)
	hearts.alignment = BoxContainer.ALIGNMENT_CENTER
	heart_panel.add_child(hearts)
	for i in range(12):
		var h := TextureRect.new()
		h.texture = HEART_FULL
		h.custom_minimum_size = Vector2(22, 22)
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hearts.add_child(h)

	# seed belt + prompt
	var seed_panel := UiKit.panel_container(8)
	seed_panel.position = Vector2(350, 608)
	seed_panel.size = Vector2(600, 100)
	add_child(seed_panel)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 2)
	seed_panel.add_child(sv)
	prompt_label = UiKit.label("E · 走到田里开始干活", 22, Color("#f6e7b4"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sv.add_child(prompt_label)
	var sh := HBoxContainer.new()
	sh.add_theme_constant_override("separation", 6)
	sh.alignment = BoxContainer.ALIGNMENT_CENTER
	sv.add_child(sh)
	for i in range(GameData.CROP_ORDER.size()):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(108, 54)
		slot.focus_mode = Control.FOCUS_NONE
		slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var base_style := UiKit.make_texture_style(UiKit.TEX_PANEL, 8, 8)
		for state in ["normal", "hover", "pressed", "focus"]:
			slot.add_theme_stylebox_override(state, base_style)
		slot.pressed.connect(_on_seed_slot_pressed.bind(i))
		sh.add_child(slot)
		var hh := HBoxContainer.new()
		hh.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hh.offset_left = 5
		hh.offset_top = 2
		hh.offset_right = -3
		hh.offset_bottom = -2
		hh.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hh.add_theme_constant_override("separation", 2)
		slot.add_child(hh)
		var key := UiKit.label(str(i + 1), 13, Color("#9fb0c8"))
		key.custom_minimum_size = Vector2(10, 0)
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_seed_keys.append(key)
		hh.add_child(key)
		var crop_id: String = GameData.CROP_ORDER[i]
		var ic := UiKit.icon("res://assets/generated/ui/seed_%s.png" % _seed_icon_id(crop_id), 28)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hh.add_child(ic)
		var vv := VBoxContainer.new()
		vv.add_theme_constant_override("separation", -5)
		vv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hh.add_child(vv)
		var name_label := UiKit.label(GameData.CROPS[crop_id]["name"], 14, Color("#c8d6e8"))
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vv.add_child(name_label)
		var cnt := UiKit.label("×0", 19, Color("#f6e7b4"))
		cnt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vv.add_child(cnt)
		seed_panels.append(slot)
		seed_counts.append(cnt)

	_hint = UiKit.label("E 互动 · 空格 挥镰 · 1-5 选种 · Esc 暂停", 14, Color(0.72, 0.8, 0.9, 0.65))
	_hint.position = Vector2(958, 668)
	_hint.size = Vector2(306, 30)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_hint)

	damage_flash = ColorRect.new()
	damage_flash.color = Color(0.8, 0.1, 0.15, 0.0)
	damage_flash.position = Vector2.ZERO
	damage_flash.size = Vector2(1280, 720)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_flash)

	# low-health red frame
	var frame_specs := [
		Rect2(0, 0, 1280, 14), Rect2(0, 706, 1280, 14),
		Rect2(0, 0, 14, 720), Rect2(1266, 0, 14, 720),
	]
	for spec in frame_specs:
		var r := ColorRect.new()
		r.color = Color(0.75, 0.08, 0.12, 0.0)
		r.position = spec.position
		r.size = spec.size
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(r)
		_low_rects.append(r)

	# boss health bar (hidden until the pumpkin king wakes up)
	boss_panel = UiKit.panel_container(8)
	boss_panel.position = Vector2(470, 126)
	boss_panel.size = Vector2(340, 62)
	boss_panel.visible = false
	add_child(boss_panel)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 2)
	boss_panel.add_child(bv)
	boss_name = UiKit.label("腐化南瓜王", 18, Color("#ffb066"))
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(boss_name)
	boss_bar = ProgressBar.new()
	boss_bar.custom_minimum_size = Vector2(290, 10)
	boss_bar.show_percentage = false
	boss_bar.max_value = 1.0
	boss_bar.value = 1.0
	boss_fill = StyleBoxFlat.new()
	boss_fill.bg_color = Color("#e8893a")
	boss_fill.corner_radius_top_left = 3
	boss_fill.corner_radius_top_right = 3
	boss_fill.corner_radius_bottom_left = 3
	boss_fill.corner_radius_bottom_right = 3
	var bbg := StyleBoxFlat.new()
	bbg.bg_color = Color(0.06, 0.05, 0.04, 0.9)
	boss_bar.add_theme_stylebox_override("background", bbg)
	boss_bar.add_theme_stylebox_override("fill", boss_fill)
	bv.add_child(boss_bar)

	# big centre banner ("夜幕降临", boss warnings ...)
	banner_label = UiKit.label("", 46, Color("#f6e7b4"))
	banner_label.position = Vector2(240, 232)
	banner_label.size = Vector2(800, 70)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.add_theme_constant_override("outline_size", 14)
	banner_label.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.08, 0.95))
	banner_label.modulate.a = 0.0
	banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner_label)


func set_day(day: int, phase_text: String, phase_color: Color) -> void:
	day_label.text = "第 %d 天" % day
	phase_label.text = phase_text
	phase_label.add_theme_color_override("font_color", phase_color)


func set_timer(seconds_left: float, total: float, is_night: bool) -> void:
	var s := maxi(0, ceili(seconds_left))
	time_label.text = "%d:%02d" % [s / 60, s % 60]
	time_icon.texture = MOON if is_night else SUN
	progress.value = clampf(seconds_left / maxf(total, 0.001), 0.0, 1.0)
	_progress_fill.bg_color = Color("#9a8fe0") if is_night else Color("#7fd8c8")
	time_label.add_theme_color_override("font_color", Color("#b8b0f0") if is_night else Color("#f6e7b4"))


func set_gold(value: int) -> void:
	gold_label.text = str(value)


func set_wave(text: String) -> void:
	wave_label.text = text


func set_relic_count(count: int) -> void:
	relic_label.text = "祝福 × %d" % count


func set_prompt(text: String, color: Color = UiKit.GOLD) -> void:
	prompt_label.text = text
	prompt_label.add_theme_color_override("font_color", color)


func refresh_hearts(hp: int, max_hp: int) -> void:
	for i in range(hearts.get_child_count()):
		var h := hearts.get_child(i) as TextureRect
		h.visible = i < max_hp
		h.texture = HEART_FULL if i < hp else HEART_EMPTY
	set_low_hp(hp > 0 and hp <= 2)


func set_low_hp(active: bool) -> void:
	_low_active = active
	if not active:
		for r in _low_rects:
			r.color.a = 0.0


func _process(delta: float) -> void:
	if not _low_active:
		return
	_pulse_t += delta
	var a := 0.10 + 0.07 * (0.5 + 0.5 * sin(_pulse_t * 3.4))
	for r in _low_rects:
		r.color.a = a


func refresh_seeds(counts: Array, selected: int) -> void:
	for i in range(seed_counts.size()):
		seed_counts[i].text = "×%d" % int(counts[i]) if i < counts.size() else "×0"
		var style := UiKit.make_texture_style(UiKit.TEX_PANEL_SEL if i == selected else UiKit.TEX_PANEL, 8, 8)
		for state in ["normal", "hover", "pressed", "focus"]:
			seed_panels[i].add_theme_stylebox_override(state, style)
		seed_panels[i].modulate = Color(1.22, 1.22, 1.08) if i == selected else Color.WHITE


func _on_seed_slot_pressed(index: int) -> void:
	Audio.sfx("click", 1.2, -10.0)
	seed_selected.emit(index)


func set_mobile(on: bool) -> void:
	if _hint:
		_hint.visible = not on
	for key in _seed_keys:
		key.visible = not on


func _seed_icon_id(crop_id: String) -> String:
	if crop_id == "moonwheat":
		return "moon"
	return crop_id


func flash_damage() -> void:
	damage_flash.color.a = 0.12 if SaveGame.reduce_flash else 0.35
	var tw := create_tween()
	tw.tween_property(damage_flash, "color:a", 0.0, 0.35)


func show_boss(name: String, hp: int, max_hp: int) -> void:
	boss_panel.visible = true
	boss_name.text = name
	boss_bar.value = clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)


func hide_boss() -> void:
	if boss_panel:
		boss_panel.visible = false


func banner(text: String, color: Color = Color("#f6e7b4"), hold: float = 1.1) -> void:
	if banner_label == null:
		return
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	banner_label.text = text
	banner_label.add_theme_color_override("font_color", color)
	banner_label.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_property(banner_label, "modulate:a", 1.0, 0.18)
	_banner_tween.tween_interval(hold)
	_banner_tween.tween_property(banner_label, "modulate:a", 0.0, 0.6)

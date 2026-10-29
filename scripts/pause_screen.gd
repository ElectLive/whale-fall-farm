class_name PauseScreen
extends Control
## Pause overlay: resume, sound/fullscreen toggles and current blessings.

signal resume_requested
signal title_requested
signal toggle_music
signal toggle_sfx
signal toggle_vibration
signal toggle_fullscreen

var _list: VBoxContainer
var _music_btn: Button
var _sfx_btn: Button
var _vib_btn: Button
var _fs_btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	visible = false


func show_pause(relics: Array, music_on: bool = true, sfx_on: bool = true, mobile: bool = false,
		vibration_on: bool = true) -> void:
	for c in get_children():
		c.queue_free()
	visible = true
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.07, 0.72)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var panel := UiKit.panel_container(24)
	panel.position = Vector2(380, 70)
	panel.size = Vector2(520, 560)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	var title := UiKit.label("暂停", 46, Color("#f6e7b4"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	v.add_child(UiKit.label("左侧摇杆移动 · 右侧镰刀攻击 · 互动键干活" if mobile else "WASD 移动 · E 互动 · 空格 挥镰 · Esc 继续", 19, Color("#9fb0c8")))
	v.add_child(HSeparator.new())
	v.add_child(UiKit.label("已获得的潮汐祝福", 21, UiKit.GOLD))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	v.add_child(_list)
	for r in relics:
		_list.add_child(UiKit.label("· %s —— %s" % [r["name"], r["desc"]], 17, Color("#c8d6e8")))
	if relics.is_empty():
		_list.add_child(UiKit.label("· 还没有祝福，黎明时可以选择。", 17, Color(0.6, 0.7, 0.8, 0.8)))
	var toggles := HBoxContainer.new()
	toggles.alignment = BoxContainer.ALIGNMENT_CENTER
	toggles.add_theme_constant_override("separation", 10)
	v.add_child(toggles)
	_music_btn = UiKit.button("音乐：开", 19)
	_music_btn.custom_minimum_size = Vector2(150, 44)
	_music_btn.pressed.connect(func() -> void: toggle_music.emit())
	toggles.add_child(_music_btn)
	_sfx_btn = UiKit.button("音效：开", 19)
	_sfx_btn.custom_minimum_size = Vector2(150, 44)
	_sfx_btn.pressed.connect(func() -> void: toggle_sfx.emit())
	toggles.add_child(_sfx_btn)
	_vib_btn = UiKit.button("震动：开", 19)
	_vib_btn.custom_minimum_size = Vector2(150, 44)
	_vib_btn.pressed.connect(func() -> void: toggle_vibration.emit())
	_vib_btn.visible = mobile
	toggles.add_child(_vib_btn)
	_fs_btn = UiKit.button("全屏：关", 19)
	_fs_btn.custom_minimum_size = Vector2(150, 44)
	_fs_btn.pressed.connect(func() -> void: toggle_fullscreen.emit())
	_fs_btn.visible = not mobile
	toggles.add_child(_fs_btn)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	v.add_child(row)
	var resume := UiKit.button("继续", 26)
	resume.custom_minimum_size = Vector2(170, 54)
	resume.pressed.connect(func() -> void:
		Audio.sfx("click")
		resume_requested.emit())
	row.add_child(resume)
	var home := UiKit.button("回到标题", 22)
	home.custom_minimum_size = Vector2(170, 54)
	home.pressed.connect(func() -> void:
		Audio.sfx("click")
		title_requested.emit())
	row.add_child(home)
	set_toggles(music_on, sfx_on, DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN, vibration_on)


func set_toggles(music_on: bool, sfx_on: bool, fullscreen: bool, vibration_on: bool = true) -> void:
	if _music_btn:
		_music_btn.text = "音乐：开" if music_on else "音乐：关"
	if _sfx_btn:
		_sfx_btn.text = "音效：开" if sfx_on else "音效：关"
	if _vib_btn:
		_vib_btn.text = "震动：开" if vibration_on else "震动：关"
	if _fs_btn:
		_fs_btn.text = "全屏：开" if fullscreen else "全屏：关"

class_name PauseScreen
extends Control
## Pause overlay: resume, control reminder and current blessings.

signal resume_requested
signal title_requested

var _list: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	visible = false


func show_pause(relics: Array) -> void:
	for c in get_children():
		c.queue_free()
	visible = true
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.07, 0.72)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var panel := UiKit.panel_container(26)
	panel.position = Vector2(390, 110)
	panel.size = Vector2(500, 500)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	var title := UiKit.label("暂停", 48, Color("#f6e7b4"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	v.add_child(UiKit.label("WASD 移动 · E 互动 · 空格 挥镰 · Esc 继续", 20, Color("#9fb0c8")))
	var sep := HSeparator.new()
	v.add_child(sep)
	v.add_child(UiKit.label("已获得的潮汐祝福", 22, UiKit.GOLD))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	v.add_child(_list)
	for r in relics:
		_list.add_child(UiKit.label("· %s —— %s" % [r["name"], r["desc"]], 18, Color("#c8d6e8")))
	if relics.is_empty():
		_list.add_child(UiKit.label("· 还没有祝福，黎明时可以选择。", 18, Color(0.6, 0.7, 0.8, 0.8)))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	v.add_child(row)
	var resume := UiKit.button("继续", 26)
	resume.custom_minimum_size = Vector2(170, 56)
	resume.pressed.connect(func() -> void:
		Audio.sfx("click")
		resume_requested.emit())
	row.add_child(resume)
	var home := UiKit.button("回到标题", 22)
	home.custom_minimum_size = Vector2(170, 56)
	home.pressed.connect(func() -> void:
		Audio.sfx("click")
		title_requested.emit())
	row.add_child(home)

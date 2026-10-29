class_name EndScreen
extends Control
## Shared victory / game-over screen.

signal restart_requested
signal title_requested
signal endless_requested

var _panel: PanelContainer
var _kind := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	visible = false


func show_result(kind: String, day: int, kills: int, gold: int, new_best: bool, can_endless: bool = false) -> void:
	_kind = kind
	for c in get_children():
		c.queue_free()
	visible = true
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.07, 0.82)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	_panel = UiKit.panel_container(30)
	_panel.position = Vector2(300, 130)
	_panel.size = Vector2(680, 460)
	add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	_panel.add_child(v)
	var victory := kind == "victory"
	var title := UiKit.label("你守住了鲸落农场" if victory else "农场沉没了", 48,
		Color("#f6e7b4") if victory else Color("#e2556b"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UiKit.label(
		"七次潮汐过去，鲸背上的灯火还亮着。" if victory else "第七天之前，你还差一点点。",
		22, Color("#9fb0c8"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var stats := UiKit.label("存活 %d 天   ·   击杀 %d 只怪物   ·   收获 %d 金币" % [day, kills, gold],
		26, Color("#dbe6f4"))
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(stats)
	if new_best:
		var best := UiKit.label("✦ 新的最佳记录 ✦", 26, UiKit.GOLD)
		best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(best)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	v.add_child(spacer)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	v.add_child(row)
	var again := UiKit.button("再来一局", 26)
	again.custom_minimum_size = Vector2(200, 60)
	again.pressed.connect(func() -> void:
		Audio.sfx("click")
		restart_requested.emit())
	row.add_child(again)
	if victory and can_endless:
		var endless := UiKit.button("继续无尽", 24)
		endless.custom_minimum_size = Vector2(180, 60)
		endless.pressed.connect(func() -> void:
			Audio.sfx("click")
			endless_requested.emit())
		row.add_child(endless)
	var home := UiKit.button("回到标题", 24)
	home.custom_minimum_size = Vector2(180, 60)
	home.pressed.connect(func() -> void:
		Audio.sfx("click")
		title_requested.emit())
	row.add_child(home)

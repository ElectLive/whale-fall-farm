class_name DawnScreen
extends Control
## Between days: choose one tide blessing. Also hosts the little seed shop later.

signal relic_chosen(id: String)
signal continue_pressed

var _panel: PanelContainer
var _title: Label
var _sub: Label
var _stats: Label
var _cards: HBoxContainer
var _continue: Button
var _chosen := ""
var _continue_day := 1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	visible = false


func _dim() -> ColorRect:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.09, 0.72)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	return dim


func show_dawn(day: int, relics: Array, gold_earned: int, kills: int, next_day: int) -> void:
	for c in get_children():
		c.queue_free()
	visible = true
	_chosen = ""
	_continue_day = next_day
	_dim()
	_panel = UiKit.panel_container(26)
	_panel.position = Vector2(150, 70)
	_panel.size = Vector2(980, 580)
	add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	_panel.add_child(v)

	_title = UiKit.label("第 %d 天 · 黎明" % day, 44, Color("#f6e7b4"))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_title)
	_sub = UiKit.label("潮水退去，留下三份祝福。选择一份带进白天。", 22, Color("#9fb0c8"))
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_sub)

	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 18)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(_cards)
	for relic in relics:
		_cards.add_child(_make_card(relic))

	_stats = UiKit.label("本日收获 %d 金币 · 击杀 %d 只怪物" % [gold_earned, kills], 22, Color("#f2c94c"))
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_stats)

	_continue = UiKit.button("选择一份祝福后继续", 28)
	_continue.custom_minimum_size = Vector2(420, 60)
	_continue.disabled = true
	_continue.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue.pressed.connect(func() -> void:
		Audio.sfx("click")
		continue_pressed.emit())
	v.add_child(_continue)


func _make_card(relic: Dictionary) -> Button:
	var b := UiKit.button("", 24)
	b.custom_minimum_size = Vector2(286, 300)
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.pressed.connect(_on_card.bind(relic))
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 18
	v.offset_top = 18
	v.offset_right = -18
	v.offset_bottom = -18
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 10)
	b.add_child(v)
	var icon := UiKit.icon("res://assets/generated/ui/%s.png" % relic["icon"], 96)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(icon)
	var name_label := UiKit.label(relic["name"], 30, Color(relic["color"]))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(name_label)
	var desc := UiKit.label(relic["desc"], 20, Color("#c8d6e8"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.custom_minimum_size = Vector2(240, 80)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(desc)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(spacer)
	var hint := UiKit.label("点击选择", 18, Color(0.65, 0.74, 0.85, 0.8))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(hint)
	return b


func _on_card(relic: Dictionary) -> void:
	if _chosen != "":
		return
	_chosen = relic["id"]
	Audio.sfx("buy")
	relic_chosen.emit(_chosen)
	for c in _cards.get_children():
		(c as Button).disabled = true
	_continue.disabled = false
	_continue.text = "继续 · 第 %d 天" % _continue_day
	_stats.text = "已获得：%s" % relic["name"]

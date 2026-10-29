class_name DawnScreen
extends Control
## Between days: choose one tide blessing, then optionally shop with gold.

signal relic_chosen(id: String)
signal continue_pressed
signal shop_buy(index: int)

var _panel: PanelContainer
var _title: Label
var _sub: Label
var _stats: Label
var _cards: HBoxContainer
var _shop_box: VBoxContainer
var _shop_hint: Label
var _notice: Label
var _continue: Button
var _chosen := ""
var _continue_day := 1
var _offers: Array = []
var _shop_buttons: Array[Button] = []
var _shop_price_labels: Array[Label] = []
var _gold := 0


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


func show_dawn(day: int, relics: Array, gold_earned: int, kills: int, next_day: int,
		offers: Array = [], gold: int = 0) -> void:
	for c in get_children():
		c.queue_free()
	visible = true
	_chosen = ""
	_continue_day = next_day
	_offers = offers
	_gold = gold
	_shop_buttons.clear()
	_shop_price_labels.clear()
	_dim()
	_panel = UiKit.panel_container(22)
	_panel.position = Vector2(150, 60)
	_panel.size = Vector2(980, 600)
	add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
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
	_cards.custom_minimum_size = Vector2(0, 300)
	v.add_child(_cards)
	for relic in relics:
		_cards.add_child(_make_card(relic))

	_shop_box = _make_shop_box()
	_shop_box.visible = false
	v.add_child(_shop_box)

	_stats = UiKit.label("本日收获 %d 金币 · 击杀 %d 只怪物" % [gold_earned, kills], 22, Color("#f2c94c"))
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_stats)

	_continue = UiKit.button("选择一份祝福后继续", 28)
	_continue.custom_minimum_size = Vector2(420, 58)
	_continue.disabled = true
	_continue.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue.pressed.connect(func() -> void:
		Audio.sfx("click")
		continue_pressed.emit())
	v.add_child(_continue)


func _make_card(relic: Dictionary) -> Button:
	var b := UiKit.button("", 24)
	b.custom_minimum_size = Vector2(286, 296)
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
	desc.custom_minimum_size = Vector2(240, 76)
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


func _make_shop_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size = Vector2(0, 296)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_shop_hint = UiKit.label("潮汐商店", 24, UiKit.GOLD)
	_shop_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_shop_hint)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	for i in range(_offers.size()):
		var offer: Dictionary = _offers[i]
		var b := UiKit.button("", 20)
		b.custom_minimum_size = Vector2(286, 120)
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_on_shop_pressed.bind(i))
		var h := HBoxContainer.new()
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 14
		h.offset_top = 10
		h.offset_right = -14
		h.offset_bottom = -10
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_theme_constant_override("separation", 10)
		b.add_child(h)
		var icon := UiKit.icon("res://assets/generated/ui/%s.png" % offer["icon"], 48)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(icon)
		var vv := VBoxContainer.new()
		vv.add_theme_constant_override("separation", 2)
		vv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(vv)
		var name_label := UiKit.label(offer["name"], 22, Color("#e8eef8"))
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vv.add_child(name_label)
		var desc := UiKit.label(offer["desc"], 16, Color("#9fb0c8"))
		desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vv.add_child(desc)
		var price := UiKit.label("%d 金币" % int(offer["price"]), 20, UiKit.GOLD)
		price.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vv.add_child(price)
		_shop_buttons.append(b)
		_shop_price_labels.append(price)
		row.add_child(b)
	_notice = UiKit.label("", 18, Color("#e2556b"))
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_notice)
	return box


func _on_card(relic: Dictionary) -> void:
	if _chosen != "":
		return
	_chosen = relic["id"]
	Audio.sfx("buy")
	relic_chosen.emit(_chosen)
	_cards.visible = false
	_sub.text = "祝福已选。可以去潮汐商店补充补给，或直接继续。"
	_shop_box.visible = true
	_continue.disabled = false
	_continue.text = "继续 · 第 %d 天" % _continue_day
	_stats.text = "已获得：%s" % relic["name"]
	refresh_shop(_gold, [false, false, false])


func _on_shop_pressed(index: int) -> void:
	if index >= 0 and index < _shop_buttons.size() and not _shop_buttons[index].disabled:
		shop_buy.emit(index)


func refresh_shop(gold: int, sold: Array) -> void:
	_gold = gold
	_shop_hint.text = "潮汐商店 · 金币 %d" % gold
	for i in range(_shop_buttons.size()):
		var offer: Dictionary = _offers[i]
		var is_sold: bool = i < sold.size() and bool(sold[i])
		var price := int(offer["price"])
		_shop_buttons[i].disabled = is_sold or price > gold
		_shop_price_labels[i].text = "已售出" if is_sold else "%d 金币" % price
		_shop_price_labels[i].add_theme_color_override("font_color",
			Color(0.55, 0.6, 0.68) if _shop_buttons[i].disabled else UiKit.GOLD)


func notify(text: String) -> void:
	if _notice:
		_notice.text = text


func ready_to_continue() -> bool:
	return _chosen != "" and _continue != null and not _continue.disabled

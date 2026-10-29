class_name TitleScreen
extends Control
## Title screen shown on boot.

signal start_requested
signal codex_requested
signal quit_requested

var _title: Label
var _help: PanelContainer
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.theme()
	_build()
	set_process(true)


func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/generated/bg/title.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.08, 0.18)
	shade.position = Vector2(0, 300)
	shade.size = Vector2(760, 420)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	_title = UiKit.label("鲸落农场", 104, Color("#f6e7b4"))
	_title.add_theme_constant_override("outline_size", 18)
	_title.add_theme_color_override("font_outline_color", Color("#141a2a"))
	_title.position = Vector2(92, 92)
	_title.size = Vector2(620, 120)
	add_child(_title)

	var sub := UiKit.label("W H A L E   F A L L   F A R M", 28, Color("#8fd3d6"))
	sub.position = Vector2(100, 214)
	add_child(sub)

	var tag := UiKit.label("白天种田，夜晚守夜。每一次潮汐，都是新的开始。", 24, Color("#c8d6e8"))
	tag.position = Vector2(100, 258)
	add_child(tag)

	var start := UiKit.button("开始新的一局", 30)
	start.position = Vector2(100, 330)
	start.size = Vector2(330, 62)
	start.pressed.connect(func() -> void:
		Audio.sfx("click")
		start_requested.emit())
	add_child(start)

	var help_btn := UiKit.button("操作说明", 26)
	help_btn.position = Vector2(100, 398)
	help_btn.size = Vector2(330, 54)
	help_btn.pressed.connect(_toggle_help)
	add_child(help_btn)

	var codex := UiKit.button("农场图鉴", 26)
	codex.position = Vector2(100, 464)
	codex.size = Vector2(330, 54)
	codex.pressed.connect(func() -> void:
		Audio.sfx("click")
		codex_requested.emit())
	add_child(codex)

	var quit := UiKit.button("离开", 26)
	quit.position = Vector2(100, 530)
	quit.size = Vector2(330, 54)
	quit.pressed.connect(func() -> void: quit_requested.emit())
	add_child(quit)

	var best := UiKit.label(_best_text(), 22, Color("#f2c94c"))
	best.position = Vector2(100, 610)
	best.size = Vector2(620, 30)
	add_child(best)

	var version := UiKit.label("v1.5.0 · 全部美术与音乐由程序生成", 18, Color(0.68, 0.76, 0.86, 0.7))
	version.position = Vector2(720, 680)
	version.size = Vector2(520, 24)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version)

	_help = _build_help()
	_help.visible = false
	add_child(_help)


func _best_text() -> String:
	if SaveGame.runs <= 0:
		return "尚无记录 · 第一局从今天开始"
	return "最佳记录：第 %d 天 · 最多击杀 %d · 已玩 %d 局" % [SaveGame.best_day, SaveGame.best_kills, SaveGame.runs]


func _build_help() -> PanelContainer:
	var p := UiKit.panel_container(20)
	p.position = Vector2(650, 300)
	p.size = Vector2(560, 300)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var title := UiKit.label("操作", 30, UiKit.GOLD)
	v.add_child(title)
	var lines := [
		"WASD / 方向键 —— 走动",
		"E —— 松土 / 播种 / 浇水 / 收获",
		"1 2 3 4 5 —— 切换种子",
		"空格 / 鼠标左键 —— 挥镰",
		"Esc —— 暂停",
	]
	if OS.has_feature("mobile"):
		lines = [
			"左侧摇杆 —— 走动",
			"右侧「镰」—— 挥镰（可长按）",
			"「互动」—— 松土 / 播种 / 浇水 / 收获",
			"轻点下方种子栏 —— 切换种子",
			"右上「Ⅱ」—— 暂停",
		]
	for line in lines:
		v.add_child(UiKit.label(line, 22, Color("#dbe6f4")))
	v.add_child(UiKit.label("夜幕降临后怪物会啃食作物，撑过七天。", 20, Color("#8fe0b0")))
	return p


func _toggle_help() -> void:
	_help.visible = not _help.visible
	Audio.sfx("click")


func _process(delta: float) -> void:
	_t += delta
	_title.position.y = 92.0 + sin(_t * 1.4) * 4.0


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			start_requested.emit()
		elif event.keycode == KEY_H:
			_toggle_help()

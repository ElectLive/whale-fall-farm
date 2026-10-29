class_name MobileControls
extends Control
## Touch controls: a floating joystick on the left, attack / interact / pause
## buttons on the right. Only instantiated on mobile (or with --touch).

signal attack_changed(held: bool)
signal attack_tap
signal interact_pressed
signal pause_pressed

const JOY_CENTER := Vector2(170, 520)
const JOY_DRAW_RADIUS := 78.0
const JOY_TOUCH_RADIUS := 140.0
const JOY_TRAVEL := 62.0

var move_vector := Vector2.ZERO

var _touch_index := -1
var _draw_knob := Vector2.ZERO
var _attack_btn: Button
var _interact_btn: Button
var _pause_btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_buttons()
	set_process_input(true)


func _build_buttons() -> void:
	_attack_btn = _make_round_button("镰", Vector2(1140, 560), 74, 46, Color("#e8d9a8"))
	_attack_btn.button_down.connect(func() -> void:
		attack_changed.emit(true)
		Audio.sfx("click", 1.4, -12.0))
	_attack_btn.button_up.connect(func() -> void: attack_changed.emit(false))
	_attack_btn.pressed.connect(func() -> void: attack_tap.emit())
	add_child(_attack_btn)

	_interact_btn = _make_round_button("互动", Vector2(1005, 618), 50, 22, Color("#8fe0b0"))
	_interact_btn.pressed.connect(func() -> void: interact_pressed.emit())
	add_child(_interact_btn)

	_pause_btn = _make_round_button("Ⅱ", Vector2(1218, 150), 28, 24, Color("#c8d6e8"))
	_pause_btn.pressed.connect(func() -> void: pause_pressed.emit())
	add_child(_pause_btn)


func _make_round_button(text: String, center: Vector2, radius: float, font_size: int, accent: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.position = center - Vector2(radius, radius)
	b.size = Vector2(radius * 2.0, radius * 2.0)
	b.add_theme_font_override("font", UiKit.font())
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color("#f4f0e2"))
	b.add_theme_color_override("font_pressed_color", accent)
	var normal := _circle_style(Color(0.04, 0.07, 0.12, 0.62), Color(accent.r, accent.g, accent.b, 0.55), 2)
	var hover := _circle_style(Color(0.08, 0.13, 0.2, 0.78), accent, 3)
	var pressed := _circle_style(Color(0.16, 0.24, 0.3, 0.88), accent, 3)
	for state in [["normal", normal], ["hover", hover], ["pressed", pressed], ["focus", hover]]:
		b.add_theme_stylebox_override(state[0], state[1])
	return b


func _circle_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.border_width_left = width
	sb.border_width_right = width
	sb.border_width_top = width
	sb.border_width_bottom = width
	sb.corner_radius_top_left = 999
	sb.corner_radius_top_right = 999
	sb.corner_radius_bottom_left = 999
	sb.corner_radius_bottom_right = 999
	return sb


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_index == -1 and event.position.distance_to(JOY_CENTER) <= JOY_TOUCH_RADIUS:
				_touch_index = event.index
				_update_joystick(event.position)
				get_viewport().set_input_as_handled()
		elif event.index == _touch_index:
			_release_joystick()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_joystick(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _touch_index == -1 and event.position.distance_to(JOY_CENTER) <= JOY_TOUCH_RADIUS:
			_touch_index = 0
			_update_joystick(event.position)
		elif not event.pressed and _touch_index == 0:
			_release_joystick()
	elif event is InputEventMouseMotion and _touch_index == 0:
		_update_joystick(event.position)


func _update_joystick(at: Vector2) -> void:
	var v := (at - JOY_CENTER) / JOY_TRAVEL
	if v.length() > 1.0:
		v = v.normalized()
	if v.length() < 0.16:
		v = Vector2.ZERO
	move_vector = v
	_draw_knob = v * (JOY_TRAVEL - 18.0)
	queue_redraw()


func _release_joystick() -> void:
	_touch_index = -1
	move_vector = Vector2.ZERO
	_draw_knob = Vector2.ZERO
	queue_redraw()


func set_active(on: bool) -> void:
	visible = on
	_attack_btn.disabled = not on
	_interact_btn.disabled = not on
	_pause_btn.disabled = not on
	if not on:
		attack_changed.emit(false)
		_release_joystick()


func _draw() -> void:
	var base := Color(0.04, 0.08, 0.13, 0.38)
	var ring := Color(0.62, 0.82, 0.9, 0.28)
	var knob := Color(0.62, 0.85, 0.88, 0.52)
	draw_circle(JOY_CENTER, JOY_DRAW_RADIUS, base)
	draw_arc(JOY_CENTER, JOY_DRAW_RADIUS, 0, TAU, 48, ring, 2.0, true)
	draw_circle(JOY_CENTER + _draw_knob, 30.0, knob)
	draw_arc(JOY_CENTER + _draw_knob, 30.0, 0, TAU, 32, Color(0.85, 0.95, 1.0, 0.5), 2.0, true)

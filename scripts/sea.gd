class_name Sea
extends Node2D
## Animated ocean painted directly with draw calls (no textures).

var night_mix := 0.0
var target_mix := 0.0
var t := 0.0
var _stars: Array[Vector3] = []


func _ready() -> void:
	z_index = -100
	var rng := RandomNumberGenerator.new()
	rng.seed = 991
	for i in range(70):
		_stars.append(Vector3(rng.randf_range(-80, 400), rng.randf_range(-40, 80), rng.randf_range(0.2, 1.0)))


func set_night(v: bool) -> void:
	target_mix = 1.0 if v else 0.0


func _process(delta: float) -> void:
	t += delta
	night_mix = move_toward(night_mix, target_mix, delta * 0.9)
	queue_redraw()


func _draw() -> void:
	var top := Color("#20415c").lerp(Color("#070c18"), night_mix)
	var bottom := Color("#123049").lerp(Color("#04070f"), night_mix)
	# vertical gradient bands
	for i in range(0, 72):
		var y := -48.0 + i * 4.0
		var f := float(i) / 72.0
		draw_rect(Rect2(-120, y, 560, 4.5), top.lerp(bottom, f))
	# stars
	if night_mix > 0.02:
		for s in _stars:
			var tw := 0.55 + 0.45 * sin(t * 2.0 + s.z * 12.0)
			draw_rect(Rect2(s.x, s.y, 1.5 if s.z > 0.6 else 1.0, 1.5), Color(0.85, 0.9, 1.0, night_mix * tw * 0.85))
	# moon reflection column
	if night_mix > 0.02:
		var mx := 246.0
		for i in range(18):
			var yy := -20.0 + i * 9.0
			var w := 10.0 + 8.0 * sin(i * 0.8 + t * 1.5)
			draw_rect(Rect2(mx - w * 0.5 + sin(i + t) * 3.0, yy, w, 1.2), Color(0.9, 0.92, 0.8, 0.10 * night_mix))
	# wave lines
	var wave_col := Color(0.62, 0.82, 0.9, 0.18).lerp(Color(0.32, 0.45, 0.7, 0.18), night_mix)
	for row in range(44):
		var y := -40.0 + row * 6.0
		var speed := 5.0 + float(row % 5) * 2.0
		var off := sin(t * 0.6 + row * 0.7) * 7.0 + fmod(t * speed, 40.0)
		var x := -100.0 + off
		while x < 400.0:
			var w := 6.0 + float(row % 3) * 4.0
			draw_rect(Rect2(x, y, w, 1.0), wave_col)
			x += 26.0 + float(row % 4) * 9.0
	# foam near the island
	var foam := Color(0.72, 0.88, 0.9, 0.22).lerp(Color(0.45, 0.6, 0.8, 0.16), night_mix)
	for i in range(26):
		var a := float(i) / 26.0 * TAU
		var cx := 120.0 + cos(a) * 152.0
		var cy := 64.0 + sin(a) * 96.0
		var wob := sin(t * 1.4 + i) * 1.5
		draw_rect(Rect2(cx + wob, cy, 3.0, 1.0), foam)

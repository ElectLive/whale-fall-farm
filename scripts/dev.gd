extends Node
## Developer hooks: headless self-test and deterministic screenshots.
##
## Run:
##   Godot --headless --path . -- --selftest
##   Godot --path . -- --shot=day
##   Godot --path . -- --shot=night

var _args: PackedStringArray = []
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_args = OS.get_cmdline_user_args()
	call_deferred("_boot")


func _boot() -> void:
	if _busy:
		return
	_busy = true
	await get_tree().process_frame
	await get_tree().process_frame
	var main := get_tree().current_scene
	if main == null:
		get_tree().quit(2)
		return
	if "--selftest" in _args:
		var code: int = await main.run_selftest()
		get_tree().quit(code)
		return
	if "--smoke" in _args:
		var code2: int = await main.run_smoke()
		get_tree().quit(code2)
		return
	for arg in _args:
		if arg.begins_with("--shot="):
			var shot_name := arg.trim_prefix("--shot=")
			await _take_shot(main, shot_name)
			return
	# no dev command: leave the game running normally
	_busy = false


func _take_shot(main: Node, shot_name: String) -> void:
	main.setup_shot(shot_name)
	# let the state settle and any tween finish
	await get_tree().create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var dir := ""
	if OS.has_feature("editor"):
		dir = ProjectSettings.globalize_path("res://screenshots")
	else:
		dir = OS.get_executable_path().get_base_dir().path_join("screenshots")
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join("shot_%s.png" % shot_name)
	var err := img.save_png(path)
	if err == OK:
		print("SHOT_OK ", path, " ", img.get_width(), "x", img.get_height())
	else:
		print("SHOT_FAIL ", path, " err=", err)
	get_tree().quit(0 if err == OK else 1)

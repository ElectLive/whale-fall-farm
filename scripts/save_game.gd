extends Node
## Persistent records. Stored next to the project (editor) or the executable
## (exported build) so the game is portable and never depends on AppData.

var best_day := 0
var best_kills := 0
var runs := 0
var total_gold := 0
var music_on := true
var sfx_on := true
var vibration_on := true
var screen_shake_on := true
var reduce_flash := false
var auto_aim := false
var daily_best_day := 0
var daily_best_date := ""
var save_version := 2
var achievements: Array[String] = []
var crops_harvested := 0
var enemies_killed := 0
var golden_harvested := 0
var discovered_crops: Array[String] = []
var discovered_enemies: Array[String] = []
var discovered_relics: Array[String] = []
var PATH := ""


func _ready() -> void:
	PATH = _resolve_path()
	load_data()


func _resolve_path() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://save_data.cfg")
	if OS.has_feature("mobile"):
		return "user://save_data.cfg"
	var base := OS.get_executable_path().get_base_dir()
	if not base.is_empty():
		return base.path_join("save_data.cfg")
	return "user://save_data.cfg"


func load_data() -> void:
	var cfg := ConfigFile.new()
	if PATH == "" or cfg.load(PATH) != OK:
		return
	best_day = int(cfg.get_value("records", "best_day", 0))
	best_kills = int(cfg.get_value("records", "best_kills", 0))
	runs = int(cfg.get_value("records", "runs", 0))
	total_gold = int(cfg.get_value("records", "total_gold", 0))
	music_on = bool(cfg.get_value("settings", "music_on", true))
	sfx_on = bool(cfg.get_value("settings", "sfx_on", true))
	vibration_on = bool(cfg.get_value("settings", "vibration_on", true))
	screen_shake_on = bool(cfg.get_value("settings", "screen_shake_on", true))
	reduce_flash = bool(cfg.get_value("settings", "reduce_flash", false))
	auto_aim = bool(cfg.get_value("settings", "auto_aim", false))
	daily_best_day = int(cfg.get_value("records", "daily_best_day", 0))
	daily_best_date = String(cfg.get_value("records", "daily_best_date", ""))
	save_version = int(cfg.get_value("meta", "save_version", 1))
	crops_harvested = int(cfg.get_value("records", "crops_harvested", 0))
	enemies_killed = int(cfg.get_value("records", "enemies_killed", 0))
	golden_harvested = int(cfg.get_value("records", "golden_harvested", 0))
	var arr = cfg.get_value("records", "achievements", [])
	achievements.clear()
	if arr is Array:
		for a in arr:
			achievements.append(str(a))
	_load_list(cfg, "discovered_crops", discovered_crops)
	_load_list(cfg, "discovered_enemies", discovered_enemies)
	_load_list(cfg, "discovered_relics", discovered_relics)


func _load_list(cfg: ConfigFile, key: String, target: Array[String]) -> void:
	target.clear()
	var arr = cfg.get_value("records", key, [])
	if arr is Array:
		for a in arr:
			target.append(str(a))


func save_data() -> void:
	if PATH == "":
		PATH = _resolve_path()
	var cfg := ConfigFile.new()
	cfg.set_value("records", "best_day", best_day)
	cfg.set_value("records", "best_kills", best_kills)
	cfg.set_value("records", "runs", runs)
	cfg.set_value("records", "total_gold", total_gold)
	cfg.set_value("settings", "music_on", music_on)
	cfg.set_value("settings", "sfx_on", sfx_on)
	cfg.set_value("settings", "vibration_on", vibration_on)
	cfg.set_value("settings", "screen_shake_on", screen_shake_on)
	cfg.set_value("settings", "reduce_flash", reduce_flash)
	cfg.set_value("settings", "auto_aim", auto_aim)
	cfg.set_value("meta", "save_version", save_version)
	cfg.set_value("records", "daily_best_day", daily_best_day)
	cfg.set_value("records", "daily_best_date", daily_best_date)
	cfg.set_value("records", "crops_harvested", crops_harvested)
	cfg.set_value("records", "enemies_killed", enemies_killed)
	cfg.set_value("records", "golden_harvested", golden_harvested)
	cfg.set_value("records", "achievements", achievements)
	cfg.set_value("records", "discovered_crops", discovered_crops)
	cfg.set_value("records", "discovered_enemies", discovered_enemies)
	cfg.set_value("records", "discovered_relics", discovered_relics)
	var err := cfg.save(PATH)
	if err != OK:
		push_warning("whale_fall_farm: could not save records (%s, err %d)" % [PATH, err])


func record_run(day: int, kills: int, gold: int) -> void:
	runs += 1
	total_gold += gold
	best_day = maxi(best_day, day)
	best_kills = maxi(best_kills, kills)
	save_data()


func update_best(day: int, kills: int) -> void:
	## Called when an endless run continues past the recorded victory.
	best_day = maxi(best_day, day)
	best_kills = maxi(best_kills, kills)
	save_data()


func add_achievement(id: String) -> bool:
	if achievements.has(id):
		return false
	achievements.append(id)
	save_data()
	return true


func discover_crop(id: String) -> bool:
	if discovered_crops.has(id):
		return false
	discovered_crops.append(id)
	save_data()
	return true


func discover_enemy(id: String) -> bool:
	if discovered_enemies.has(id):
		return false
	discovered_enemies.append(id)
	save_data()
	return true


func discover_relic(id: String) -> bool:
	if discovered_relics.has(id):
		return false
	discovered_relics.append(id)
	save_data()
	return true

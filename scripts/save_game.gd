extends Node
## Persistent records. Stored next to the project (editor) or the executable
## (exported build) so the game is portable and never depends on AppData.

var best_day := 0
var best_kills := 0
var runs := 0
var total_gold := 0
var music_on := true
var sfx_on := true
var PATH := ""


func _ready() -> void:
	PATH = _resolve_path()
	load_data()


func _resolve_path() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://save_data.cfg")
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
	var err := cfg.save(PATH)
	if err != OK:
		push_warning("whale_fall_farm: could not save records (%s, err %d)" % [PATH, err])


func record_run(day: int, kills: int, gold: int) -> void:
	runs += 1
	total_gold += gold
	best_day = maxi(best_day, day)
	best_kills = maxi(best_kills, kills)
	save_data()

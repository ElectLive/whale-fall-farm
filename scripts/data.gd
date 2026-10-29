class_name GameData
extends RefCounted
## Static game tables: crops, enemies, night waves and tide blessings (relics).

const TILE := 16
const FARM_W := 15
const FARM_H := 8
const WIN_DAY := 7

const CROPS := {
	"radish": {
		"name": "萝卜", "seed_cost": 3, "value": 9, "grow": 7.0,
		"seed_drop": 0.40, "color": Color("#d64c54"),
		"desc": "长得快，卖得便宜。",
	},
	"pumpkin": {
		"name": "南瓜", "seed_cost": 9, "value": 24, "grow": 13.0,
		"seed_drop": 0.30, "color": Color("#e8893a"),
		"desc": "慢一点，但沉甸甸。",
	},
	"star": {
		"name": "星露花", "seed_cost": 20, "value": 54, "grow": 20.0,
		"seed_drop": 0.20, "color": Color("#7ee3d4"),
		"desc": "只在鲸背上开的花。",
	},
	"moonwheat": {
		"name": "月光麦", "seed_cost": 16, "value": 44, "grow": 9.0,
		"seed_drop": 0.25, "color": Color("#cfe8b0"),
		"desc": "只在夜里生长，白天会打盹。",
		"night_only": true,
	},
}
const CROP_ORDER := ["radish", "pumpkin", "star", "moonwheat"]

const ENEMIES := {
	"slime": {
		"name": "潮泥怪", "hp": 3, "speed": 21.0, "damage": 1, "gold": 2,
		"texture": "res://assets/generated/chars/slime.png", "frames": 4, "scale": 1.0,
	},
	"crow": {
		"name": "偷穗鸦", "hp": 2, "speed": 34.0, "damage": 1, "gold": 3,
		"texture": "res://assets/generated/chars/crow.png", "frames": 2, "scale": 1.0,
	},
	"vine": {
		"name": "缠根怪", "hp": 7, "speed": 13.0, "damage": 2, "gold": 5,
		"texture": "res://assets/generated/chars/vine.png", "frames": 2, "scale": 1.0,
	},
	"frog": {
		"name": "沼泽蛙", "hp": 4, "speed": 62.0, "damage": 1, "gold": 4,
		"texture": "res://assets/generated/chars/frog.png", "frames": 2, "scale": 1.0,
	},
	"boss": {
		"name": "腐化南瓜王", "hp": 24, "speed": 15.0, "damage": 2, "gold": 60,
		"texture": "res://assets/generated/chars/boss_pumpkin.png", "frames": 2, "scale": 1.0,
		"size": 32, "boss": true,
	},
}

const SHOP_OFFERS := [
	{"id": "seed_radish", "name": "萝卜种子 ×3", "desc": "长得快，回本快", "price": 6, "icon": "seed_radish"},
	{"id": "seed_pumpkin", "name": "南瓜种子 ×2", "desc": "沉甸甸的稳健收益", "price": 14, "icon": "seed_pumpkin"},
	{"id": "seed_star", "name": "星露花种子 ×1", "desc": "很贵，但值得", "price": 18, "icon": "seed_star"},
	{"id": "seed_moon", "name": "月光麦种子 ×1", "desc": "只在夜里生长", "price": 16, "icon": "seed_moon"},
	{"id": "heal", "name": "潮汐药汤", "desc": "回复 2 点生命", "price": 8, "icon": "heart_full"},
	{"id": "maxhp", "name": "鲸骨护心镜", "desc": "生命上限 +1，回复 1", "price": 24, "icon": "heart_full"},
]

const RELICS := [
	{"id": "boots", "name": "疾风草鞋", "desc": "移动速度 +20%", "icon": "relic_boots", "color": "#8fd3d6"},
	{"id": "whetstone", "name": "磨刀石", "desc": "镰刀伤害 +1", "icon": "relic_whetstone", "color": "#c8d2e0"},
	{"id": "blubber", "name": "鲸脂护符", "desc": "生命上限 +2，并回复 2 点", "icon": "relic_blubber", "color": "#7fb0e8"},
	{"id": "metronome", "name": "节拍贝壳", "desc": "挥镰速度 +25%", "icon": "relic_metronome", "color": "#e8c56a"},
	{"id": "rainbell", "name": "春雨铃", "desc": "作物生长速度 +30%", "icon": "relic_rainbell", "color": "#8fe0b0"},
	{"id": "goldseed", "name": "金穗", "desc": "获得的金币 +25%", "icon": "relic_goldseed", "color": "#f2c94c"},
	{"id": "fang", "name": "吸血鬼鱼牙", "desc": "击杀敌人时 15% 概率回复 1 点生命", "icon": "relic_fang", "color": "#e2556b"},
	{"id": "thorns", "name": "荆棘斗篷", "desc": "受击时对敌人反弹 1 点伤害", "icon": "relic_thorns", "color": "#a8c060"},
	{"id": "clover", "name": "四叶幸运草", "desc": "敌人掉落种子的概率 +15%", "icon": "relic_clover", "color": "#6fd08c"},
	{"id": "tideheart", "name": "潮汐之心", "desc": "每天黎明回复 1 点生命", "icon": "relic_tideheart", "color": "#7ee3d4"},
	{"id": "longhandle", "name": "长柄镰", "desc": "镰刀攻击范围 +30%", "icon": "relic_longhandle", "color": "#d8b48a"},
	{"id": "nightglass", "name": "夜视螺镜", "desc": "夜晚移动速度 +20%", "icon": "relic_nightglass", "color": "#9a8fe0"},
	{"id": "slowcharm", "name": "潮雾提灯", "desc": "夜晚怪物移动速度 -12%", "icon": "relic_slowcharm", "color": "#8fd3d6"},
	{"id": "greenthumb", "name": "绿拇指", "desc": "浇水时作物立即获得 15% 生长进度", "icon": "relic_greenthumb", "color": "#8fe0b0"},
]


static func night_duration(day: int) -> float:
	return minf(38.0, 20.0 + day * 2.0)


static func night_plan(day: int) -> Array:
	if day == WIN_DAY:
		return [
			{"kind": "slime", "count": 6},
			{"kind": "crow", "count": 3},
			{"kind": "vine", "count": 2},
			{"kind": "frog", "count": 3},
		]
	var extra := maxi(0, day - 7)
	return [
		{"kind": "slime", "count": 4 + (day - 1) * 2 + extra * 2},
		{"kind": "crow", "count": maxi(0, day - 1) + extra},
		{"kind": "vine", "count": maxi(0, day - 3) + extra},
		{"kind": "frog", "count": maxi(0, day - 4) + extra},
	]


static func hp_scale(day: int) -> float:
	return 1.0 + (day - 1) * 0.12


static func seed_pack() -> Array:
	## Returns three seed ids for the dawn shop.
	return []


static func relic_by_id(id: String) -> Dictionary:
	for r in RELICS:
		if r["id"] == id:
			return r
	return {}

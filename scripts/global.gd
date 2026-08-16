extends Node

signal credits_changed(value: float)
signal gems_changed(value: float)

var credits: float = 0.0
var gems: float = 0.0
var bonus_thrust: float = 1.0
var thrust_level: int = 0
var tank_level: int = 0
var time_level: int = 0
var next_planet: int = 0
var planets_unlocked: Array[bool] = []
var best_altitude: float = 0.0
var rebirth_count: int = 0
var credit_mult: float = 1.0
var gem_mult: float = 1.0
var highscores: Array = []

const PLANET_NAMES: Array[String] = [
	"Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto",
	"Super Mercury", "Super Venus", "Super Earth", "Super Mars", "Super Jupiter", "Super Saturn",
	"Super Uranus", "Super Neptune", "Red Planet", "Asteroid", "Comet", "Star", "Super Star",
	"Milky Way", "Black Hole"
]
const PLANET_ALTITUDES: Array[float] = [
	10000.0, 50000.0, 150000.0, 700000.0, 2000000.0, 10000000.0,
	350000000.0, 1000000000.0, 4000000000.0, 9000000000.0,
	20000000000.0, 50000000000.0, 80000000000.0, 100000000000.0,
	300000000000.0, 700000000000.0, 1000000000000.0, 10000000000000.0,
	100000000000000.0, 1000000000000000.0, 5000000000000000.0,
	35000000000000000.0, 3500000000000000000.0, 350000000000000000000.0,
]
const STAGE_SPEEDS: Array[float] = [5.0, 2.5, 1.5]
const STAGE_THRUSTS: Array[float] = [5.0, 2.5, 1.5]

const BASE_COSTS := {"thrust": 50.0, "tank": 2000.0, "time": 50000.0}
const COST_GROWTH := 1.8

const OFFLINE_CAP := 8.0 * 3600.0

const SAVE_PATH := "user://savegame.json"
var last_seen: float = 0.0

func _ready() -> void:
	planets_unlocked.resize(PLANET_NAMES.size())
	planets_unlocked.fill(false)
	
func tank_capacity() -> float:
	return 20.0 + 10.0 * tank_level
	
func thrust_power() -> float:
	return 1.0 + 0.5 * thrust_level
	
func time_speed() -> float:
	return 1.0 + 0.25 * time_level
	
func upgrade_cost(kind: String) -> float:
	var lv := 0
	match kind:
		"thrust": lv = thrust_level
		"tank": lv = tank_level
		"time": lv = time_level
	return BASE_COSTS[kind] * pow(COST_GROWTH, lv)
	
func add_credits(v: float) -> void:
	credits += v * credit_mult
	credits_changed.emit(credits)
	
func add_gems(v: float) -> void:
	gems += v * gem_mult
	gems_changed.emit(gems)
	
const SUFFIXES: Array[String] = ["", "K", "M", "B", "T"]
func fmt(n: float) -> String:
	if n < 1000.0:
		return str(int(n))
	var tier := int(floor(log(n) / log(1000.0)))
	var suffix := ""
	if tier <= 4:
		suffix = SUFFIXES[tier]
	else:
		var t := tier - 5
		suffix = String.chr(97+t/26) + String.chr(97+t%26)
	return "%.2f%s" % [n / pow(1000.0, tier), suffix]
	
func save_game() -> void:
	last_seen = Time.get_unix_time_from_system()
	var data := {
		"credits": credits, "gems": gems,
		"thrust_level": thrust_level, "tank_level": tank_level, "time_level": time_level,
		"next_planet": next_planet, "planets_unlocked": planets_unlocked,
		"best_altitude": best_altitude,
		"rebirth_count": rebirth_count,
		"credit_mult": credit_mult, "gem_mult": gem_mult,
		"highscores": highscores, "last_seen": last_seen,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
	
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	credits = data.get("credits", 0.0)
	gems = data.get("gems", 0.0)
	thrust_level = data.get("thrust_level", 0)
	tank_level = data.get("tank_level", 0)
	time_level = data.get("time_level", 0)
	next_planet = data.get("next_planet", 0)
	best_altitude = data.get("best_altitude", 0.0)
	rebirth_count = data.get("rebirth_count", 0)
	credit_mult = data.get("credit_mult", 1.0)
	gem_mult = data.get("gem_mult", 1.0)
	highscores = data.get("highscores", [])
	last_seen = data.get("last_seen", 0.0)
	var saved_unlocked: Array = data.get("planets_unlocked", [])
	for i in min(saved_unlocked.size(), PLANET_NAMES.size()):
		planets_unlocked[i] = saved_unlocked[i]
		
func offline_earnings(now: float) -> float:
	if last_seen <= 0.0:
		return 0.0
	var dt: float = minf(now-last_seen, OFFLINE_CAP)
	return dt*tank_capacity() * 0.005 * credit_mult

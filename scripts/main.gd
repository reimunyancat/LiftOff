extends Node2D

enum State { IDLE, FLYING }

const FUEL_PER_SEC := 1.0
const BURN_PER_SEC := 1.0
const ALT_SCALE := 100.0
const ROCKET_BASE_Y := 480.0
const ROCKET_VISUAL := 0.0004

var state: State = State.IDLE
var fuel := 0.0
var altitude := 0.0
var stage := 0

@onready var rocket: Node2D = $Rocket
@onready var credits_label: Label = $UI/CreditsLabel
@onready var gems_label: Label = $UI/GemsLabel
@onready var fuel_bar: ProgressBar = $UI/FuelBar
@onready var altitude_label: Label = $UI/AltitudeLabel
@onready var planet_label: Label = $UI/PlanetLabel
@onready var info_label: Label = $UI/InfoLabel
@onready var thrust_button: Button = $UI/Upgrades/BuyThrust
@onready var tank_button: Button = $UI/Upgrades/BuyTank
@onready var time_button: Button = $UI/Upgrades/BuyTime

func _ready() -> void:
	rocket.position.y = ROCKET_BASE_Y
	_refresh_ui()

func _process(delta: float) -> void:
	var dt := delta * Global.time_speed()
	if state == State.IDLE:
		fuel = minf(Global.tank_capacity(), fuel + FUEL_PER_SEC * dt)
	else:
		fuel -= BURN_PER_SEC * dt
		var spd: float = Global.STAGE_SPEEDS[stage] * Global.STAGE_THRUSTS[stage] \
			* Global.thrust_power() * Global.bonus_thrust
		altitude += spd * ALT_SCALE * dt
		rocket.position.y = maxf(80.0, ROCKET_BASE_Y - altitude * ROCKET_VISUAL)
		var burned := Global.tank_capacity() - fuel
		stage = clampi(int(burned / (Global.tank_capacity() / 3.0)), 0, 2)
		if fuel <= 0.0:
			_land()
	_refresh_ui()

func _on_launch_pressed() -> void:
	if state != State.IDLE or fuel < 5.0:
		return
	state = State.FLYING
	altitude = 0.0
	stage = 0
	info_label.text = "Stage 1 — burning!"

func _land() -> void:
	state = State.IDLE
	fuel = 0.0
	Global.add_credits(altitude)
	if altitude > Global.best_altitude:
		Global.best_altitude = altitude
	while Global.next_planet < Global.PLANET_NAMES.size() \
			and altitude >= Global.PLANET_ALTITUDES[Global.next_planet]:
		Global.planets_unlocked[Global.next_planet] = true
		Global.add_gems(Global.next_planet + 1)
		Global.next_planet += 1
	Global.bonus_thrust = 1.0
	Global.save_game()
	rocket.position.y = ROCKET_BASE_Y
	info_label.text = "Touchdown! +%s Credits" % Global.fmt(altitude)
	if Global.next_planet >= Global.PLANET_NAMES.size():
		get_tree().change_scene_to_file("res://scenes/win.tscn")

func _buy(kind: String) -> void:
	var cost := Global.upgrade_cost(kind)
	if Global.credits < cost:
		return
	Global.credits -= cost
	match kind:
		"thrust": Global.thrust_level += 1
		"tank": Global.tank_level += 1
		"time": Global.time_level += 1
	_refresh_ui()

func _on_buy_thrust_pressed() -> void:
	_buy("thrust")

func _on_buy_tank_pressed() -> void:
	_buy("tank")

func _on_buy_time_pressed() -> void:
	_buy("time")

func _on_starhop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/starhop.tscn")

func _on_timing_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ignition_timing.tscn")

func _on_intercept_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/meteor_intercept.tscn")

func _on_codex_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/codex.tscn")

func _on_rebirth_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/rebirth.tscn")

func _refresh_ui() -> void:
	credits_label.text = "Credits: %s" % Global.fmt(Global.credits)
	gems_label.text = "Gems: %s" % Global.fmt(Global.gems)
	fuel_bar.max_value = Global.tank_capacity()
	fuel_bar.value = fuel
	altitude_label.text = "Altitude: %s m" % Global.fmt(altitude)
	if Global.next_planet < Global.PLANET_NAMES.size():
		planet_label.text = "Next: %s (%s m)" % [
			Global.PLANET_NAMES[Global.next_planet],
			Global.fmt(Global.PLANET_ALTITUDES[Global.next_planet]),
		]
	else:
		planet_label.text = "All planets reached!"
	thrust_button.text = "Thrust Lv.%d — %s Cr" % [Global.thrust_level, Global.fmt(Global.upgrade_cost("thrust"))]
	tank_button.text = "Tank Lv.%d — %s Cr" % [Global.tank_level, Global.fmt(Global.upgrade_cost("tank"))]
	time_button.text = "Time Lv.%d — %s Cr" % [Global.time_level, Global.fmt(Global.upgrade_cost("time"))]

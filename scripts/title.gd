extends Node2D

func _ready() -> void:
	Global.load_game()
	var earned := Global.offline_earnings(Time.get_unix_time_from_system())
	if earned > 0.0:
		Global.credits += earned
		$UI/OfflineLabel.text = "While you were away: +%s Credits" % Global.fmt(earned)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_scores_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/highscores.tscn")

func _on_quit_pressed() -> void:
	Global.save_game()
	get_tree().quit()
	

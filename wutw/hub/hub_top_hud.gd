class_name HubTopHud
extends Node2D

func _ready() -> void:
	_update_pause_button_visibility()
	GlobalGameSettings.changed.connect(_update_pause_button_visibility)

func get_insights_counter() -> InsightsCounter:
	return %InsightsCounter

func get_quest_hud() -> QuestHud:
	return %QuestHud

func get_pause_button() -> PauseButton:
	return %PauseButton

func _update_pause_button_visibility() -> void:
	get_pause_button().visible = GameSettings.Interface.show_pause_button.value()

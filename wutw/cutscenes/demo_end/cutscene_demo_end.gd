class_name Cutscene_Demo_End
extends Node2D

signal finished

const STEAM_URL := 'https://store.steampowered.com/app/3640430/Worlds_Upon_The_Wind/'
const SURVEY_URL := 'https://docs.google.com/forms/d/e/1FAIpQLSceRoq78JfgJR9SQcna3rm6P8B7sAfnlFn-8t6ET9ZMavIIFQ/viewform'

func _ready() -> void:
	(%SteamLabel as Label).text = tr('Upgrade on Steam')
	Utils.set_input_enabled(%CTAs as Control, false)
	(%CatAnimationPlayer as AnimationPlayer).play('idle')
	(%AnimationPlayer as AnimationPlayer).queue('fadein')
	await (%AnimationPlayer as AnimationPlayer).animation_finished
	Utils.set_input_enabled(%CTAs as Control, true)

func _on_cat_button_pressed() -> void:
	if (%CatAnimationPlayer as AnimationPlayer).current_animation != 'react':
		(%CatAnimationPlayer as AnimationPlayer).play('react')
		(%CatAnimationPlayer as AnimationPlayer).queue('idle')
		GlobalAudioSystem.play(AK.EVENTS.SFX_ANIMAL_COMPANION_CAT)

func _on_survey_button_pressed() -> void:
	OS.shell_open(SURVEY_URL)

func _on_discord_button_pressed() -> void:
	OS.shell_open(DiscordButton.DISCORD_INVITE_URL)

func _on_steam_button_pressed() -> void:
	OS.shell_open(STEAM_URL)

func _on_survey_button_mouse_entered() -> void:
	(%SurveyButton as Button).modulate = Color(.5, .5, .5)

func _on_survey_button_mouse_exited() -> void:
	(%SurveyButton as Button).modulate = Color.WHITE

func _on_discord_button_mouse_entered() -> void:
	(%DiscordButton as Button).modulate = Color(.5, .5, .5)

func _on_discord_button_mouse_exited() -> void:
	(%DiscordButton as Button).modulate = Color.WHITE

func _on_steam_button_mouse_entered() -> void:
	(%SteamButton as Button).modulate = Color(.5, .5, .5)

func _on_steam_button_mouse_exited() -> void:
	(%SteamButton as Button).modulate = Color.WHITE

func _on_exit_button_pressed() -> void:
	finished.emit()

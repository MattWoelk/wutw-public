extends Node2D

var _run: Run

func _ready() -> void:
	GlobalGameSettings.read_only = true
	GlobalGameSettings.Interface.animation_speed.set_value(1.25)
	GameSettings.Interface.tooltip_speed.set_value(.001)
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P510_FINISHED_OUTRO_CUTSCENE)

	# Setup run.
	var RUN_SCENE := load('res://run/run.tscn') as PackedScene
	_run = RUN_SCENE.instantiate() as Run
	_run.run_config = RunConfig.new()
	_run.run_config.run_type = RunSetup.get_default_run_type()
	_run.run_config.starting_cards = [
		load('res://cards/tier2/card_four.tres'),
		load('res://cards/tier5/card_echo.tres'),
		load('res://cards/tier5/card_loop.tres'),
		load('res://cards/tier3/card_righteousness.tres'),
		load('res://cards/tier3/card_chat.tres'),
		load('res://cards/tier2/card_koto.tres'),
		load('res://cards/tier2/card_search.tres'),
	]
	_run.run_config.run_seed = 12
	_run.run_config.debug_map_seed = 9142
	add_child(_run)
	await get_tree().process_frame
	var map := _run.get_map()
	await map.cloud_generation_finished
	await get_tree().create_timer(1).timeout

	# Start survey.
	const SURVEY_LOCATION := Vector2i(295, 183)
	_run._data.current_survey_location = SURVEY_LOCATION
	_run.get_vars().modify_base_value(RunVars.Var.HAND_SIZE, 6)
	_run.set_state(RunData.State.SURVEY)
	await get_tree().process_frame

	# Drag card to activate recipe.
	map.instant_focus_location(SURVEY_LOCATION, 5.5)
	await get_tree().create_timer(1).timeout
	var survey := _run.get_current_stage().get_survey()
	await get_tree().create_timer(0.5).timeout
	survey._start_episode(load('res://stage/survey/episodes/episode_beautiful_valley.tres') as SurveyEpisode, false, false)
	await get_tree().create_timer(0.5).timeout
	survey._on_skip_button_pressed()

	await get_tree().create_timer(3).timeout

	if OS.has_feature('movie'):
		get_tree().quit()

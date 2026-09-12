extends Node2D

var _run: Run

func _ready() -> void:
	GlobalSaveGame.init_new_game(2)
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P300_STARTED_LEADERSHIP)
	GlobalSaveGame.unlock_skill(load('res://skills/settlement/skill_settlement_preview_bonuses.tres') as Skill)
	GlobalSaveGame.unlock_skill(load('res://skills/events/skill_events_preview.tres') as Skill)
	GlobalSaveGame.unlock_skill(load('res://skills/events/skill_events_extra.tres') as Skill)
	GlobalSaveGame.unlock_skill(load('res://skills/hauntings/skill_hauntings_preview.tres') as Skill)

	# Setup run.
	var RUN_SCENE := load('res://run/run.tscn') as PackedScene
	_run = RUN_SCENE.instantiate() as Run
	_run.run_config = RunConfig.new()
	_run.run_config.run_type = RunSetup.get_default_run_type()
	_run.run_config.starting_cards = SaveGame.get_starter_cards()
	_run.run_config.run_seed = 151
	_run.run_config.run_type.scaling_override = load('res://run/scaling/run_scaling.tres').duplicate()
	_run.run_config.run_type.scaling_override.haunting_probability = Curve.new()
	_run.run_config.run_type.scaling_override.haunting_probability.add_point(Vector2(0, 1.0), 0, 0)
	GlobalUI.add_layer_content(_run, UI.Layer.GAME)
	var map := _run.get_map()
	await map.cloud_generation_finished

	# Start stage selection.
	_run.set_state(RunData.State.STAGE_SELECTOR)

	await get_tree().create_timer(3).timeout
	Input.warp_mouse(Vector2(340, 420))
	await get_tree().create_timer(0.1).timeout
	(_run.get_current_scene() as StageSelector)._state = StageSelector.State.CONFIRMING
	await get_tree().create_timer(0.1).timeout

	Input.warp_mouse(Vector2(490, 350))
	await get_tree().create_timer(2).timeout

	Utils.take_screenshot(self, 'C:/users/max99/wutw/screenshots/map.png')

	await get_tree().process_frame
	get_tree().quit()

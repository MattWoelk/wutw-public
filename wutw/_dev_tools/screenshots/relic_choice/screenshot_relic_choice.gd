extends Node2D

func _ready() -> void:
	GlobalSaveGame.init_new_game(2)
	GlobalSaveGame.unlock_skill(load('res://skills/relics/skill_relics_starting_random.tres') as Skill)

	# Setup run.
	var RUN_SCENE := load('res://run/run.tscn') as PackedScene
	var run := RUN_SCENE.instantiate() as Run
	run.run_config = RunConfig.new()
	run.run_config.run_type = RunSetup.get_default_run_type()
	run.run_config.starting_cards = GlobalSaveGame.get_run_starting_deck()
	run.run_config.run_seed = 40
	add_child(run)
	await get_tree().process_frame

	await get_tree().create_timer(5).timeout

	Utils.take_screenshot(self, 'C:/users/max99/wutw/screenshots/relic_choice.png')

	await get_tree().process_frame

	get_tree().quit()

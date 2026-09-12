extends Node2D

var _run: Run

func _ready() -> void:
	GlobalSaveGame.init_new_game(2)
	GlobalSaveGame.unlock_skill(load('res://skills/relics/skill_relics_starting_random.tres') as Skill)

	# Setup run.
	var RUN_SCENE := load('res://run/run.tscn') as PackedScene
	_run = RUN_SCENE.instantiate() as Run
	_run.run_config = RunConfig.new()
	_run.run_config.run_type = RunSetup.get_default_run_type()
	_run.run_config.starting_cards = GlobalSaveGame.get_run_starting_deck()
	_run.run_config.run_seed = 40
	add_child(_run)
	await get_tree().process_frame

	await get_tree().create_timer(8).timeout
	get_tree().quit()

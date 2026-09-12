extends Node2D

@export var event: Event
@export var filename: String = 'event.png'

var _run: Run

func _ready() -> void:
	GlobalSaveGame.init_new_game(13)
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P510_FINISHED_OUTRO_CUTSCENE)
	event.mark_all_choices_seen()

	# Setup run.
	var RUN_SCENE := load('res://run/run.tscn') as PackedScene
	_run = RUN_SCENE.instantiate() as Run
	_run.run_config = RunConfig.new()
	_run.run_config.run_type = RunSetup.get_default_run_type()
	_run.run_config.starting_cards = GlobalSaveGame.get_run_starting_deck()
	_run.run_config.run_seed = 40
	GlobalUI.add_layer_content(_run, UI.Layer.GAME)
	while _run.get_state() != RunData.State.STAGE_SELECTOR:
		await get_tree().process_frame

	# Start stage.
	_run.debug_create_settlement(Vector2i(200, 110))
	_run.set_state(RunData.State.STAGE)
	add_bonus('harmony', 25)
	add_bonus('food', 5)
	add_bonus('safety', 110)
	add_bonus('productivity', 40)
	add_bonus('adventure', 30)
	add_bonus('knowledge', 10)
	add_bonus('beauty', 80)

	await get_tree().create_timer(2).timeout

	_run.queue_event(event)
	await get_tree().process_frame
	_run.get_current_event_scene().get_current_step_scene()._on_skip_button_pressed()

	await get_tree().create_timer(2).timeout

	Utils.take_screenshot(self, 'C:/users/max99/wutw/screenshots/' + filename)

	await get_tree().process_frame
	get_tree().quit()

func add_bonus(bonus_id: String, amount: int) -> void:
	_run.gain_bonus(BonusGain.new(BonusType.get_bonus_type_by_id(bonus_id), amount, GlobalConsoleCommands))

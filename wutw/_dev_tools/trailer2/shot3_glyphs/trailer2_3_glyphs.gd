extends Node2D

var _run: Run

func _ready() -> void:
	GlobalGameSettings.read_only = true
	GlobalGameSettings.Interface.animation_speed.set_value(1.3)
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
	_run.run_config.debug_map_seed = 9442
	add_child(_run)
	await get_tree().process_frame
	var map := _run.get_map()
	await map.cloud_generation_finished
	await get_tree().create_timer(1).timeout

	# Create settlement.
	const SETTLEMENT_LOCATION := Vector2i(295, 183)
	map.instant_focus_location(SETTLEMENT_LOCATION, 6.5)
	await get_tree().create_timer(0.5).timeout

	# Start stage.
	var settlement := _run.debug_create_settlement(SETTLEMENT_LOCATION)
	settlement.state.settlement_name = SettlementNameOption.new()
	settlement.state.settlement_name.name = 'Kokage Mura'
	settlement.state.goal.bonus_requirements = {
		load('res://bonuses/types/bonus_productivity.tres') as BonusType: 10
	}
	_run.get_vars().modify_base_value(RunVars.Var.MAX_EVENTS_PER_STAGE, 0)
	_run.get_vars().modify_base_value(RunVars.Var.HAND_SIZE, 6)
	_run.set_state(RunData.State.STAGE)
	await get_tree().process_frame

	# I prefer the upgrade path that happens with the productivity goal, but I
	# want the goal to be accomplished, so sneakily switch it here.
	settlement.state.goal.bonus_requirements = {
		load('res://bonuses/types/bonus_knowledge.tres') as BonusType: 10
	}
	_run.get_top_hud().get_stage_goal_tracker().goal = settlement.state.goal

	# Drag card to activate recipe.
	map.instant_focus_location(SETTLEMENT_LOCATION, 6.5)
	await get_tree().create_timer(2).timeout
	for card in _run.get_current_stage().get_card_deck().get_hand_cards():
		if card.card_type == load('res://cards/tier2/card_four.tres'):
			_run.get_current_stage().cast_card(card)
			await get_tree().create_timer(3).timeout
			break

	await settlement.reveal()

	await get_tree().create_timer(2).timeout

	if OS.has_feature('movie'):
		get_tree().quit()

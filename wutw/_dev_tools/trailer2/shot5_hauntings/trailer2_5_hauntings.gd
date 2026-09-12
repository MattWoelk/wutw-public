extends Node2D

var _run: Run

func _ready() -> void:
	GlobalGameSettings.read_only = true
	GlobalGameSettings.Interface.animation_speed.set_value(1.25)
	GameSettings.Interface.tooltip_speed.set_value(.001)
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P300_STARTED_LEADERSHIP)

	# Setup run.
	var RUN_SCENE := load('res://run/run.tscn') as PackedScene
	_run = RUN_SCENE.instantiate() as Run
	_run.run_config = RunConfig.new()
	_run.run_config.run_type = RunSetup.get_default_run_type()
	_run.run_config.run_type.scaling_override = load('res://run/scaling/run_scaling.tres').duplicate()
	_run.run_config.run_type.scaling_override.haunting_probability = Curve.new()
	_run.run_config.run_type.scaling_override.haunting_probability.add_point(Vector2(0, 1.0), 0, 0)
	_run.run_config.starting_cards = [
		load('res://cards/tier5/card_diligence.tres'),
		load('res://cards/tier2/card_forbid.tres'),
		load('res://cards/tier3/card_create.tres'),
		load('res://cards/tier3/card_blaze.tres'),
		load('res://cards/tier3/card_divinity.tres'),
		load('res://cards/tier4/card_ghost.tres'),
	]
	_run.run_config.run_seed = 12
	_run.run_config.debug_map_seed = 9446
	add_child(_run)
	await get_tree().process_frame
	var map := _run.get_map()
	await map.cloud_generation_finished
	await get_tree().create_timer(1).timeout

	add_bonus('harmony', 25)
	add_bonus('food', 65)
	add_bonus('safety', 20)
	add_bonus('productivity', 40)
	add_bonus('adventure', 30)
	add_bonus('knowledge', 10)
	add_bonus('beauty', 80)
	_run.add_relic(load('res://relics/common/old_coin/relic_old_coin.tres') as Relic)
	_run.add_relic(load('res://relics/rare/crystal_blossom/relic_crystal_blossom.tres') as Relic)
	_run.add_relic(load('res://relics/uncommon/glowing_ember/relic_glowing_ember.tres') as Relic)
	_run.add_relic(load('res://relics/common/spring_rune/relic_spring_rune.tres') as Relic)
	_run.add_relic(load('res://relics/common/moistened_sleeve/relic_moistened_sleeve.tres') as Relic)

	# Create settlement.
	const SETTLEMENT_LOCATION := Vector2i(295, 163)
	map.instant_focus_location(SETTLEMENT_LOCATION, 6.5)
	await get_tree().create_timer(0.5).timeout

	# Start stage.
	var settlement := _run.debug_create_settlement(SETTLEMENT_LOCATION)
	settlement.state.settlement_name = SettlementNameOption.new()
	settlement.state.settlement_name.name = 'Nukumori'
	settlement.state.goal.bonus_requirements = {
		load('res://bonuses/types/bonus_harmony.tres') as BonusType: 25,
		load('res://bonuses/types/bonus_adventure.tres') as BonusType: 15,
	}
	_run.get_vars().modify_base_value(RunVars.Var.MAX_EVENTS_PER_STAGE, 0)
	_run.get_vars().modify_base_value(RunVars.Var.HAND_SIZE, 6)
	_run.set_state(RunData.State.STAGE)

	await get_tree().create_timer(1).timeout

	# Cast card to trigger haunting.
	map.instant_focus_location(SETTLEMENT_LOCATION, 6.5)
	await get_tree().create_timer(1).timeout
	for card in _run.get_current_stage().get_card_deck().get_hand_cards():
		if card.card_type == load('res://cards/tier3/card_create.tres'):
			await _run.get_current_stage().cast_card(card)
			break

	await get_tree().create_timer(3).timeout

	if OS.has_feature('movie'):
		get_tree().quit()

func add_bonus(bonus_id: String, amount: int) -> void:
	_run.gain_bonus(BonusGain.new(BonusType.get_bonus_type_by_id(bonus_id), amount, GlobalConsoleCommands))

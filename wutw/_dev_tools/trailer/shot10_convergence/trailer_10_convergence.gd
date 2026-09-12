extends Node2D

var _run: Run

func _ready() -> void:
	GlobalSaveGame.init_new_game(13)
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P510_FINISHED_OUTRO_CUTSCENE)
	GlobalSaveGame.unlock_skill(load('res://skills/cards/skill_cards_hand_size_start.tres') as Skill)

	# Setup run.
	var RUN_SCENE := load('res://run/run.tscn') as PackedScene
	_run = RUN_SCENE.instantiate() as Run
	_run.run_config = RunConfig.new()
	_run.run_config.run_type = RunSetup.get_default_run_type()
	_run.run_config.starting_cards = [
		load('res://cards/tier2/card_three.tres'),
		load('res://cards/tier6/card_echo.tres'),
		load('res://cards/tier5/card_loop.tres'),
		load('res://cards/tier3/card_righteousness.tres'),
		load('res://cards/tier3/card_chat.tres'),
		load('res://cards/tier2/card_koto.tres'),
	]
	_run.run_config.run_seed = 1644
	GlobalUI.add_layer_content(_run, UI.Layer.GAME)
	var map := _run.get_map()
	await map.cloud_generation_finished

	add_bonus('harmony', 25)
	add_bonus('food', 65)
	add_bonus('safety', 20)
	add_bonus('productivity', 40)
	add_bonus('adventure', 30)
	add_bonus('knowledge', 10)
	add_bonus('beauty', 80)
	_run.add_relic(load('res://relics/common/old_coin/relic_old_coin.tres') as Relic)
	_run.add_relic(load('res://relics/common/ancient_bark/relic_ancient_bark.tres') as Relic)
	_run.add_relic(load('res://relics/common/dusty_mirror/relic_dusty_mirror.tres') as Relic)
	_run.add_relic(load('res://relics/common/glowing_ember/relic_glowing_ember.tres') as Relic)
	_run.add_relic(load('res://relics/common/spring_rune/relic_spring_rune.tres') as Relic)
	_run.add_relic(load('res://relics/common/moistened_sleeve/relic_moistened_sleeve.tres') as Relic)

	# Setup settlements.
	_run.get_map().instant_focus_location(Vector2(110, 80), 2.5)  # Make sure VFX are in view so they finish.
	await add_settlement(100, 70)
	await add_settlement(150, 55)
	await add_settlement(220, 45)

	# Start convergence.
	_run._current_capital = Run.CAPITAL_SCENE.instantiate_loaded_scene() as Capital
	_run._current_capital.map_location = Vector2i(160, 100)
	_run.get_map().add_map_object(_run._current_capital)
	_run.get_map().set_map_object_location(_run._current_capital, _run._current_capital.map_location)
	await _run._current_capital.reveal()
	_run.get_map().clear_all_fow()
	_run.set_state(RunData.State.HARMONIZATION)
	await get_tree().process_frame

	await get_tree().create_timer(1.5).timeout
	_run.get_map().instant_focus_location(Vector2(110, 80), 5.5)
	await get_tree().create_timer(0.25).timeout
	_run.get_map().focus_location(Vector2(170, 80), 5.5, 8.0)

	await get_tree().create_timer(8).timeout
	if OS.has_feature('movie'):
		get_tree().quit()

# Utilities

func add_settlement(x: int, y: int) -> void:
	const NUM_SPOTS := 4
	var settlement := _run.debug_create_settlement(
		Vector2i(x, y), 15 + _run.get_map().get_map_objects().size(), NUM_SPOTS, false)
	var settlement_names := (load('res://stage/settlement_names.tres') as SettlementNameSet).options
	settlement.state.settlement_name = settlement_names[_run.get_map().get_map_objects().size()]
	settlement.state.bonus_amounts = BonusAmounts.new()
	var bonus_type := StageSatisfiability.get_sorted_spot_bonuses(
			_run, settlement.state.spot_types[0], true)[0]
	var bonus_amount := _run.get_map().get_map_objects().size() * 15
	settlement.state.bonus_amounts.add_amount(bonus_type, bonus_amount)
	add_bonus(bonus_type.bonus_type_id, bonus_amount)
	_run.get_map().reveal_fow_tween(settlement.state.map_location, settlement.state.radius + 36)
	for spot_index in range(NUM_SPOTS):
		var upgrade := _run.get_goals_random().pick(settlement.state.spot_types[spot_index].upgrades) as SpotUpgrade
		while upgrade:
			settlement.activate_upgrade(spot_index, upgrade)
			upgrade = _run.get_goals_random().pick(upgrade.child_upgrades)
			await get_tree().create_timer(0.2).timeout
	settlement.reveal()

func add_card(card_name: String) -> void:
	_run.add_card_to_deck(CardType.get_card_type_by_name_or_symbol(card_name))

func add_bonus(bonus_id: String, amount: int) -> void:
	_run.gain_bonus(BonusGain.new(BonusType.get_bonus_type_by_id(bonus_id), amount, GlobalConsoleCommands))

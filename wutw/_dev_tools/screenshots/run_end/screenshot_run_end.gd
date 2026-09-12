extends Node2D

var _run: Run

func _ready() -> void:
	GlobalGameSettings.read_only = true
	GameSettings.Interface.tooltip_speed.set_value(.001)
	GlobalContextHighlight.enabled = false
	GlobalSaveGame.init_new_game(2)
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P300_STARTED_LEADERSHIP)
	GlobalSaveGame.unlock_skill(load('res://skills/cards/skill_cards_hand_size_start.tres') as Skill)

	var custom_cards: Array[CardType] = [
		load('res://cards/tier1/card_play_music.tres'),
		load('res://cards/tier2/card_purity.tres'),
		load('res://cards/tier2/card_poem.tres'),
		load('res://cards/tier3/card_drama.tres'),
		load('res://cards/tier5/card_festival.tres'),
		load('res://cards/tier2/card_acting.tres'),
	]

	# Setup run.
	var RUN_SCENE := load('res://run/run.tscn') as PackedScene
	_run = RUN_SCENE.instantiate() as Run
	_run.run_config = RunConfig.new()
	_run.run_config.run_type = RunSetup.get_default_run_type()
	_run.run_config.starting_cards = SaveGame.get_starter_cards() + custom_cards
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
	_run.add_relic(load('res://relics/common/starter_bead/relic_starter_bead.tres') as Relic)
	_run.add_relic(load('res://relics/common/tea_whisk/relic_tea_whisk.tres') as Relic)
	_run.add_relic(load('res://relics/common/mirror_ink/relic_mirror_ink.tres') as Relic)
	_run.add_relic(load('res://relics/common/chisel_fang/relic_chisel_fang.tres') as Relic)
	_run.add_relic(load('res://relics/rare/last_thread/relic_last_thread.tres') as Relic)

	# Setup settlements.
	await add_settlement(100, 70)
	await add_settlement(150, 55)
	await add_settlement(360, 100)
	await add_settlement(220, 45)
	await add_settlement(300, 85)
	await add_settlement(130, 150)

	# Start convergence.
	_run._current_capital = Run.CAPITAL_SCENE.instantiate_loaded_scene() as Capital
	_run._current_capital.map_location = Vector2i(160, 105)
	_run.get_map().add_map_object(_run._current_capital)
	_run.get_map().set_map_object_location(_run._current_capital, _run._current_capital.map_location)
	await _run._current_capital.reveal()
	_run.get_map().clear_all_fow()
	_run._data.current_season_index = 1
	_run._data.current_stage_index = 9
	_run._data.newly_seen_cards.append_array(custom_cards)
	_run._data.newly_seen_event_outcomes.append(load('res://events/generic/tea_ceremony/event_tea_ceremony_1.tres'))
	_run._data.newly_seen_hauntings.append(load('res://stage/hauntings/types/haunting_akashita.tres'))
	_run.grant_insights(370)
	_run.modify_inspiration(-13, Run.InspirationChangeReason.EVENT)
	_run.set_state(RunData.State.RUN_WON)
	await get_tree().process_frame

	await get_tree().create_timer(5.0).timeout

	Utils.take_screenshot(self, 'C:/users/max99/wutw/screenshots/run_end.png')

	await get_tree().process_frame
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

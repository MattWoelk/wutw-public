extends Node2D

var _run: Run

func _ready() -> void:
	GlobalGameSettings.read_only = true
	GlobalGameSettings.Interface.show_card_names.set_value(true)
	GlobalSaveGame.init_new_game(13)
	var dragon := Companion.get_companion_by_id('dragon')
	GlobalSaveGame.unlock_companion(dragon)
	GlobalSaveGame.set_current_companion(dragon)
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P510_FINISHED_OUTRO_CUTSCENE)
	GlobalSaveGame.unlock_skill(load('res://skills/cards/skill_cards_hand_size_start.tres') as Skill)
	GlobalSaveGame.unlock_skill(load('res://skills/capital/skill_capital_connect.tres') as Skill)
	GlobalSaveGame.unlock_skill(load('res://skills/capital/skill_capital_initial_provision.tres') as Skill)
	GlobalSaveGame.unlock_skill(load('res://skills/inspiration/skill_inspiration_max_1.tres') as Skill)
	GlobalSaveGame.unlock_skill(load('res://skills/inspiration/skill_inspiration_max_2.tres') as Skill)

	var custom_cards: Array[CardType] = [
		load('res://cards/tier2/card_bamboo.tres'),
		load('res://cards/tier4/card_illustration.tres'),
		load('res://cards/tier5/card_wildcard.tres'),
		load('res://cards/tier3/card_enlightenment.tres'),
		load('res://cards/tier3/card_bloom.tres'),
		load('res://cards/tier2/card_accumulate.tres'),
	]

	# Setup run.
	var RUN_SCENE := load('res://run/run.tscn') as PackedScene
	_run = RUN_SCENE.instantiate() as Run
	_run.run_config = RunConfig.new()
	_run.run_config.run_type = RunSetup.get_default_run_type()
	_run.run_config.starting_cards = SaveGame.get_starter_cards() + custom_cards
	_run.run_config.run_seed = 1644
	_run.run_config.companion = dragon
	GlobalUI.add_layer_content(_run, UI.Layer.GAME)
	var map := _run.get_map()
	await map.cloud_generation_finished

	add_bonus('harmony', 110)
	add_bonus('food', 80)
	add_bonus('safety', 33)
	add_bonus('productivity', 40)
	add_bonus('adventure', 15)
	add_bonus('knowledge', 45)
	add_bonus('beauty', 18)
	_run.add_relic(load('res://relics/common/oracle_bone/relic_oracle_bone.tres') as Relic)
	_run.add_relic(load('res://relics/common/roof_tile/relic_roof_tile.tres') as Relic)
	_run.add_relic(load('res://relics/common/soggy_acorn/relic_soggy_acorn.tres') as Relic)
	_run.add_relic(load('res://relics/common/stone_heart/relic_stone_heart.tres') as Relic)
	_run.add_relic(load('res://relics/common/jade_shard/relic_jade_shard.tres') as Relic)
	_run.add_relic(load('res://relics/common/golden_persimmon/relic_golden_persimmon.tres') as Relic)

	# Setup settlements.
	_run.get_map().instant_focus_location(Vector2(110, 80), 2.5)  # Make sure VFX are in view so they finish.
	await add_settlement(100, 70, 'knowledge', 1)
	await add_settlement(152, 59, 'food', 3)
	await add_settlement(210, 50, 'adventure', 0)

	# Start convergence.
	_run._current_capital = Run.CAPITAL_SCENE.instantiate_loaded_scene() as Capital
	_run._current_capital.map_location = Vector2i(160, 100)
	_run.get_map().add_map_object(_run._current_capital)
	_run.get_map().set_map_object_location(_run._current_capital, _run._current_capital.map_location)
	await _run._current_capital.reveal()
	_run.get_map().clear_all_fow()
	_run.set_state(RunData.State.HARMONIZATION)
	await get_tree().process_frame

	_run.get_settlements()[0].connect_to_capital()

	await get_tree().create_timer(2).timeout
	_run.get_map().instant_focus_location(Vector2(163, 87), 5.38)

	var deck := _run.get_current_stage().get_card_deck()
	await deck.discard_all()
	for card_type in custom_cards:
		await deck.add_card_to_hand(card_type, CardDeck.CardDrawReason.EVENT)
	await get_tree().process_frame

	await get_tree().create_timer(5.0).timeout  # Let any VFX advance.

	Utils.take_screenshot(self, 'C:/users/max99/wutw/screenshots/convergence.png')

	await get_tree().process_frame
	get_tree().quit()

# Utilities

func add_settlement(x: int, y: int, extra_bonus_id: String, num_rolls: int) -> void:
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
	settlement.state.bonus_amounts.add_amount(BonusType.get_bonus_type_by_id(extra_bonus_id), 80)
	add_bonus(extra_bonus_id, 80)
	_run.get_map().reveal_fow_tween(settlement.state.map_location, settlement.state.radius + 36)
	var random := _run.get_goals_random().snapshot()
	for _i in num_rolls:
		random.rand_bool()  # Tweak for preferred upgrades.
	for spot_index in range(NUM_SPOTS):
		var upgrade := random.pick(settlement.state.spot_types[spot_index].upgrades) as SpotUpgrade
		while upgrade:
			settlement.activate_upgrade(spot_index, upgrade)
			upgrade = random.pick(upgrade.child_upgrades)
			await get_tree().create_timer(0.2).timeout
	settlement.reveal()

func add_card(card_name: String) -> void:
	_run.add_card_to_deck(CardType.get_card_type_by_name_or_symbol(card_name))

func add_bonus(bonus_id: String, amount: int) -> void:
	_run.gain_bonus(BonusGain.new(BonusType.get_bonus_type_by_id(bonus_id), amount, GlobalConsoleCommands))

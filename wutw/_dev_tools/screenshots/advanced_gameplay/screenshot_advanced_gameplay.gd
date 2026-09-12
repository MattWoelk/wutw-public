extends Node2D

@export var activated_recipes: Array[SpotUpgrade]

func _ready() -> void:
	GlobalContextHighlight.enabled = false
	var snake := Companion.get_companion_by_id('snake')
	GlobalSaveGame.init_new_game(2)
	GlobalSaveGame.unlock_companion(snake)
	GlobalSaveGame.set_current_companion(snake)
	GlobalSaveGame.unlock_skill(load('res://skills/settlement/skill_settlement_nongoal.tres') as Skill)
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P300_STARTED_LEADERSHIP)

	var custom_cards: Array[CardType] = [
		load('res://cards/tier2/card_three.tres'),
		load('res://cards/tier6/card_echo.tres'),
		load('res://cards/tier5/card_loop.tres'),
		load('res://cards/tier3/card_righteousness.tres'),
		load('res://cards/tier3/card_chat.tres'),
		load('res://cards/tier2/card_koto.tres'),
		load('res://cards/tier6/card_wildcard.tres'),
	]

	# Setup run.
	var RUN_SCENE := load('res://run/run.tscn') as PackedScene
	var run := RUN_SCENE.instantiate() as Run
	run.run_config = RunConfig.new()
	run.run_config.run_type = RunSetup.get_default_run_type().duplicate()
	run.run_config.run_type.scaling_override = run.scaling.duplicate()
	run.run_config.run_type.scaling_override.haunting_probability = Curve.new()
	run.run_config.run_type.scaling_override.haunting_probability.add_point(Vector2(0, 0.3), 0, 0)
	run.run_config.starting_cards = SaveGame.get_starter_cards() + custom_cards
	run.run_config.companion = snake
	run.run_config.run_seed = 402
	run.run_config.debug_map_seed = 403
	GlobalUI.add_layer_content(run, UI.Layer.GAME)
	var map := run.get_map()
	await map.cloud_generation_finished

	# Start progress.
	run.modify_inspiration(-13, Run.InspirationChangeReason.EVENT)
	add_bonus(run, 'harmony', 330)
	add_bonus(run, 'food', 265)
	add_bonus(run, 'safety', 227)
	add_bonus(run, 'productivity', 45)
	add_bonus(run, 'adventure', 125)
	add_bonus(run, 'knowledge', 110)
	add_bonus(run, 'beauty', 480)
	run.add_relic(load('res://relics/common/jade_shard/relic_jade_shard.tres') as Relic)
	run.add_relic(load('res://relics/common/tea_whisk/relic_tea_whisk.tres') as Relic)
	run.add_relic(load('res://relics/common/dusty_mirror/relic_dusty_mirror.tres') as Relic)
	run.add_relic(load('res://relics/common/glowing_ember/relic_glowing_ember.tres') as Relic)
	run.add_relic(load('res://relics/common/spring_rune/relic_spring_rune.tres') as Relic)
	run.add_relic(load('res://relics/rare/last_thread/relic_last_thread.tres') as Relic)
	run.add_relic(load('res://relics/common/leaky_inkstick/relic_leaky_inkstick.tres') as Relic)

	# Start stage.
	run.debug_create_settlement(Vector2i(340, 150), 30, 3)
	run.set_state(RunData.State.STAGE)
	await get_tree().process_frame

	map.instant_focus_location(run._current_settlement.state.map_location, 5.5)
	(run.get_current_stage().get_node('%ShowAllToggle') as Button).button_pressed = true
	run._current_settlement.state.goal.bonus_requirements = {
		BonusType.get_bonus_type_by_id('knowledge'): 30,
		BonusType.get_bonus_type_by_id('food'): 55,
	}
	run.get_current_stage()._goal_tracker.goal = run._current_settlement.state.goal
	run.get_current_stage()._on_show_all_toggle_pressed()

	await get_tree().create_timer(0.5).timeout

	# Activate a bunch of recipes.
	while not activated_recipes.is_empty():
		for spot in run.get_current_stage().get_spots():
			for recipe in spot.get_all_recipes():
				if recipe.spot_upgrade in activated_recipes and recipe.state == SpotRecipe.State.AVAILABLE:
					for slot in recipe.get_aspect_slots():
						slot.animate_fill()
					activated_recipes.erase(recipe.spot_upgrade)
		await get_tree().create_timer(0.25).timeout
	await get_tree().create_timer(2.0).timeout

	var deck := run.get_current_stage().get_card_deck()
	await deck.discard_all()
	for card_type in custom_cards:
		await deck.add_card_to_hand(card_type, CardDeck.CardDrawReason.EVENT)

	run.get_current_stage()._hauntings[0].haunting_type = load('res://stage/hauntings/types/haunting_koto_furunushi.tres')

	await get_tree().create_timer(1.0).timeout
	Input.warp_mouse(Vector2(1830, 850))

	await get_tree().create_timer(2.0).timeout

	Utils.take_screenshot(self, 'C:/users/max99/wutw/screenshots/advanced_gameplay.png')

	await get_tree().process_frame
	get_tree().quit()

func add_bonus(run: Run, bonus_id: String, amount: int) -> void:
	run.gain_bonus(BonusGain.new(BonusType.get_bonus_type_by_id(bonus_id), amount, GlobalConsoleCommands))

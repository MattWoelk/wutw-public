extends Node2D

@export var activated_recipes: Array[SpotUpgrade]

func _ready() -> void:
	GlobalGameSettings.read_only = true
	GameSettings.Interface.tooltip_speed.set_value(.001)
	GlobalContextHighlight.enabled = false
	GlobalSaveGame.init_new_game(2)
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P300_STARTED_LEADERSHIP)

	# Setup run.
	var RUN_SCENE := load('res://run/run.tscn') as PackedScene
	var run := RUN_SCENE.instantiate() as Run
	run.run_config = RunConfig.new()
	run.run_config.run_type = RunSetup.get_default_run_type()
	run.run_config.starting_cards = GlobalSaveGame.get_run_starting_deck()
	run.run_config.run_seed = 12
	GlobalUI.add_layer_content(run, UI.Layer.GAME)
	var map := run.get_map()
	await map.cloud_generation_finished

	# Start stage.
	run.debug_create_settlement(Vector2i(90, 70))
	run.set_state(RunData.State.STAGE)
	await get_tree().process_frame

	while not activated_recipes.is_empty():
		for spot in run.get_current_stage().get_spots():
			for recipe in spot.get_all_recipes():
				if recipe.spot_upgrade in activated_recipes and recipe.state == SpotRecipe.State.AVAILABLE:
					for slot in recipe.get_aspect_slots():
						slot.animate_fill()
					activated_recipes.erase(recipe.spot_upgrade)
		await get_tree().create_timer(0.25).timeout
	await get_tree().create_timer(3.0).timeout

	map.instant_focus_location(run._current_settlement.state.map_location + Vector2(10, -18), map.max_zoom)
	await get_tree().create_timer(3.0).timeout
	var card := run.get_current_stage().get_card_deck().get_hand_cards()[-1]
	card.is_selected = true
	card.drag_started.emit()
	Input.warp_mouse(Vector2(1320, 190))

	await get_tree().create_timer(1.0).timeout

	Utils.take_screenshot(self, 'C:/users/max99/wutw/screenshots/core_gameplay.png')

	await get_tree().process_frame
	get_tree().quit()

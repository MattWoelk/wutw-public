extends Node2D

@export var activated_recipes: Array[SpotUpgrade]

var _run: Run

func _ready() -> void:
	GlobalGameSettings.read_only = true
	GameSettings.Interface.tooltip_speed.set_value(.001)
	GlobalContextHighlight.enabled = false
	GlobalSaveGame.init_new_game(13)
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P510_FINISHED_OUTRO_CUTSCENE)
	var cat := Companion.get_companion_by_id('cat')
	GlobalSaveGame.unlock_companion(cat)
	GlobalSaveGame.set_current_companion(cat)

	# Setup run.
	var RUN_SCENE := load('res://run/run.tscn') as PackedScene
	_run = RUN_SCENE.instantiate() as Run
	_run.run_config = RunConfig.new()
	_run.run_config.run_type = RunSetup.get_default_run_type()
	_run.run_config.starting_cards = GlobalSaveGame.get_run_starting_deck()
	_run.run_config.companion = cat
	_run.run_config.run_seed = 40
	GlobalUI.add_layer_content(_run, UI.Layer.GAME)
	var map := _run.get_map()
	await map.cloud_generation_finished

	# Start stage.
	var settlement := _run.debug_create_settlement(Vector2i(320, 110))
	settlement.state.goal.bonus_requirements = {
		load('res://bonuses/types/bonus_productivity.tres') as BonusType: 20,
		load('res://bonuses/types/bonus_adventure.tres') as BonusType: 35,
	}
	_run.set_state(RunData.State.STAGE)
	await get_tree().create_timer(1.0).timeout

	# Activate a bunch of recipes.
	while not activated_recipes.is_empty():
		for spot in _run.get_current_stage().get_spots():
			for recipe in spot.get_all_recipes():
				if recipe.spot_upgrade in activated_recipes and recipe.state == SpotRecipe.State.AVAILABLE:
					for slot in recipe.get_aspect_slots():
						slot.animate_fill()
					activated_recipes.erase(recipe.spot_upgrade)
		await get_tree().create_timer(0.25).timeout
	await get_tree().create_timer(3.0).timeout

	# Drag card to activate companion ability.
	Input.warp_mouse(Vector2(1150, 960))
	var card := _run.get_current_stage().get_card_deck().get_hand_cards()[-1]
	card.is_selected = true
	card.drag_started.emit()
	var drag_tween := create_tween()
	drag_tween.set_ease(Tween.EaseType.EASE_OUT)
	drag_tween.set_trans(Tween.TRANS_CUBIC)
	drag_tween.tween_method(Input.warp_mouse, Vector2(1150, 960), Vector2(1830, 850), 1.3)
	drag_tween.play()

	await drag_tween.finished
	var companion_recipe := _run.get_current_stage().get_node('%CompanionPanel').get_child(0) as CompanionRecipe
	var slot := SlotUtils.match_slot(companion_recipe.get_aspect_slots(), card.card_type.aspects)
	_run.get_current_stage()._on_card_dropped_on_slot(card, slot)
	card.drag_ended.emit()

	await get_tree().create_timer(3.5).timeout
	if OS.has_feature('movie'):
		get_tree().quit()

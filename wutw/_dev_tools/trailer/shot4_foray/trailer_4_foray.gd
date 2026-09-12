extends Node2D

var _run: Run

func _ready() -> void:
	GlobalGameSettings.read_only = true
	GameSettings.Interface.tooltip_speed.set_value(.001)
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P510_FINISHED_OUTRO_CUTSCENE)

	# Setup run.
	var RUN_SCENE := load('res://run/run.tscn') as PackedScene
	_run = RUN_SCENE.instantiate() as Run
	_run.run_config = RunConfig.new()
	_run.run_config.run_type = RunSetup.get_default_run_type()
	_run.run_config.starting_cards = GlobalSaveGame.get_run_starting_deck()
	_run.run_config.run_seed = 12
	_run.run_config.debug_map_seed = 9441
	add_child(_run)
	await get_tree().process_frame
	var map := _run.get_map()
	await map.cloud_generation_finished
	await get_tree().create_timer(1).timeout

	# Create settlement.
	const SETTLEMENT_LOCATION := Vector2i(335, 133)
	map.instant_focus_location(SETTLEMENT_LOCATION, 6.5)
	await get_tree().create_timer(0.5).timeout

	# Start stage.
	_run.get_vars().modify_base_value(RunVars.Var.REDRAWS, -1)
	var settlement := _run.debug_create_settlement(SETTLEMENT_LOCATION)
	settlement.state.settlement_name = SettlementNameOption.new()
	settlement.state.settlement_name.name = 'Shigure'
	settlement.state.goal.bonus_requirements = {
		load('res://bonuses/types/bonus_productivity.tres') as BonusType: 10
	}
	_run.set_state(RunData.State.STAGE)
	await get_tree().process_frame

	# Drag card to activate recipe.
	map.instant_focus_location(SETTLEMENT_LOCATION, 6.5)
	await get_tree().create_timer(2).timeout
	Input.warp_mouse(Vector2(1100, 960))
	var card := _run.get_current_stage().get_card_deck().get_hand_cards()[-1]
	card.is_selected = true
	card.drag_started.emit()
	var drag_tween := create_tween()
	drag_tween.set_ease(Tween.EaseType.EASE_OUT)
	drag_tween.set_trans(Tween.TRANS_CUBIC)
	drag_tween.tween_method(Input.warp_mouse, Vector2(1100, 960), Vector2(1340, 190), 1.0)
	drag_tween.play()
	await drag_tween.finished
	var slot := SlotUtils.match_slot(_run.get_current_stage()._spots[-1].get_all_aspect_slots(),
								 card.card_type.aspects)
	_run.get_current_stage()._on_card_dropped_on_slot(card, slot)
	card.drag_ended.emit()

	await get_tree().create_timer(1.4).timeout
	await settlement.reveal()
	# Alternatively, to fade out stage UI:
	#(_run.get_current_stage().get_node('%FinishButton') as Button).pressed.emit()
	#await _run.state_changed
	#(_run.get_current_scene() as Node2D).visible = false

	await get_tree().create_timer(3).timeout

	if OS.has_feature('movie'):
		get_tree().quit()

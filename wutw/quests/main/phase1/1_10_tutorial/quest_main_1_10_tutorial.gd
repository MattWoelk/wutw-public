@tool
class_name Quest_Main110_Tutorial
extends Quest

static var STATIC_TUTORIAL_TOOLTIP_SCENE := AsyncLoadedResource.new('res://tutorial/static_tutorial_tooltip.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var TUTORIAL_ARROW_SCENE := AsyncLoadedResource.new('res://tutorial/tutorial_arrow.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var initial_card_rewards: Array[CardType]
@export var begin_dialogue: Dialogue
@export var end_dialogue: Dialogue
@export var next_quest: Quest
@export_multiline var first_foray_tutorial_text: String
@export_multiline var first_foray_tutorial_text_steam_deck: String
@export_multiline var end_foray_tutorial_text: String
@export_multiline var end_foray_tutorial_text_steam_deck: String
@export_multiline var stage_selector_tutorial_text: String
@export_multiline var stage_selector_tutorial_text_steam_deck: String
@export_multiline var inspiration_tutorial_text: String
@export_multiline var bonus_listing_tutorial_text: String
@export_multiline var third_foray_tutorial_text: String

var _cur_hints: Array[Tooltip]
var _arrows: Array[TutorialArrow]

func on_run_entered(instance: QuestInstance, run: Run) -> void:
	if instance.is_active():
		_setup_arrow_listener()
	run.state_changed.connect(_on_run_state_changed.bind(instance, run))
	_on_run_state_changed(instance, run)

func on_run_exited(instance: QuestInstance, run: Run) -> void:
	if instance.is_active():
		_cleanup_arrow_listener()
	run.state_changed.disconnect(_on_run_state_changed.bind(instance, run))

func _on_run_state_changed(instance: QuestInstance, run: Run) -> void:
	assert(instance)

	var num_settlements := run.get_settlements().size()

	if run.get_state() != RunData.State.STAGE_SELECTOR:
		for arrow in _arrows:
			arrow.remove()
		_arrows.clear()
		if run.get_state() in [RunData.State.RUN_LOST, RunData.State.RUN_WON]:
			_cleanup_arrow_listener()

		if run.get_state() == RunData.State.STAGE_CARD_REWARD and num_settlements == 1:
			# Rig the first card reward.
			var card_reward_choice := run.get_current_scene() as CardRewardChoice
			var choices := card_reward_choice.get_node('%Choices').get_children()
			if Utils.ensure(choices.size() == 3 and choices[0] is Card):
				for i in choices.size():
					(choices[i] as Card).card_type = initial_card_rewards[i]
		elif run.get_state() == RunData.State.STAGE_CARD_REWARD and num_settlements == 2:
			# Skip the second card reward.
			var card_reward_choice := run.get_current_scene() as CardRewardChoice
			card_reward_choice.selection_finished.emit()

		return

	var stage_selector := run.get_current_scene() as StageSelector
	(stage_selector.get_node('%TitleLabel') as Control).visible = false
	if num_settlements == 0:
		stage_selector.visible = false
		await GlobalUI.show_dialogue(begin_dialogue)
		if stage_selector._stage_location_target:
			stage_selector._stage_location_target.visible = false

		# Auto-start first foray.
		stage_selector.location_selected.emit(run.get_map().generated_map.starting_point)

		# Wait for stage to be activated.
		while not run.get_current_stage():
			await run.get_tree().process_frame

		# We still haven't introduced inspiration or goals, so hide and auto-fulfill them, respectively.
		# We don't simply remove the goals, so that the upgrade tree is filtered to a manageable size.
		var reqs := run.get_current_stage_goal().bonus_requirements
		var stage := Utils.get_active_run().get_current_stage()
		run.gain_bonus(BonusGain.new(reqs.keys()[0] as BonusType, reqs.values()[0] as int, GlobalConsoleCommands))

		# Show basic foray tutorial.
		var anchor := stage.get_card_deck().get_node('%HandList') as Control
		var tooltip_text := tr(first_foray_tutorial_text)
		if Utils.is_steam_deck():
			tooltip_text = tr(first_foray_tutorial_text_steam_deck)
		_show_hint(anchor, tooltip_text, 40)
		run.signals.redraw_started.connect(func(_is_first: bool) -> void:
			_clear_hints()
			var tooltip_text2 := tr(end_foray_tutorial_text)
			if Utils.is_steam_deck():
				tooltip_text2 = tr(stage_selector_tutorial_text_steam_deck)
			_show_hint(stage.get_node('%FinishButton') as Control, tooltip_text2, 40)
		, CONNECT_ONE_SHOT)
		stage.finish_button_pressed.connect(_clear_hints)
	elif num_settlements == 1:
		instance.set_goal_finished(0)
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P105_SETTLED_ONCE)

		run.get_top_hud().visible = true
		run.get_inspiration_display().visible = false
		run.get_run_bonus_listing().visible = false

		var anchor := run.get_stage_goal_tracker()
		var reqs := run.get_current_stage_goal().bonus_requirements
		# Prompt to choose a location. Will be auto-removed when the stage starts.
		var goal_parts: Array[String]
		for req in reqs:
			goal_parts.append('%d %s' % [reqs[req], (req as BonusType).get_term_tag()])
		var tooltip_text := tr(stage_selector_tutorial_text)
		if Utils.is_steam_deck():
			tooltip_text = tr(stage_selector_tutorial_text_steam_deck)
		_show_hint(anchor, tooltip_text % Utils.format_conjunction(goal_parts))

		# Wait for stage to be activated.
		while not run.get_current_stage():
			await run.get_tree().process_frame

		_clear_hints()

		# Resize the spots scroller to avoid intersecting the hints.
		var spots_scroller := run.get_current_stage().get_node('%SpotsScroller') as Control
		spots_scroller.size.x = 1300
		spots_scroller.position.x = 325

		# Enable inspiration and bonuses and show their tutorials. Will be auto-removed when the stage is finished.
		run.get_inspiration_display().visible = true
		run.get_run_bonus_listing().visible = true

		# Wait for the "save" message to fade out.
		await run.get_tree().create_timer(1.0).timeout
		_show_hint(run.get_inspiration_display(), tr(inspiration_tutorial_text))
		_show_hint(run.get_run_bonus_listing(), tr(bonus_listing_tutorial_text))

		run.get_current_stage().finish_button_pressed.connect(_clear_hints)
	elif num_settlements == 2:
		assert(GlobalSaveGame.get_main_quest_progress() == SaveGame.MainQuestProgress.P105_SETTLED_ONCE)
		_clear_hints()

		run.grant_insights(40 - run.get_total_insights_gained())  # Guarantee enough insights for multiple skill options.
		stage_selector.set_force_end()

		await GlobalUI.show_dialogue(end_dialogue)
		instance.finish(next_quest, false)
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P110_COMPLETED_TUTORIAL)

		# Show the End Expedition tutorial. Will be auto-removed at run end (which you are forced into).
		_show_hint(stage_selector.get_node('%EndRunButton') as Control, third_foray_tutorial_text)

func _show_hint(anchor: Control, text: String, margin: int = 0) -> void:
	var hint := Tooltip.create(
			anchor, text,
			[Tooltip.RelativeDirection.ABOVE, Tooltip.RelativeDirection.BELOW],
			[Tooltip.Alignment.CENTERED],
			null, STATIC_TUTORIAL_TOOLTIP_SCENE.get_loaded_scene())
	hint.margin = margin
	hint.show_tooltip()
	_cur_hints.append(hint)

func _clear_hints() -> void:
	for hint in _cur_hints:
		hint.hide_tooltip()
	_cur_hints.clear()

func _setup_arrow_listener() -> void:
	GlobalContextHighlight.request_changed.connect(_handle_context_request)

func _cleanup_arrow_listener() -> void:
	GlobalContextHighlight.request_changed.disconnect(_handle_context_request)

func _handle_context_request(requested: ContextHighlight.Context) -> void:
	for arrow in _arrows:
		arrow.remove()
	_arrows.clear()
	if not requested:
		return

	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	if load('res://glossary/terms/standalone/term_spot.tres') in requested.terms:
		for spot in stage.get_spots():
			_add_tutorial_arrow(spot, TutorialArrow.RelativeDirection.BELOW)
	if load('res://glossary/terms/standalone/term_spot_upgrade.tres') in requested.terms:
		for spot in stage.get_spots():
			for recipe in spot.get_all_recipes():
				if recipe.is_visible_in_tree():
					_add_tutorial_arrow(recipe, TutorialArrow.RelativeDirection.LEFT)
	if load('res://glossary/terms/standalone/term_stage_goal.tres') in requested.terms:
		var goal_tracker := run.get_stage_goal_tracker()
		if stage:
			_add_tutorial_arrow(goal_tracker, TutorialArrow.RelativeDirection.BELOW)
		else:
			_add_tutorial_arrow(goal_tracker, TutorialArrow.RelativeDirection.RIGHT)
	if load('res://glossary/terms/standalone/term_inspiration.tres') in requested.terms:
		_add_tutorial_arrow(Utils.get_active_run().get_inspiration_display().get_child(0) as Control,
			TutorialArrow.RelativeDirection.RIGHT)

func _add_tutorial_arrow(target: Control, direction: TutorialArrow.RelativeDirection) -> void:
	var arrow := TUTORIAL_ARROW_SCENE.instantiate_loaded_scene() as TutorialArrow
	arrow.direction = direction
	arrow.target = target
	arrow.z_index = Utils.get_absolute_z_index(target) + UI.LAYER_SPACING - 1
	target.get_tree().root.add_child(arrow)
	_arrows.append(arrow)

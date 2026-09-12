class_name StarterTutorial
extends Node2D

const TIME_PER_CHAR := 0.035
const DIALOGUE_TEXT_SPEED := 3.0
static var STATIC_TUTORIAL_TOOLTIP_SCENE := AsyncLoadedResource.new('res://tutorial/static_tutorial_tooltip.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var TUTORIAL_ARROW_SCENE := AsyncLoadedResource.new('res://tutorial/tutorial_arrow.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var INITIAL_QUEST := AsyncLoadedResource.new('res://quests/main/phase1/1_10_tutorial/quest_main_1_10_tutorial.tres', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export_multiline var line_start: String
@export_multiline var line_redraw: String
@export_multiline var line_open: String
@export_multiline var line_opened: String
@export_multiline var line_gathered: String
@export var tutorial_cards: Array[CardType]

@onready var _anim_player := %AnimationPlayer as AnimationPlayer
@onready var _speech_label := %SpeechLabel as Label
var _arrow_hint_tween: Tween
var _dialogue_tween: Tween
var _hint_tooltip: Tooltip
var _sfx_playing_id: int = 0

var _end_turn_arrow: TutorialArrow
var _recipe_arrows: Array[TutorialArrow]
var _slot_arrows: Array[TutorialArrow]
var _card_arrows: Array[TutorialArrow]
var _aspect_arrows: Array[TutorialArrow]
var _invocation_arrows: Array[TutorialArrow]

func _ready() -> void:
	UI.register_zoomable(%DialogueBox as Control, 0.3, 0.5)

func _exit_tree() -> void:
	_stop_sfx()

func start() -> void:
	var run := Utils.get_active_run()
	run.get_top_hud().visible = false
	run.get_current_stage().add_modifier(RunVars.Var.SHIELD, 10)
	run.signals.card_slotted.connect(_on_card_played)
	run.signals.redraw_started.connect(_on_redraw_started)
	run.signals.redraw_finished.connect(_on_redraw_finished)

	(%TransitionTex as Control).material = (%TransitionTex as Control).material.duplicate()
	((%TransitionTex as Control).material as ShaderMaterial).set_shader_parameter('progress', 0)
	_speech_label.text = ''
	_anim_player.play('clear', -1, Utils.anim_speed())
	await _anim_player.animation_finished

	await get_tree().create_timer(Utils.anim_duration(1.5)).timeout  # Wait for transition anim.

	_anim_player.play('start', -1, Utils.anim_speed())
	await _anim_player.animation_finished
	await _show_dialogue(tr(line_start))

	_anim_player.play('show_first_recipe', -1, Utils.anim_speed())
	await _anim_player.animation_finished

	GlobalContextHighlight.request_changed.connect(_handle_context_request)

	# Stage will run the initial draw after this method returns.

func get_recipes() -> Array[GenericRecipe]:
	return [%Recipe_Gate, %Recipe_OpenPortal, %Recipe_Expedition, %Recipe_Embark]

func animate_transition() -> void:
	_show_hint(null, '')
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	stage.get_finish_button().visible = false
	_end_turn_arrow.remove()
	_end_turn_arrow = null

	for child in get_children():
		if child is Control:
			Utils.set_input_enabled(child as Control, false)

	(%TransitionTex as Control).visible = true
	var mat := ((%TransitionTex as Control).material as ShaderMaterial)
	var set_mat_progress := func(t: float) -> void: mat.set_shader_parameter('progress', t)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_method(set_mat_progress, 0.0, 0.5, 1.0)
	tween.tween_property(self, 'modulate:a', 2.0 / 255.0, 0.01)
	tween.tween_method(set_mat_progress, 0.5, 1.0, 0.75)
	tween.tween_property(self, 'modulate:a', 0, 0.01)
	tween.set_speed_scale(Utils.anim_speed())
	tween.play()
	GlobalAudioSystem.play(AK.EVENTS.SFX_TRANSITION_SWIRL)
	await tween.finished

func _on_card_played(_card: Card, _aspect_slot: AspectSlot) -> void:
	(%HintArrow as BrushstrokeArrow).card = null
	_arrow_hint_tween.kill()
	_arrow_hint_tween = null
	var run := Utils.get_active_run()
	run.signals.card_slotted.disconnect(_on_card_played)

func _on_redraw_started(is_first: bool) -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	stage.get_finish_button().visible = false
	if is_first:
		stage.get_card_deck().set_draw_deck_cards(tutorial_cards)
	else:
		_end_turn_arrow.remove()
		_end_turn_arrow = null
		_show_hint(null, '')

func _on_redraw_finished(is_first: bool) -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	var deck := stage.get_card_deck()
	if is_first:
		var card := deck.get_hand_cards()[-1]
		var slot := (%Recipe_Gate as GenericRecipe).get_aspect_slots()[0]
		Utils.ensure(card.card_type.aspects[0] == slot.aspect_type)
		(%HintArrow as BrushstrokeArrow).card = card
		_arrow_hint_tween = create_tween()
		_arrow_hint_tween.tween_property(%HintArrow, 'target_override', card.get_global_rect().get_center(), 0.01)
		_arrow_hint_tween.tween_property(%HintArrow, 'target_override', slot.global_position, 2.0)
		_arrow_hint_tween.parallel().tween_property(%HintArrow, 'modulate:a', 1, .1)
		_arrow_hint_tween.parallel().tween_property(%HintArrow, 'modulate:a', 0, .5).set_delay(1.5)
		_arrow_hint_tween.set_loops()
		_arrow_hint_tween.play()
		_show_hint(_get_hand_list(), tr('Drag <term:glyph>s to <term:aspect_slot>s with a matching <term:aspect> to activate the <term:spot_upgrade>.'), 50)
	else:
		await _show_dialogue(tr(line_open))
		_show_hint(_get_hand_list(), tr('A <term:glyph> with multiple <term_lower:aspect>s can <term_lower:fill> any matching <term_lower:aspect_slot>, but a single glyph can only fill one slot.'), 50)

func _on_recipe_gate_activated() -> void:
	_show_hint(null, '')
	(%Recipe_OpenPortal as GenericRecipe).state = GenericRecipe.State.AVAILABLE

	_anim_player.play('build_gate', -1, Utils.anim_speed())
	await _anim_player.animation_finished
	await _show_dialogue(tr(line_redraw))

	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	stage.get_finish_button().visible = true

	_show_hint(stage.get_finish_button(), tr('You can <term_lower:redraw> your <term_lower:hand> once.'))
	_end_turn_arrow = _add_tutorial_arrow(stage.get_finish_button(), TutorialArrow.RelativeDirection.LEFT)

func _on_recipe_open_portal_activated() -> void:
	_show_hint(null, '')
	(%Recipe_Expedition as GenericRecipe).state = GenericRecipe.State.AVAILABLE
	GlobalAudioSystem.play(AK.EVENTS.SFX_TRANSITION_SWIRL)
	_anim_player.play('open_gateway', -1, Utils.anim_speed())
	await _anim_player.animation_finished
	await _show_dialogue(tr(line_opened))

func _on_recipe_expedition_activated() -> void:
	(%Recipe_Embark as GenericRecipe).state = GenericRecipe.State.AVAILABLE
	_anim_player.play('gather_people', -1, Utils.anim_speed())
	await _anim_player.animation_finished
	await _show_dialogue(tr(line_gathered))
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P101_CASTING_ENABLED)
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	for card in stage.get_card_deck().get_hand_cards():
		card.card_type = card.card_type  # Trigger recreate() to show abilities.
	_show_hint(_get_hand_list(), tr('''<term:glyph>s have <term_lower:card_ability>s. Hover the <term_lower:glyph> to learn more.

%s the <term_lower:glyph> to cast all of its <term_lower:card_ability>s.''') %
					InputPrompts.get_input_markup(InputPrompts.InputType.RIGHT_CLICK), 85)

func _on_recipe_embark_activated() -> void:
	_show_hint(null, '')

	_anim_player.play('finish', -1, Utils.anim_speed())
	await _anim_player.animation_finished

	var run := Utils.get_active_run()
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P102_COMPLETED_STARTER_TUTORIAL)
	var quest := INITIAL_QUEST.get_loaded() as Quest
	# Instantiating as already started to avoid showing the quest announcement.
	var quest_instance := quest.instantiate(QuestInstance.STATE_ACTIVE)
	GlobalSaveGame.add_quest_instance(quest_instance)

	var stage := run.get_current_stage()
	stage.get_finish_button().text = tr('Start Expedition')
	stage.get_finish_button().visible = true
	_show_hint(stage.get_finish_button(), tr('You are now ready to start your first <term:run>!'))
	_end_turn_arrow = _add_tutorial_arrow(stage.get_finish_button(), TutorialArrow.RelativeDirection.LEFT)

func _show_dialogue(text: String) -> void:
	(%SkipButton as Button).visible = true
	_dialogue_tween = create_tween()
	if _speech_label.text:
		_dialogue_tween.tween_property(_speech_label, 'modulate:a', 0, 0.3)
	_dialogue_tween.tween_callback(func() -> void:
		_speech_label.text = text
		_speech_label.visible_ratio = 0
		_speech_label.modulate.a = 1
	)
	_dialogue_tween.tween_property(_speech_label, 'visible_ratio', 1.0, text.length() * TIME_PER_CHAR)
	_dialogue_tween.set_speed_scale(Utils.anim_speed())
	_dialogue_tween.play()
	_start_sfx()
	await _dialogue_tween.finished
	_stop_sfx()
	(%SkipButton as Button).visible = false
	_dialogue_tween = null

func _show_hint(anchor: Control, text: String, margin: int = 20) -> void:
	if _hint_tooltip:
		await _hint_tooltip.hide_tooltip()
		_hint_tooltip.destroy()
		_hint_tooltip = null
	if text:
		_hint_tooltip = Tooltip.create(
				anchor, text, [Tooltip.RelativeDirection.ABOVE],
				[Tooltip.Alignment.CENTERED, Tooltip.Alignment.END], null,
				STATIC_TUTORIAL_TOOLTIP_SCENE.get_loaded_scene(), false)
		_hint_tooltip.margin = margin
		_hint_tooltip.z_index = Utils.get_absolute_z_index(anchor) + UI.LAYER_SPACING
		add_child(_hint_tooltip)  # Instead of root, so that menus block hovers.
		_hint_tooltip.show_tooltip()

func _start_sfx() -> void:
	_stop_sfx()
	GlobalAudioSystem.set_parameter(AK.GAME_PARAMETERS.TEXT_SPEED, DIALOGUE_TEXT_SPEED)
	_sfx_playing_id = GlobalAudioSystem.start_loop(AK.EVENTS.UI_DIALOGUE_TEXT_LOOP)

func _stop_sfx() -> void:
	if _sfx_playing_id:
		GlobalAudioSystem.stop_loop(_sfx_playing_id)
		_sfx_playing_id = 0

func _get_hand_list() -> Control:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	return stage.get_card_deck().get_node('%HandList') as Control

func _on_skip_button_pressed() -> void:
	if _dialogue_tween:
		_dialogue_tween.set_speed_scale(100.0)

func _add_tutorial_arrow(target: Control, direction: TutorialArrow.RelativeDirection) -> TutorialArrow:
	var result := TUTORIAL_ARROW_SCENE.instantiate_loaded_scene() as TutorialArrow
	result.direction = direction
	result.target = target
	result.z_index = Utils.get_absolute_z_index(target) + UI.LAYER_SPACING - 1
	get_tree().root.add_child(result)
	return result

func _handle_context_request(requested: ContextHighlight.Context) -> void:
	if requested and load('res://glossary/terms/standalone/term_spot_upgrade.tres') in requested.terms:
		_recipe_arrows = [
			_add_tutorial_arrow(%Recipe_Gate as Control, TutorialArrow.RelativeDirection.LEFT),
			_add_tutorial_arrow(%Recipe_OpenPortal as Control, TutorialArrow.RelativeDirection.LEFT),
		]
	else:
		for arrow in _recipe_arrows:
			arrow.remove()
		_recipe_arrows.clear()

	if requested and load('res://glossary/terms/standalone/term_aspect_slot.tres') in requested.terms:
		if not Utils.ensure(_slot_arrows.is_empty()):
			for arrow in _slot_arrows:
				arrow.remove()
			_slot_arrows.clear()
		for slot in (%Recipe_Gate as GenericRecipe).get_aspect_slots():
			_slot_arrows.append(_add_tutorial_arrow(slot, TutorialArrow.RelativeDirection.ABOVE))
		for slot in (%Recipe_OpenPortal as GenericRecipe).get_aspect_slots():
			_slot_arrows.append(_add_tutorial_arrow(slot, TutorialArrow.RelativeDirection.BELOW))
	else:
		for arrow in _slot_arrows:
			arrow.remove()
		_slot_arrows.clear()

	if requested and load('res://glossary/terms/standalone/term_glyph.tres') in requested.terms:
		if not Utils.ensure(_card_arrows.is_empty()):
			for arrow in _card_arrows:
				arrow.remove()
			_card_arrows.clear()
		for card in Utils.get_active_run().get_current_stage().get_card_deck().get_hand_cards():
			_card_arrows.append(_add_tutorial_arrow(
				card.get_node('%MainContainer') as Control,
				TutorialArrow.RelativeDirection.ABOVE))
	else:
		for arrow in _card_arrows:
			arrow.remove()
		_card_arrows.clear()

	if requested and load('res://glossary/terms/standalone/term_aspect.tres') in requested.terms:
		if not Utils.ensure(_aspect_arrows.is_empty()):
			for arrow in _aspect_arrows:
				arrow.remove()
			_aspect_arrows.clear()
		for card in Utils.get_active_run().get_current_stage().get_card_deck().get_hand_cards():
			for slot: Control in card.get_node('%AspectsList').get_children():
				_aspect_arrows.append(_add_tutorial_arrow(slot, TutorialArrow.RelativeDirection.ABOVE))
	else:
		for arrow in _aspect_arrows:
			arrow.remove()
		_aspect_arrows.clear()

	if requested and load('res://glossary/terms/standalone/term_card_ability.tres') in requested.terms:
		if not Utils.ensure(_invocation_arrows.is_empty()):
			for arrow in _invocation_arrows:
				arrow.remove()
			_invocation_arrows.clear()
		for card in Utils.get_active_run().get_current_stage().get_card_deck().get_hand_cards():
			var ability_label := card.get_node('%AbilityLabel1') as RichTextLabel
			if ability_label and ability_label.text and ability_label.is_visible_in_tree():
				_invocation_arrows.append(_add_tutorial_arrow(ability_label, TutorialArrow.RelativeDirection.RIGHT))
	else:
		for arrow in _invocation_arrows:
			arrow.remove()
		_invocation_arrows.clear()

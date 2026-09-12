@tool
class_name DevEventCreator
extends Node2D

enum Type { GENERIC, COMPANION, LANDMARK, MANUAL, GENERIC_CHAIN, HUB, SECRET }

@export_group('Setup')
@export_tool_button('Reset')
@warning_ignore('unused_private_class_variable')
var _reset_tool := _reset
@export var id: String
@export var type: Type = Type.GENERIC
@export var spot_upgrade: SpotUpgrade
@export var probability: Event_Stage.Probability = Event_Stage.Probability.NORMAL
@export var repeatability: Event_Stage.Repeatability = Event_Stage.Repeatability.ONCE_PER_RUN
@export var requirement: String

@export_group('Content')
@export var event_name: String
@export var background: Texture2D
@export var background_credit: ArtPiece
@export_multiline var main_text: String

@export_group('Choice 1')
@export var choice1: String
@export var choice1_requirement: String
@export var choice1_outcome: EventOutcome
@export_multiline var choice1_response: String

@export_group('Choice 2')
@export var choice2: String
@export var choice2_requirement: String
@export var choice2_outcome: EventOutcome
@export_multiline var choice2_response: String

@export_group('Choice 3')
@export var choice3: String
@export var choice3_requirement: String
@export var choice3_outcome: EventOutcome
@export_multiline var choice3_response: String

@export_group('Choice Exit')
@export var choice_exit: String
@export var choice_exit_outcome: EventOutcome
@export_multiline var choice_exit_response: String

@export_group('Preview')
@export_multiline var preview_preamble: String
@export var preview: Event:
	set(value):
		preview = value
		if is_node_ready():
			(%EventScene as EventScene).event = preview
@export_tool_button('Preview')
@warning_ignore('unused_private_class_variable')
var _preview_tool := _preview

@export_group('Save')
@export var folder: String
@export_tool_button('Save')
@warning_ignore('unused_private_class_variable')
var _save_tool := _save

var _run: Run

func _ready() -> void:
	if not Utils.is_in_editor():
		_run_preview()

func _reset() -> void:
	id = ''
	type = Type.GENERIC
	spot_upgrade = null
	probability = Event_Stage.Probability.NORMAL
	repeatability = Event_Stage.Repeatability.ONCE_PER_RUN
	event_name = ''
	background = null
	background_credit = null
	requirement = ''
	main_text = ''
	choice1 = ''
	choice1_requirement = ''
	choice1_outcome = null
	choice1_response = ''
	choice2 = ''
	choice2_requirement = ''
	choice2_outcome = null
	choice2_response = ''
	choice3 = ''
	choice3_requirement = ''
	choice3_outcome = null
	choice3_response = ''
	choice_exit = ''
	choice_exit_outcome = null
	choice_exit_response = ''
	preview = null
	folder = ''

func _preview() -> void:
	preview = _create_preview()

func _create_preview() -> Event:
	var event: Event
	if type == Type.HUB:
		event = Event_Hub.new()
	else:
		event = Event_Stage.new()

	event.event_id = id
	event.event_name = event_name
	assert(event_name, 'Must specify event name.')

	if event is Event_Stage:
		if type != Type.MANUAL:
			assert(spot_upgrade, 'Stage events must specify the spot upgrade.')
			(event as Event_Stage).default_spot_upgrade = spot_upgrade
		if type == Type.LANDMARK:
			assert(repeatability == Event_Stage.Repeatability.ONCE_PER_RUN,
					'Landmarks must be repeatable once per stage.')
			assert(probability == Event_Stage.Probability.LANDMARK,
					'Landmarks must have probability == landmark.')
		(event as Event_Stage).default_probability_weight = probability
		(event as Event_Stage).repeatability = repeatability
		match type:
			Type.GENERIC: event.categories += [Event_Stage.Category.GENERIC]
			Type.COMPANION: event.categories += [Event_Stage.Category.COMPANION, Event_Stage.Category.CHAIN]
			Type.LANDMARK: event.categories += [Event_Stage.Category.LANDMARK]
			Type.GENERIC_CHAIN: event.categories += [Event_Stage.Category.GENERIC, Event_Stage.Category.CHAIN]
			Type.SECRET: event.categories += [Event_Stage.Category.GENERIC, Event_Stage.Category.SECRET]

	if requirement:
		event.requirement = EventRequirementParser.parse(requirement)
		assert(event.requirement)

	var step := EventStep.new()
	event.steps.append(step)
	if background:
		step.background_image = LazyTextureResource.new()
		step.background_image._texture_path = background.resource_path
	step.background_credit = background_credit
	step.markedup_text = main_text
	assert(main_text, 'Must specify main text.')

	if choice1:
		step.choices.append(_create_choice(choice1, choice1_requirement, choice1_outcome, choice1_response))
	else:
		assert(not choice1_requirement, 'Choice 1 has no text but has details.')
		assert(not choice1_outcome, 'Choice 1 has no text but has details.')
		assert(not choice1_response, 'Choice 1 has no text but has details.')

	if choice2:
		step.choices.append(_create_choice(choice2, choice2_requirement, choice2_outcome, choice2_response))
	else:
		assert(not choice2_requirement, 'Choice 2 has no text but has details.')
		assert(not choice2_outcome, 'Choice 2 has no text but has details.')
		assert(not choice2_response, 'Choice 2 has no text but has details.')

	if choice3:
		step.choices.append(_create_choice(choice3, choice3_requirement, choice3_outcome, choice3_response))
	else:
		assert(not choice3_requirement, 'Choice 3 has no text but has details.')
		assert(not choice3_outcome, 'Choice 3 has no text but has details.')
		assert(not choice3_response, 'Choice 3 has no text but has details.')

	if choice_exit:
		step.exit_choice = _create_choice(choice_exit, '', choice_exit_outcome, choice_exit_response)
	else:
		assert(not choice_exit_outcome, 'Exit choice has no text but has details.')
		assert(not choice_exit_response, 'Exit choice has no text but has details.')

	return event

func _create_choice(text: String, c_requirement: String, outcome: EventOutcome, response: String) -> EventChoice:
	var choice := EventChoice.new()
	choice.markedup_text = text
	if c_requirement:
		for aspect in AspectType.get_all_types():
			var regex := RegEx.create_from_string('^' + aspect.aspect_type_id + r'\((\d+)\)$')
			var m := regex.search(c_requirement)
			if m:
				c_requirement = 'aspect(%s, %s, -1, 1)' % [aspect.aspect_type_id, m.get_string(1)]
				break
		for bonus_type in BonusType.get_all_types():
			var regex := RegEx.create_from_string('^' + bonus_type.bonus_type_id + r'\((\d+)(?:, *(\d+))?\)$')
			var m := regex.search(c_requirement)
			if m:
				c_requirement = 'bonus(%s, %s, -1, %s)' % [bonus_type.bonus_type_id, m.get_string(1), m.get_string(2) if m.get_string(2) else '0']
				break
		choice.requirement = EventRequirementParser.parse(c_requirement)
		assert(choice.requirement)
	choice.outcome = outcome
	choice.markedup_result_text = response
	return choice

func _save() -> void:
	assert(preview)
	assert(folder)
	folder = folder.rstrip('/')
	if folder.begins_with('res://events/'):
		folder = folder.substr('res://events/'.length())
	assert(not folder.begins_with('res:'))
	if folder == 'generic':
		folder = 'generic/' + preview.event_id
	var filename := 'res://events/%s/event_%s.tres' % [folder, preview.event_id]
	var save_result := ResourceSaver.save(preview, filename)
	if save_result == OK:
		print('Event saved.')
	else:
		push_error('FAILED TO SAVE EVENT: ', save_result)

func _run_preview() -> void:
	remove_child(%EventScene)

	GlobalSaveGame.init_new_game(13)
	GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P300_STARTED_LEADERSHIP)

	var RUN_SCENE := load('res://run/run.tscn') as PackedScene
	_run = RUN_SCENE.instantiate() as Run
	_run.run_config = RunConfig.new()
	_run.run_config.run_type = RunSetup.get_default_run_type()
	_run.run_config.starting_cards = GlobalSaveGame.get_run_starting_deck()
	_run.run_config.run_seed = 123
	GlobalUI.add_layer_content(_run, UI.Layer.GAME)

	while _run.get_state() != RunData.State.STAGE_SELECTOR:
		await get_tree().process_frame
	_run.debug_create_settlement(Vector2i(100, 100))
	_run.set_state(RunData.State.STAGE)

	for command in preview_preamble.split('\n'):
		if command.strip_edges().begins_with('#'):
			continue
		var expression := Expression.new()
		expression.parse(command, ['run'])
		expression.execute([_run], self)

	await get_tree().process_frame
	_start_event()

func _start_event() -> void:
	_run.queue_event(preview).finished.connect(_start_event)  # Keep looping.

# Preamble Utilities

func add_card(card_name: String) -> void:
	_run.add_card_to_deck(CardType.get_card_type_by_name_or_symbol(card_name))

func add_relic(relic_id: String) -> void:
	_run.add_relic(Relic.get_relic_by_id(relic_id))

func add_bonus(bonus_id: String, amount: int) -> void:
	_run.gain_bonus(BonusGain.new(
		BonusType.get_bonus_type_by_id(bonus_id), amount, GlobalConsoleCommands))

func set_run_var(event_id: String, var_id: String, value_str: String) -> void:
	_set_event_var(_run.get_events_state(), event_id, var_id, value_str)

func set_savegame_var(event_id: String, var_id: String, value_str: String) -> void:
	_set_event_var(GlobalSaveGame.get_events_state(), event_id, var_id, value_str)

func _set_event_var(state: EventsState, event_id: String, var_id: String, value_str: String) -> void:
	if value_str in ['true', 'false']:
		state.set_bool(event_id, var_id, value_str == 'true')
	elif value_str.to_int() or value_str == '0':
		state.set_int(event_id, var_id, value_str.to_int())
	else:
		if ((value_str.begins_with('"') and value_str.ends_with('"'))
				or (value_str.begins_with("'") and value_str.ends_with("'"))):
			value_str = value_str.substr(1, value_str.length() - 2)
		state.set_string(event_id, var_id, value_str)

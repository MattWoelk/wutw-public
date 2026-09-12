@tool
class_name DevSurveyCreator
extends Node2D

@export_group('Setup')
@export_tool_button('Reset')
@warning_ignore('unused_private_class_variable')
var _reset_tool := _reset
@export var episode_id: String
@export var biome_types: Array[MapBiomes.Biome]
@export var spot_types: Array[SpotType]
@export var requirement: String

@export_group('Content')
@export var title: String
@export var background: Texture2D
@export var background_credit: ArtPiece
@export_multiline var main_text: String

@export_group('Choice 1')
@export var choice1: String
@export var choice1_requirement: String
@export var choice1_aspects: String
@export var choice1_outcome: EventOutcome
@export_multiline var choice1_response: String

@export_group('Choice 2')
@export var choice2: String
@export var choice2_requirement: String
@export var choice2_aspects: String
@export var choice2_outcome: EventOutcome
@export_multiline var choice2_response: String

@export_group('Choice 3')
@export var choice3: String
@export var choice3_requirement: String
@export var choice3_aspects: String
@export var choice3_outcome: EventOutcome
@export_multiline var choice3_response: String

@export_group('Choice Exit')
@export var choice_exit: String
@export var choice_exit_aspects: String
@export var choice_exit_outcome: EventOutcome
@export_multiline var choice_exit_response: String

@export_group('Output')
@export var preview: SurveyEpisode:
	set(value):
		preview = value
		if is_node_ready():
			(%Survey as Survey).debug_episode = preview
@export_tool_button('Preview')
@warning_ignore('unused_private_class_variable')
var _preview_tool := _preview
@export_tool_button('Save')
@warning_ignore('unused_private_class_variable')
var _save_tool := _save

func _reset() -> void:
	episode_id = ''
	biome_types = []
	spot_types = []
	title = ''
	background = null
	background_credit = null
	requirement = ''
	main_text = ''
	choice1 = ''
	choice1_requirement = ''
	choice1_aspects = ''
	choice1_outcome = null
	choice1_response = ''
	choice2 = ''
	choice2_requirement = ''
	choice2_aspects = ''
	choice2_outcome = null
	choice2_response = ''
	choice3 = ''
	choice3_requirement = ''
	choice3_aspects = ''
	choice3_outcome = null
	choice3_response = ''
	choice_exit = ''
	choice_exit_aspects = ''
	choice_exit_outcome = null
	choice_exit_response = ''
	preview = null

func _preview() -> void:
	preview = _create_preview()

func _create_preview() -> SurveyEpisode:
	var result := SurveyEpisode.new()

	assert(episode_id, 'Missing ID')
	result.episode_id = episode_id

	result.biome_types = biome_types
	result.spot_types = spot_types

	assert(title, 'Missing title')
	result.title = title

	if background:
		result.background_image = LazyTextureResource.new()
		result.background_image._texture_path = background.resource_path
	background_credit = background_credit

	if requirement:
		result.requirement = EventRequirementParser.parse(requirement)
		assert(result.requirement, 'Failed to parse requirement: ' + requirement)

	assert(main_text, 'Missing main text')
	result.text = main_text

	if choice1:
		result.choices.append(_create_choice(1, choice1, choice1_requirement, choice1_aspects, choice1_outcome, choice1_response))
	if choice2:
		result.choices.append(_create_choice(2, choice2, choice2_requirement, choice2_aspects, choice2_outcome, choice2_response))
	if choice3:
		result.choices.append(_create_choice(3, choice3, choice3_requirement, choice3_aspects, choice3_outcome, choice3_response))
	if choice_exit:
		result.choices.append(_create_choice(4, choice_exit, '', choice_exit_aspects, choice_exit_outcome, choice_exit_response))

	assert(result.choices, 'Must have at least one choice.')

	return result

func _create_choice(debug_index: int, text: String, c_requirement: String, c_aspects: String, outcome: EventOutcome, response: String) -> SurveyChoice:
	var choice := SurveyChoice.new()
	choice.label = text
	if c_requirement:
		choice.requirement = EventRequirementParser.parse(c_requirement)
		assert(choice.requirement, 'Choice %d requirement parsing failed.' % debug_index)
	var pieces := c_aspects.split('+', 0)
	choice.aspects = _parse_aspects(pieces[0])
	assert(choice.aspects, 'Choice %d aspects parsing failed.' % debug_index)
	if pieces.size() > 1:
		choice.aspects_per_season = _parse_aspects(pieces[1])
	choice.outcome = outcome
	choice.outcome_text = response
	return choice

func _parse_aspects(aspects_string: String) -> Array[AspectType]:
	var result: Array[AspectType]
	for aspect_type_id in aspects_string.to_lower().split(','):
		if aspect_type_id == 'universal':
			result.append(null)
			continue
		if aspect_type_id == 'radiance':
			aspect_type_id = 'illumination'  # Convenience
		var aspect_type := AspectType.get_aspect_type_by_id(aspect_type_id)
		assert(aspect_type, 'Unrecognized aspect: ' + aspect_type_id)
		result.append(aspect_type)
	return result

func _save() -> void:
	assert(preview, 'Preview not set.')
	var filename := 'res://stage/survey/episodes/episode_%s.tres' % preview.episode_id

	var save_result := ResourceSaver.save(preview, filename)
	if save_result == OK:
		preview = load(filename)
		print('Episode saved.')
	else:
		push_error('FAILED TO SAVE EPISODE: ', save_result)

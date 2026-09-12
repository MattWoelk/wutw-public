@tool
class_name DevCardCreator
extends Node2D

@warning_ignore('unused_private_class_variable')
@export_tool_button('Clear') var _clear_tool := clear

@export var rarity: CardType.Rarity
@export var symbol: String
@export var card_name: String
@export var abilities: Array[CardAbility] = []
@export var ability_power_estimate: int
@export_flags('Change', 'Life', 'Stability', 'Craft', 'Connection', 'Radiance', 'Spirit')
var init_aspects := 0
@export var tags: Array[CardType.Tag] = []
@export var vocabulary: Array[Vocab]
@export var example_sentences: Array[ExampleSentence]

@export_custom(PROPERTY_HINT_NONE, '', PropertyUsageFlags.PROPERTY_USAGE_EDITOR)
var _vocab_fetch_offset: int = 0
@export_custom(PROPERTY_HINT_NONE, '', PropertyUsageFlags.PROPERTY_USAGE_EDITOR)
var _sentence_fetch_offset: int = 0

@warning_ignore_start('unused_private_class_variable')
@export_tool_button('Fetch Vocab') var _fetch_vocab_tool := _fetch_vocab
@export_tool_button('Fetch Sentences') var _fetch_sentences_tool := _fetch_sentences
@export_tool_button('Save Card') var _save_card_tool := save_card
@warning_ignore_restore('unused_private_class_variable')

func _process(_delta: float) -> void:
	ability_power_estimate = _make_card().estimate_ability_power()

func save_card() -> void:
	if not card_name:
		push_error('MUST ENTER NAME')
		return

	var new_resource := _make_card()
	var filename := 'res://cards/tier%d/card_%s.tres' % [rarity, card_name.to_lower().replace(' ', '_')]

	if FileAccess.file_exists(filename):
		var existing := load(filename) as CardType
		if existing.symbol != new_resource.symbol:
			push_error('Duplicate card with name %s but symbol %s' % [
				new_resource.card_name, new_resource.symbol])
			return
		else:
			push_warning('Overwriting ', filename)
	elif CardType.get_card_type_by_name_or_symbol(new_resource.symbol):
		push_error('Duplicate card with symbol %s but name %s' % [
			new_resource.symbol, new_resource.card_name])
		return

	if new_resource.rarity < CardType.Rarity.NEGATIVE:
		var aspect_count := new_resource.aspects.size()
		if aspect_count != 0 and aspect_count != clamp(new_resource.rarity, 1, 4):
			push_error('Rarity does not match essence count for card ', card_name)
			return

	var save_result := ResourceSaver.save(new_resource, filename)
	if save_result == OK:
		print('Saved ', filename)
	else:
		push_error('FAILED SAVE ', save_result)

func _make_card() -> CardType:
	var new_resource := CardType.new()
	new_resource.rarity = rarity
	new_resource.card_name = card_name
	new_resource.symbol = symbol
	for ability in abilities:
		if ability:
			new_resource.abilities.append(ability.duplicate())
	new_resource.init_aspects = init_aspects
	new_resource.tags = tags
	new_resource.vocabulary = vocabulary.duplicate()
	new_resource.vocabulary.sort_custom(func(a: Vocab, b: Vocab) -> bool:
		return a.get_difficulty() < b.get_difficulty()
	)
	new_resource.example_sentences = example_sentences.duplicate()
	if symbol:
		new_resource.kanji_shape = JapaneseUtils.dev_get_kanji_stroke_shape(symbol)
	return new_resource

func clear() -> void:
	rarity = CardType.Rarity.BASIC
	symbol = ''
	card_name = ''
	abilities = []
	ability_power_estimate = 0
	init_aspects = 0
	tags = []
	vocabulary = []
	example_sentences = []
	_vocab_fetch_offset = 0
	_sentence_fetch_offset = 0

func _fetch_vocab() -> void:
	var fetched := JapaneseUtils.dev_fetch_vocab(symbol, _vocab_fetch_offset + 5)
	vocabulary += fetched.slice(_vocab_fetch_offset).duplicate(true)
	_vocab_fetch_offset += 5

func _fetch_sentences() -> void:
	var fetched := JapaneseUtils.dev_fetch_example_sentences(symbol, _sentence_fetch_offset, 5)
	example_sentences += fetched.duplicate(true)
	_sentence_fetch_offset += 5

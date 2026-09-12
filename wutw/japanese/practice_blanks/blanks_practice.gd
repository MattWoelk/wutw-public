class_name BlanksPractice
extends Node2D

signal closed

static var PROBLEM_SCENE := AsyncLoadedResource.new('res://japanese/practice_blanks/blanks_practice_problem.tscn', true, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var DECK_VIEWER_SCENE := AsyncLoadedResource.new('res://cards/viewer/card_deck_viewer.tscn', true, AsyncLoadedResource.LoadPhase.SPECULATIVE)

enum ProblemType { KANJI_MEANING, KANJI_READING, VOCAB_READING, VOCAB_MEANING, SENTENCE }

@export var arrow_start_sound: WwiseEvent
@export var arrow_confirm_sound: WwiseEvent
@export var arrow_cancel_sound: WwiseEvent

# Balance settings.
@export var bonus_insights_for_finishing: float = 0.1
@export var score_per_problem: float = 0.2
@export var hand_size_curve: Curve
@export var kanji_meaning_probability_curve: Curve
@export var kanji_reading_probability_curve: Curve
@export var vocab_reading_probability_curve: Curve
@export var vocab_meaning_probability_curve: Curve
@export var sentence_probability_curve: Curve
@export var universal_slot_probability_curve: Curve
@export var multi_blank_probability_curve: Curve
@export var vocab_difficulty_curve: Curve
@export var sentence_difficulty_curve: Curve
@export var hide_native_probability_curve: Curve

# Session config.
var starting_level := 60
var level_cap := 60
var draw_deck_cards: Array[CardType]

var _selected_card: Card
var _started := false
var _card_just_slotted := false
var _current_level := 0
var _current_round := 0
var _closing := false
var _random := RandomState.new()
var _meaning_picked := false
var _reading_picked := false

@onready var scroll_panel := %ScrollPanel as ScrollPanel
@onready var deck := %CardDeck as CardDeck
@onready var arrow := %CardArrow as BrushstrokeArrow
@onready var inspiration_bar := %PracticeInspirationDisplay as PracticeInspirationDisplay
@onready var score_bar := %PracticeInsightsScore as PracticeInsightsScore

func _ready() -> void:
	for control: Control in [%FinishButton, %NextRoundButton, deck]:
		control.visible = false
		control.modulate.a = 0
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(%SubtitleLabel as Label).visible = false
	(%QuestionsScroller as Control).visible = false
	(%SetupBox as Control).visible = true
	(%HiraganaPanel as Control).modulate.a = 0
	(%KatakanaPanel as Control).modulate.a = 0

	inspiration_bar.max_inspiration = RunVars.DEFAULTS[RunVars.Var.MAX_INSPIRATION] + Skill.get_skill_var(Skill.Var.MAX_INSPIRATION)

	if Utils.is_running_in_single_scene_mode():
		get_parent().move_child.call_deferred(self, 0)  # Under dynamic UI layers.

	_setup_tooltips()
	_start_setup()
	scroll_panel.animate_unroll()

func _start_minigame() -> void:
	_current_level = starting_level
	_random.shuffle(draw_deck_cards)

	deck.visible = true
	deck.mouse_filter = Control.MOUSE_FILTER_STOP
	(%FinishButton as Control).visible = true
	(%FinishButton as Control).mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(deck, 'modulate:a', 1, 0.5)
	tween.parallel().tween_property(%FinishButton, 'modulate:a', 1, 1.0)
	tween.play()

	_start_round(true)

	_started = true

func _unhandled_input(event: InputEvent) -> void:
	if not Utils.is_running_in_single_scene_mode():  # DEBUG-only
		return
	var key_event := event as InputEventKey
	if not key_event:
		return
	if key_event.keycode == KEY_F2 and key_event.pressed:
		_refill_questions()
		for aspect_slot in _get_all_slots():
			aspect_slot.card_dropped.connect(_on_card_dropped_on_slot.bind(aspect_slot))
	if key_event.keycode == KEY_F3 and key_event.pressed:
		_current_level -= 1
		_start_round()

func _handle_esc() -> bool:
	if not _started:
		_close()
		return true
	return false

func _close() -> void:
	if not _closing:
		_closing = true
		_set_input_enabled(false)
		(%BG as FadedBackground).fade_out()
		(%HiraganaPanel as KanaPanel).animate_hide()
		(%KatakanaPanel as KanaPanel).animate_hide()
		var tween := create_tween()
		tween.tween_property(deck, 'modulate:a', 0.0, 0.5)
		tween.parallel().tween_property(%FinishButton, 'modulate:a', 0.0, 0.5)
		tween.play()
		await scroll_panel.animate_roll()
		queue_free()
		closed.emit()

func _start_round(first: bool = false) -> void:
	if not first and deck.get_draw_pile_cards().is_empty():
		_finish()
		return

	_set_input_enabled(false)

	deck.practice_hand_size = _get_current_hand_size()

	await Utils.coro_all([
		deck.start.bind(draw_deck_cards, _random) if first else deck.redraw,
		scroll_panel.animate_roll.bind(scroll_panel.default_roll_duration, false)
	])

	_refill_questions()
	for aspect_slot in _get_all_slots():
		aspect_slot.card_dropped.connect(_on_card_dropped_on_slot.bind(aspect_slot))

	if starting_level < 10:
		(%StartHintLabel as Control).visible = first
		(%EndHintLabel as Control).visible = false
		(%KunOnHintLabel as Control).visible = _reading_picked
	else:
		(%KunOnHintLabel as Control).visible = false

	(%SubtitleLabel as Label).text = tr('Round %d - Level %d') % [_current_round + 1, _current_level + 1]
	if _current_level > GameSettings.Japanese.kanji_practice_max_level.value():
		GameSettings.Japanese.kanji_practice_max_level.set_value(_current_level, true)
	_current_round += 1
	_current_level = mini(level_cap, _current_level + 1)

	if first:
		(%SetupBox as Control).visible = false
		(%QuestionsScroller as Control).visible = true
		(%SubtitleLabel as Label).visible = true
		(%HiraganaPanel as KanaPanel).animate_show()
		(%KatakanaPanel as KanaPanel).animate_show()

	await scroll_panel.animate_unroll(scroll_panel.default_unroll_duration, false)

	_set_input_enabled(true)

func _get_all_slots() -> Array[AspectSlot]:
	var result: Array[AspectSlot]
	for problem: BlanksPracticeProblem in %QuestionsList.get_children():
		result.append_array(problem.get_aspect_slots())
	return result

func _on_card_deck_card_drag_started(card: Card) -> void:
	Utils.ensure(not _selected_card)
	card.is_selected = true
	_selected_card = card
	arrow.card = _selected_card
	arrow_start_sound.post(GlobalAudioSystem)

func _on_card_deck_card_drag_ended(card: Card) -> void:
	Utils.ensure(_selected_card == card)
	_selected_card = null
	card.is_selected = false
	arrow.card = null
	if _card_just_slotted:
		arrow_confirm_sound.post(GlobalAudioSystem)
		_card_just_slotted = false
	else:
		var message := SlotUtils.get_slot_failure_error_message(card.card_type.aspects)
		if message:
			GlobalUI.show_error(message)
		else:
			arrow_cancel_sound.post(GlobalAudioSystem)

func _on_card_dropped_on_slot(card: Card, slot: AspectSlot) -> void:
	Utils.ensure(card == _selected_card)
	var kanji_slot := slot.get_parent() as KanjiSlot
	assert(kanji_slot)
	for aspect_slot in _get_all_slots():
		aspect_slot.state = AspectSlot.State.NORMAL
	_card_just_slotted = true
	if kanji_slot.kanji == card.card_type.symbol:
		kanji_slot.fill()
		deck.discard(card, CardDeck.DiscardReason.SLOTTED)
	else:
		(Utils.get_typed_ancestor(slot, BlanksPracticeProblem) as BlanksPracticeProblem).play_mistake_anim()
		inspiration_bar.damage()

func _on_practice_inspiration_display_exhausted() -> void:
	while deck.get_draw_pile_cards():
		deck.move_card_from_draw_to_discard(deck.get_draw_pile_cards().size() - 1)

	deck.discard_all()

	for problem: BlanksPracticeProblem in %QuestionsList.get_children():
		for slot in problem.get_kanji_slots():
			if not slot.is_filled():
				slot.fill()

	_reveal_next_round_button()

func _finish() -> void:
	var won := inspiration_bar.get_current_inspiration() > 0
	var gained_insights := floori(score_bar.score)
	var bonus_insights := roundi(score_bar.score * bonus_insights_for_finishing) if won else 0
	var text := tr('Practice session finished!\n\n')
	if gained_insights:
		text += tr_n(
			'You will gain %d insight for correct answers.',
			'You will gain %d insights for correct answers.',
			gained_insights) % gained_insights
		if bonus_insights:
			text += '\n\n'
			text += tr_n(
				'You will gain %d more insight for finishing all the problems!',
				'You will gain %d more insights for finishing all the problems!',
				bonus_insights) % bonus_insights
	else:
		text += tr('No insights gained.')
	await GlobalUI.show_confirm(tr('Practice Result'), text).confirmed
	GlobalSaveGame.insights += gained_insights + bonus_insights
	GlobalSaveGame.save_game()
	_close()

func _refill_questions() -> void:
	Utils.clear_node(%QuestionsList)

	var hand_cards := deck.get_hand_cards()
	_random.shuffle(hand_cards)

	var multi_card_probability := multi_blank_probability_curve.sample(_current_level)
	if _random.rand_float() < multi_card_probability:
		for _i in 3:
			var multi_blank_problem := _try_multi_blank(hand_cards)
			if multi_blank_problem:
				hand_cards = hand_cards.filter(func(c: Card) -> bool:
					return c.card_type.symbol not in multi_blank_problem.kanji_blanks
				)
				multi_blank_problem.solved.connect(_on_problem_solved)
				multi_blank_problem.solved.connect(func() -> void:
					if inspiration_bar.get_current_inspiration() <= 0:
						return
					score_bar.score += 1  # Bonus!
				)
				%QuestionsList.add_child(multi_blank_problem)
			else:
				break

	_meaning_picked = false
	_reading_picked = false
	var hand_card_types: Array[CardType]
	for card in hand_cards:
		hand_card_types.append(card.card_type)
	for card in hand_cards:
		hand_card_types.erase(card.card_type)
		var problem := _create_question(card.card_type, hand_card_types)
		problem.solved.connect(_on_problem_solved)
		%QuestionsList.add_child(problem)
		hand_card_types.append(card.card_type)

func _create_question(answer: CardType, other_cards: Array[CardType]) -> BlanksPracticeProblem:
	var problem_type := _choose_problem_type()
	var details := JapaneseUtils.get_kanji_detail(answer.symbol)

	if problem_type == ProblemType.SENTENCE:
		if answer.example_sentences:
			var target_difficulty := sentence_difficulty_curve.sample(_current_level)
			var weights: Dictionary[ExampleSentence, float]
			for sentence in answer.example_sentences:
				weights[sentence] = _difficulty_to_weight(sentence.get_difficulty(), target_difficulty)
			var sentence := _random.pick_weighted_dict(weights)[0] as ExampleSentence
			var result := _create_question_widget(sentence.parsed, tr(sentence.native), [answer.symbol])
			result.hide_native = _random.rand_float() < hide_native_probability_curve.sample(_current_level)
			return result
		else:
			# Fallback
			problem_type = ProblemType.VOCAB_READING

	if problem_type == ProblemType.VOCAB_MEANING:
		if answer.vocabulary:
			var target_difficulty := vocab_difficulty_curve.sample(_current_level)
			var weights: Dictionary[Vocab, float]
			for vocab in answer.vocabulary:
				weights[vocab] = _difficulty_to_weight(vocab.get_difficulty(), target_difficulty)
			var vocab := _random.pick_weighted_dict(weights)[0] as Vocab
			var meaning := vocab.pick_meaning(_random)
			if answer.symbol not in vocab.japanese:
				push_warning('Symbol %s not found in vocab %s.' % [vocab.japanese, answer.symbol])
			var token := JapaneseToken.new()
			token.raw_text = vocab.japanese
			token.reading = vocab.readings[0]
			token.vocab = vocab
			return _create_question_widget([token], tr(meaning), [answer.symbol])
		else:
			# Fallback
			problem_type = ProblemType.KANJI_READING

	if problem_type == ProblemType.VOCAB_READING:
		if answer.vocabulary:
			var target_difficulty := vocab_difficulty_curve.sample(_current_level)
			var weights: Dictionary[Vocab, float]
			for vocab in answer.vocabulary:
				weights[vocab] = _difficulty_to_weight(vocab.get_difficulty(), target_difficulty)
			var vocab := _random.pick_weighted_dict(weights)[0] as Vocab

			var reading := _random.pick(vocab.readings) as String
			if answer.symbol not in vocab.japanese:
				push_warning('Symbol %s not found in vocab %s.' % [vocab.japanese, answer.symbol])
			var token := JapaneseToken.new()
			token.raw_text = vocab.japanese
			token.reading = vocab.readings[0]
			token.vocab = vocab
			return _create_question_widget([token], reading, [answer.symbol])
		else:
			# Fallback
			problem_type = ProblemType.KANJI_READING

	if problem_type == ProblemType.KANJI_READING:
		var onyomi := details.get_preferred_onyomi()
		var can_use_onyomi := not onyomi.is_empty()
		if can_use_onyomi:
			for other_card in other_cards:
				var other_details := JapaneseUtils.get_kanji_detail(other_card.symbol)
				if onyomi in other_details.onyomi:
					can_use_onyomi = false
					break

		var kunyomi := details.get_preferred_kunyomi().split('.')[0]
		var can_use_kunyomi := not kunyomi.is_empty()
		if can_use_kunyomi:
			for other_card in other_cards:
				var other_details := JapaneseUtils.get_kanji_detail(other_card.symbol)
				for other_kunyomi in other_details.kunyomi:
					if kunyomi == other_kunyomi.split('.')[0]:
						can_use_kunyomi = false
						break

		if can_use_onyomi or can_use_kunyomi:
			var use_onyomi: bool
			if can_use_onyomi and can_use_kunyomi:
				use_onyomi = _random.rand_bool()
			elif can_use_kunyomi:
				use_onyomi = false
			elif can_use_onyomi:
				use_onyomi = true
			var prompt := (tr('Onyomi: ') + onyomi) if use_onyomi else (tr('Kunyomi: ') + kunyomi)
			var token := JapaneseToken.new()
			token.raw_text = answer.symbol
			# No reading or vocab.
			return _create_question_widget([token], prompt, [answer.symbol])
		else:
			# Fallback
			problem_type = ProblemType.KANJI_MEANING

	if problem_type == ProblemType.KANJI_MEANING:
		var token := JapaneseToken.new()
		token.raw_text = answer.symbol
		# No reading or vocab.
		return _create_question_widget([token], tr(answer.card_name), [answer.symbol])

	assert(false)
	return null

func _create_question_widget(tokens: Array[JapaneseToken], prompt: String, blanks: Array[String]) -> BlanksPracticeProblem:
	var problem := PROBLEM_SCENE.instantiate_loaded_scene() as BlanksPracticeProblem
	problem.tokens = tokens
	problem.prompt = prompt
	problem.kanji_blanks = blanks
	problem.universal_probability = universal_slot_probability_curve.sample(_current_level)
	return problem

func _choose_problem_type() -> ProblemType:
	if _current_level > 0 and not _meaning_picked:
		_meaning_picked = true
		return ProblemType.VOCAB_MEANING
	if _current_level > 1 and not _reading_picked:
		_reading_picked = true
		return ProblemType.KANJI_READING
	var choices: Dictionary[ProblemType, float]
	choices[ProblemType.KANJI_MEANING] = kanji_meaning_probability_curve.sample(_current_level)
	choices[ProblemType.KANJI_READING] = kanji_reading_probability_curve.sample(_current_level)
	choices[ProblemType.VOCAB_READING] = vocab_reading_probability_curve.sample(_current_level)
	choices[ProblemType.VOCAB_MEANING] = vocab_meaning_probability_curve.sample(_current_level)
	choices[ProblemType.SENTENCE] = sentence_probability_curve.sample(_current_level)
	return _random.pick_weighted_dict(choices)[0] as ProblemType

func _on_problem_solved() -> void:
	if inspiration_bar.get_current_inspiration() <= 0:
		return
	score_bar.score += score_per_problem
	for problem: BlanksPracticeProblem in %QuestionsList.get_children():
		if not problem.is_solved():
			return

	if starting_level < 10:
		if Utils.is_steam_deck():
			(%EndHintLabel as MarkedUpLabel).set_markedup_text(
				tr((%EndHintLabel as MarkedUpLabel).text).replace(tr('right click'), InputPrompts.get_input_markup(
					InputPrompts.InputType.RIGHT_CLICK)))

		(%EndHintLabel as Control).visible = (%StartHintLabel as Control).visible
		(%StartHintLabel as Control).visible = false

	_reveal_next_round_button()

func _reveal_next_round_button() -> void:
	if deck.get_draw_pile_cards().is_empty():
		(%NextRoundButton as Button).text = tr('Finish Practice')
		(%FinishButton as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		var finish_tween := create_tween()
		finish_tween.tween_property(%FinishButton, 'modulate:a', 0.0, 0.5)
		finish_tween.tween_callback(func() -> void: (%FinishButton as Control).visible = false)
		finish_tween.set_speed_scale(Utils.anim_speed())
		finish_tween.play()

	(%NextRoundButton as Control).visible = true
	(%NextRoundButton as Control).mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(%NextRoundButton, 'modulate:a', 1.0, 0.5)
	tween.set_speed_scale(Utils.anim_speed())
	tween.play()

func _get_current_hand_size() -> int:
	return roundi(hand_size_curve.sample(_current_level))

func _set_input_enabled(enabled: bool) -> void:
	for child: Control in get_children():
		Utils.set_input_enabled(child, enabled)

func _on_finish_button_pressed() -> void:
	_finish()

func _on_next_round_button_pressed() -> void:
	_start_round()

	(%NextRoundButton as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween()
	tween.tween_property(%NextRoundButton, 'modulate:a', 0.0, 0.5)
	tween.set_speed_scale(Utils.anim_speed())
	tween.play()
	await tween.finished
	(%NextRoundButton as Control).visible = false

func _try_multi_blank(hand_cards: Array[Card]) -> BlanksPracticeProblem:
	var available_kanji: Dictionary[String, bool]
	for card in hand_cards:
		available_kanji[card.card_type.symbol] = true

	var potential_vocabs: Array[Vocab]
	for card in hand_cards:
		for vocab in card.card_type.vocabulary:
			var used_kanji := vocab.get_used_kanji()
			if used_kanji.size() > 1:
				for kanji in used_kanji:
					if kanji != card.card_type.symbol and kanji in available_kanji:
						potential_vocabs.append(vocab)
						break
	var potential_sentences: Array[ExampleSentence]
	for card in hand_cards:
		for sentence in card.card_type.example_sentences:
			var used_kanji := sentence.get_used_kanji()
			if used_kanji.size() > 1:
				for kanji in used_kanji:
					if kanji != card.card_type.symbol and kanji in available_kanji:
						potential_sentences.append(sentence)
						break

	if not (potential_vocabs or potential_sentences):
		return null

	# We got something!
	var target_difficulty := sentence_difficulty_curve.sample(_current_level)
	var weights: Dictionary[Variant, float]
	for vocab in potential_vocabs:
		weights[vocab] = _difficulty_to_weight_tight(vocab.get_difficulty(), target_difficulty)
	for sentence in potential_sentences:
		weights[sentence] = _difficulty_to_weight_tight(sentence.get_difficulty(), target_difficulty)

	var choice: Variant = _random.pick_weighted_dict(weights)[0]
	if choice is Vocab:
		var vocab := choice as Vocab
		var kanjis: Array[String]
		for kanji: String in available_kanji.keys():
			if kanji in vocab.japanese:
				kanjis.append(kanji)
		if _random.rand_bool():
			# Meaning
			var meaning := vocab.pick_meaning(_random)
			var token := JapaneseToken.new()
			token.raw_text = vocab.japanese
			token.reading = vocab.readings[0]
			token.vocab = vocab
			return _create_question_widget([token], tr(meaning), kanjis)
		else:
			# Reading
			var token := JapaneseToken.new()
			var reading := _random.pick(vocab.readings) as String
			token.raw_text = vocab.japanese
			token.reading = reading
			token.vocab = vocab
			return _create_question_widget([token], reading, kanjis)
	elif choice is ExampleSentence:
		var sentence := choice as ExampleSentence
		var kanjis: Array[String]
		for kanji: String in available_kanji.keys():
			if kanji in sentence.japanese:
				kanjis.append(kanji)
		return _create_question_widget(sentence.parsed, tr(sentence.native), kanjis)
	else:
		assert(false)
		return null

func _difficulty_to_weight(difficulty: float, target_difficulty: float) -> float:
	var min_weight := 0.1 if difficulty < target_difficulty else 0.0
	return 1.0 - clampf(absf(difficulty - target_difficulty) / 0.2, min_weight, 1)

func _difficulty_to_weight_tight(difficulty: float, target_difficulty: float) -> float:
	return 1.0 - clampf(absf(difficulty - target_difficulty) / 0.05, 0, 1)

## Setup Functionality

func _start_setup() -> void:
	var intro_label := %IntroLabel as MarkedUpLabel
	intro_label.set_markedup_text(tr(intro_label.text))

	var max_level := mini(GameSettings.Japanese.kanji_practice_max_level.value(), 59)
	(%Slider_StartingLevel as Slider).max_value = max_level
	(%Slider_StartingLevel as Slider).set_value(GameSettings.Japanese.kanji_practice_lru_level.value())
	(%Slider_LevelCap as Slider).set_value(GameSettings.Japanese.kanji_practice_lru_level_cap.value())
	(%Slider_MaxGrade as Slider).set_value(GameSettings.Japanese.kanji_practice_lru_grade.value())
	(%Slider_MaxJlptLevel as Slider).set_value(GameSettings.Japanese.kanji_practice_lru_jlpt.value())

	(%Dropdown_FuriganaMode as Dropdown).add_item(tr('Never'), GameSettings.FuriganaMode.OFF)
	(%Dropdown_FuriganaMode as Dropdown).add_item(tr('When Solved'), GameSettings.FuriganaMode.WHEL_SOLVED)
	(%Dropdown_FuriganaMode as Dropdown).add_item(tr('Always'), GameSettings.FuriganaMode.ALWAYS)
	var furigana_mode := GameSettings.Japanese.kanji_practice_furigana_mode.value() as GameSettings.FuriganaMode
	(%Dropdown_FuriganaMode as Dropdown).set_selected_value(furigana_mode)

	_update_setup_card_count()

	if max_level == 0:
		(%SettingsList as Control).visible = false

func _on_start_button_pressed() -> void:
	starting_level = roundi((%Slider_StartingLevel as Slider).value)
	level_cap = roundi((%Slider_LevelCap as Slider).value)
	draw_deck_cards = _get_setup_matching_cards()

	_start_minigame()

func _on_slider_starting_level_value_changed(value: float) -> void:
	var level := roundi(value + 1)
	(%Label_StartingLevelValue as Label).text = str(level)
	if level == 60:
		(%Label_StartingLevelValue as Label).text += tr(' (max)')
	GameSettings.Japanese.kanji_practice_lru_level.set_value(roundi(value), true)
	if value > (%Slider_LevelCap as Slider).value:
		(%Slider_LevelCap as Slider).value = value

func _on_slider_level_cap_value_changed(value: float) -> void:
	var cap := roundi(value + 1)
	(%Label_LevelCapValue as Label).text = str(cap)
	if cap == 60:
		(%Label_LevelCapValue as Label).text += tr(' (max)')
	GameSettings.Japanese.kanji_practice_lru_level_cap.set_value(roundi(value), true)
	if value < (%Slider_StartingLevel as Slider).value:
		(%Slider_StartingLevel as Slider).value = value

func _on_slider_max_grade_value_changed(value: float) -> void:
	var grade := roundi(value)
	(%Label_MaxGradeValue as Label).text = str(grade) if grade < 11 else tr('Any')
	GameSettings.Japanese.kanji_practice_lru_grade.set_value(roundi(value), true)
	_update_setup_card_count()

func _on_slider_max_jlpt_level_value_changed(value: float) -> void:
	var jlpt := roundi(4 - value)
	(%Label_MaxJlptLevelValue as Label).text = ('N' + str(jlpt)) if jlpt > 0 else tr('Any')
	GameSettings.Japanese.kanji_practice_lru_jlpt.set_value(roundi(value), true)
	_update_setup_card_count()

func _on_dropdown_furigana_mode_selected(item: DropdownItem) -> void:
	var furigana_mode := item.value as GameSettings.FuriganaMode
	GameSettings.Japanese.kanji_practice_furigana_mode.set_value(furigana_mode)

func _update_setup_card_count() -> void:
	(%ViewStartingCardsButton as Button).text = tr('View %d Glyphs') % _get_setup_matching_cards().size()

func _get_setup_matching_cards() -> Array[CardType]:
	var all_cards: Array[CardType]
	if Utils.is_running_in_single_scene_mode():
		# For standalone testing.
		all_cards = CardType.get_all_card_types()
	else:
		all_cards = GlobalSaveGame.get_seen_cards()

	var result: Array[CardType]
	for card_type in all_cards:
		var kanji_detail := JapaneseUtils.get_kanji_detail(card_type.symbol)

		var grade_limit := roundi((%Slider_MaxGrade as Slider).value)
		if grade_limit < 11:
			if kanji_detail.grade == -1 or kanji_detail.grade > grade_limit:
				continue

		var jlpt_limit := roundi(4 - (%Slider_MaxJlptLevel as Slider).value)
		if jlpt_limit > 0:
			if kanji_detail.jlpt == -1 or kanji_detail.jlpt < jlpt_limit:
				continue

		result.append(card_type)
	return result

func _on_view_starting_cards_button_pressed() -> void:
	var draw_deck_viewer := DECK_VIEWER_SCENE.instantiate_loaded_scene() as CardDeckViewer
	draw_deck_viewer.title = tr('Glyphs to Practice')
	draw_deck_viewer.cards = _get_setup_matching_cards()
	draw_deck_viewer.cards.sort_custom(CardType.compare)
	GlobalUI.add_layer_content(draw_deck_viewer, UI.Layer.GAME_MENU_SUBMENU)

func _on_close_button_pressed() -> void:
	_close()

func _setup_tooltips() -> void:
	GlobalTooltipSystem.attach(%HBox_StartingLevel as Control, func() -> String:
		return tr('The difficulty level at which the minigame starts.' +
				' Higher levels have sentence questions and use only universal slots.' +
				' Can be set to any level you have reached before.')
	, [Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.CENTERED])
	GlobalTooltipSystem.attach(%HBox_LevelCap as Control, func() -> String:
		return tr('The maximum difficulty level at which the minigame difficulty stops increasing.')
	, [Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.CENTERED])
	GlobalTooltipSystem.attach(%HBox_FuriganaMode as Control, func() -> String:
		return tr('Show the pronunciation in hiragana above each kanji in sentences.')
	, [Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.CENTERED])

	GlobalTooltipSystem.attach(%HBox_MaxGrade as Control, func() -> String:
		return tr('Optionally, filter out kanji taught in higher school grades in Japan.')
	, [Tooltip.RelativeDirection.RIGHT], [Tooltip.Alignment.CENTERED])
	GlobalTooltipSystem.attach(%HBox_MaxJlptLevel as Control, func() -> String:
		return tr('Optionally, filter out kanji classified at harder levels of the JLPT (Japanese Language Proficiency Test).')
	, [Tooltip.RelativeDirection.RIGHT], [Tooltip.Alignment.CENTERED])
	GlobalTooltipSystem.attach(%HBox_TotalCards as Control, func() -> String:
		return tr('Preview the kanji that will be included in this session.' +
				' Only kanji of glyphs already discovered in the main game can be accessed,' +
				' and they can be filtered further by school gade or JLPT level.')
	, [Tooltip.RelativeDirection.RIGHT], [Tooltip.Alignment.CENTERED])

func _on_intro_button_pressed() -> void:
	GlobalUI.show_confirm(tr('Japanese Writing Intro'), tr('''
Japanese writing uses 3 sets of characters.

Kanji are the Chinese-origin characters that you see on the glyph scrolls in the game. Each character has a meaning, as well as one or more Chinese-origin and Japanese-origin pronunciations.

Hiragana is a phonetic syllabary used for grammar and common words. Hiragana characters do not have innate meanings, but simply represent sounds. They have simple, usually rounded shapes.

Katakana is a phonetic syllabary used for foreign loanwords. It represents the exact same sounds as hiragana, but has different shapes, written with sharp strokes.

When hiragana or katakana appears above a kanji character as a pronunciation hint, that is called furigana.

When hiragana or katakana is transliterated into latin letters, that is called romaji.
''').strip_edges(), tr('Ok'), '')

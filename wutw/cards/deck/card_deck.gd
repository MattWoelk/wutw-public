class_name CardDeck
extends Control

enum CardDrawReason { REDRAW, ABILITY, RELIC, HARMONIZATION_RECIPE, EVENT, COMPANION, HAUNTING, SETTLER_QUEST }
enum DiscardReason { SLOTTED, CAST, REDRAW, ABILITY, RELIC, COMPANION, HAUNTING, SETTLER_QUEST }

signal card_drag_started(card: Card)
signal card_drag_ended(card: Card)
signal card_right_clicked(card: Card)
signal card_hover_changed

static var CARD_SCENE := AsyncLoadedResource.new('res://cards/card.tscn')
static var DECK_VIEWER_SCENE := AsyncLoadedResource.new('res://cards/viewer/card_deck_viewer.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

const ANIM_INTERVAL: float = 0.1
const MIN_SEPARATION := -100

@export var practice_mode := false
@export var practice_hand_size := 8

var _hovered_card: Card
var _processed_card: Card
var _draw_pile: Array[CardType]
var _discard_pile: Array[CardType]
var _random_state: RandomState
var _is_first_hand: bool = true
var _most_recently_cast_card: CardType
var _hand_cards: Array[Card]
var _hand_separation: float = 0
var _redrawing: bool = false
var _draw_deck_viewer: CardDeckViewer
var _discard_deck_viewer: CardDeckViewer

var _deck_button_hovered: bool = false
var _aspect_counter_hovered: bool = false

func _ready() -> void:
	Utils.clear_node(%HandList)
	GlobalTooltipSystem.attach(%ViewDeckButton as Control, _make_tooltip_text,
			[Tooltip.RelativeDirection.ABOVE], [Tooltip.Alignment.BEGIN])
	GlobalTooltipSystem.attach(%ViewDiscardButton as Control, _make_discards_tooltip_text,
			[Tooltip.RelativeDirection.ABOVE], [Tooltip.Alignment.BEGIN])
	(%AspectCountersBox as Control).visible = not practice_mode

func _process(delta: float) -> void:
	var separation := 0
	if %HandList.get_child_count():
		var available_space := (%HandScroller as ScrollContainer).size.x - 10
		var needed_space := %HandList.get_child_count() * (%HandList.get_child(0) as Card).size.x
		if needed_space > available_space:
			separation = -floori((needed_space - available_space) / (%HandList.get_child_count() - 1))
			if separation < MIN_SEPARATION:
				separation = MIN_SEPARATION
				(%HandScroller as ScrollContainer).horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
				if get_viewport().gui_is_dragging():
					(%HandScroller as ScrollContainer).mouse_filter = Control.MOUSE_FILTER_IGNORE
				else:
					(%HandScroller as ScrollContainer).mouse_filter = Control.MOUSE_FILTER_PASS
			else:
				(%HandScroller as ScrollContainer).horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
				(%HandScroller as ScrollContainer).mouse_filter = Control.MOUSE_FILTER_IGNORE
	if separation != (%HandList as HBoxContainer).get_theme_constant('separation'):
		# Only change if relevant, otherwise hover breaks.
		_hand_separation = move_toward(_hand_separation, separation, delta * 50)
		(%HandList as HBoxContainer).add_theme_constant_override('separation', floori(_hand_separation))

	(%SortButton as Button).visible = (%HandScroller as ScrollContainer).horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO
	(%SortButton as Button).disabled = _processed_card != null

func _enter_tree() -> void:
	UI.register_zoomable(%DrawDeckBox as Control, 0, 1)

func _shortcut_input(event: InputEvent) -> void:
	if event.is_action_pressed('view_discard_deck', false):
		if _discard_deck_viewer and _discard_deck_viewer.is_inside_tree():
			if not GlobalUI.is_higher_level_active(_discard_deck_viewer):
				_discard_deck_viewer.close()
				get_viewport().set_input_as_handled()
		else:
			if not GlobalUI.is_higher_level_active(self):
				_on_view_discard_button_pressed()
				get_viewport().set_input_as_handled()
	elif event.is_action_pressed('view_draw_deck', false):
		if _draw_deck_viewer and _draw_deck_viewer.is_inside_tree():
			if not GlobalUI.is_higher_level_active(_draw_deck_viewer):
				_draw_deck_viewer.close()
				get_viewport().set_input_as_handled()
		else:
			if not GlobalUI.is_higher_level_active(self):
				_on_view_deck_button_pressed()
				get_viewport().set_input_as_handled()

# Utilities

func get_hand_size() -> int:
	if practice_mode:
		return practice_hand_size
	else:
		if not Utils.ensure(Utils.get_active_run() != null):
			return 5  # Safeguard
		var hand_size := Utils.get_active_run().get_var(RunVars.Var.HAND_SIZE)
		if _is_first_hand:
			hand_size += Skill.get_skill_var(Skill.Var.START_HAND_SIZE)
		else:
			hand_size += Skill.get_skill_var(Skill.Var.REDRAW_HAND_SIZE)
		return hand_size

func get_hand_cards(except: Array[Card] = []) -> Array[Card]:
	var pool: Array[Card] = []
	for card in _hand_cards:
		if card not in except:
			pool.append(card)
	return pool

func get_random_from_hand(except: Array[Card] = []) -> Card:
	return _random_state.pick(get_hand_cards(except))

func get_random_state() -> RandomState:
	return _random_state

func get_draw_pile_cards() -> Array[CardType]:
	return _draw_pile.duplicate()

func get_num_draw_pile_cards() -> int:
	return _draw_pile.size()

func get_discard_pile_cards() -> Array[CardType]:
	return _discard_pile.duplicate()

func get_num_discard_pile_cards() -> int:
	return _discard_pile.size()

func get_hovered_card() -> Card:
	return _hovered_card

func get_most_recently_cast_card() -> CardType:
	return _most_recently_cast_card

func set_most_recently_cast_card(card_type: CardType) -> void:
	_most_recently_cast_card = card_type

func enable_interaction() -> void:
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED

func disable_interaction() -> void:
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED

func start_processing(card: Card) -> void:
	Utils.ensure(card in _hand_cards)
	_processed_card = card
	card.is_being_played = true
	_hand_cards.erase(card)
	# Avoid cutting-off card name labels when they are raised during casing.
	(%HandScroller as ScrollContainer).clip_contents = false

func finish_processing(card: Card) -> void:
	Utils.ensure(_processed_card == card)
	if card.playable:  # Discard was blocked!
		card.is_being_played = false
		card.is_selected = false
		_hand_cards.append(card)
	else:
		card.queue_free()
	_processed_card = null
	(%HandScroller as ScrollContainer).clip_contents = true

func set_draw_deck_cards(cards: Array[CardType]) -> void:
	# A special method only used to set up the tutorial and minigames.
	Utils.ensure(practice_mode or GlobalSaveGame.get_main_quest_progress() <= SaveGame.MainQuestProgress.P100_STARTED_RELIGION)
	_draw_pile.assign(cards)

func erase_card(card_type: CardType) -> bool:
	# A special method used mainly events that remove cards from the deck during gameplay.
	for card in _hand_cards:
		if card.card_type == card_type:
			_hand_cards.erase(card)
			card.queue_free()
			return true
	if card_type in _discard_pile:
		_discard_pile.erase(card_type)
		return true
	elif card_type in _draw_pile:
		_draw_pile.erase(card_type)
		return true
	_update_indicators()
	return false

func is_redrawing() -> bool:
	return _redrawing

# Main functionality (all coroutines!)

func start(cards: Array[CardType], random_state: RandomState, helper_innate: Array[CardType] = []) -> void:
	_random_state = random_state

	if _hand_cards:
		for card: Card in _hand_cards.slice(0, -1):
			discard(card, CardDeck.DiscardReason.REDRAW, true)
		await discard(_hand_cards[-1], CardDeck.DiscardReason.REDRAW, true)
		_hand_cards = []

	_is_first_hand = true
	_discard_pile = []
	_draw_pile = cards.duplicate()
	_random_state.shuffle(_draw_pile)

	# Move innate cards to the top of the deck.
	var run := Utils.get_active_run()
	if run:
		for card_type in run.get_innate_cards() + helper_innate:
			var index := _draw_pile.rfind(card_type)  # Using rfind() to handle duplicate innate cards.
			if Utils.ensure(index >= 0):
				_draw_pile.remove_at(index)
				_draw_pile.insert(0, card_type)

	await redraw(true)
	_is_first_hand = false

func draw(reason: CardDrawReason, can_exceed_hand_size: bool = false, from_discards: bool = false) -> void:
	if _hand_cards.size() >= get_hand_size() and not can_exceed_hand_size:
		return
	var run := Utils.get_active_run()
	if from_discards:
		if _discard_pile.is_empty():
			return
		# From discards is always randomized.
		var new_card_type := _random_state.pick(_discard_pile) as CardType
		_discard_pile.erase(new_card_type)
		var new_card := await add_card_to_hand(new_card_type, reason, from_discards)
		if run:
			run.signals.card_drawn.emit(new_card, reason, from_discards)
	else:
		if _draw_pile.is_empty():
			if practice_mode:  # No reshuffling in kanji practice.
				return
			_draw_pile = _discard_pile.duplicate()
			_discard_pile = []
			_random_state.shuffle(_draw_pile)
			if run:
				run.signals.deck_reshuffled.emit()
		if not Utils.ensure(not _draw_pile.is_empty()):
			return
		var new_card_type := _draw_pile.pop_front() as CardType
		var new_card := await add_card_to_hand(new_card_type, reason, from_discards)
		if run:
			run.signals.card_drawn.emit(new_card, reason, from_discards)

func discard(card: Card, reason: DiscardReason, destroy: bool = false) -> void:
	if not Utils.ensure(card != null):
		return
	if not Utils.ensure(%HandList.is_ancestor_of(card)):
		return
	if not Utils.ensure(card == _processed_card or card in _hand_cards):
		return

	var run := Utils.get_active_run()
	if run:
		run.signals.discard_started.emit(card, reason)

		# Handle blocked discards.
		if run.get_var(RunVars.Var.DISCARDS_BLOCKED) > 0:
			run.get_vars().modify_base_value(RunVars.Var.DISCARDS_BLOCKED, -1)
			if not destroy:
				return

	if not destroy:
		_insert_into_discards(card.card_type)

	_hand_cards.erase(card)
	card.playable = false
	await card.animate_disappear()

	if run:
		run.signals.discard_finished.emit(card, reason)

	card.get_parent().remove_child(card)
	if card != _processed_card:
		card.queue_free()

	_update_indicators()

func add_card_to_draw_pile(card_type: CardType, on_top: bool = true) -> void:
	if not Utils.ensure(card_type != null):
		return

	# Gameplay effect.
	var pos := 0 if on_top else _random_state.rand_int(0, _draw_pile.size())
	_draw_pile.insert(pos, card_type)

	# Animate.
	GlobalAudioSystem.play(AK.EVENTS.UI_GAMEPLAY_DRAWSTACK_SCROLL_TOP)
	var anim_card := (%AddedAnimCard as Card)
	var original_y := anim_card.position.y
	var original_scale := anim_card.scale
	anim_card.card_type = card_type
	var tween := create_tween()
	tween.tween_property(anim_card, 'modulate:a', 1, 0.1)
	tween.tween_property(anim_card, 'position:y', original_y + 50, 0.5)
	tween.parallel().tween_property(anim_card, 'scale', Vector2(original_scale / 2), 0.5)
	tween.parallel().tween_property(anim_card, 'modulate:a', 0, 0.5)
	tween.set_speed_scale(Utils.anim_speed())
	await tween.finished

	# Restore to original.
	anim_card.position.y = original_y
	anim_card.scale = original_scale

	_update_indicators()

func add_card_to_hand(card_type: CardType, reason: CardDrawReason, from_discards: bool = false) -> Card:
	if not Utils.ensure(card_type != null):
		return null

	var new_card := CARD_SCENE.instantiate_loaded_scene() as Card
	new_card.card_type = card_type
	new_card.playable = true
	# TODO: Disabled unless we get a better sound.
	#new_card.play_selection_loop = true
	new_card.practice_mode = practice_mode
	new_card.drag_started.connect(card_drag_started.emit.bind(new_card))
	new_card.drag_ended.connect(card_drag_ended.emit.bind(new_card))
	new_card.hovered.connect(_on_card_hovered.bind(new_card))
	new_card.unhovered.connect(_on_card_unhovered.bind(new_card))
	new_card.right_clicked.connect(_on_card_right_clicked.bind(new_card))
	%HandList.add_child(new_card)
	_hand_cards.append(new_card)
	GlobalSaveGame.mark_card_seen(card_type)

	await new_card.animate_appear()

	var run := Utils.get_active_run()
	if run:
		run.signals.card_added_to_hand.emit(new_card, reason, from_discards)

	_update_indicators()

	return new_card

func redraw(is_first: bool = false) -> void:
	_redrawing = true
	var run := Utils.get_active_run()
	if run:
		run.signals.redraw_started.emit(is_first)

	await discard_all()

	for i in get_hand_size():
		if _draw_pile.is_empty() and _discard_pile.is_empty():
			break
		await draw(CardDrawReason.REDRAW)

	_redrawing = false
	if run:
		run.signals.redraw_finished.emit(is_first)

func discard_all() -> void:
	if _hand_cards:
		var last_card := _hand_cards[-1]
		for card: Card in _hand_cards.slice(0, -1):  # Copied, since hand changes.
			discard(card, DiscardReason.REDRAW)
		await discard(last_card, DiscardReason.REDRAW)
		Utils.ensure(not _hand_cards)

func move_card_from_draw_to_discard(draw_pile_index: int) -> void:
	if not Utils.ensure(draw_pile_index < _draw_pile.size()):
		return
	var card_type := _draw_pile[draw_pile_index]
	_insert_into_discards(card_type)
	_draw_pile.remove_at(draw_pile_index)
	_update_indicators()

func draw_specific_card(card_type: CardType, reason: CardDrawReason, from_discards: bool = false) -> void:
	var run := Utils.get_active_run()
	var pool := _discard_pile if from_discards else _draw_pile
	var index := pool.find(card_type)
	if not Utils.ensure(index >= 0):
		return
	pool.remove_at(index)
	var new_card := await add_card_to_hand(card_type, reason, false)
	if run:
		run.signals.card_drawn.emit(new_card, reason, false)

func animated_hand_size_change(positive: bool) -> void:
	GlobalAudioSystem.play(AK.EVENTS.UI_GAMEPLAY_GOAL_GAIN_ALL)
	var overlay := %HandSizeAnimationOverlay as Control
	overlay.modulate = Color(0.114, 0.761, 0.157) if positive else Color(0.89, 0.212, 0.212)
	overlay.modulate.a = 0
	var tween := create_tween()
	tween.tween_property(overlay, 'modulate:a', 1, 0.8).set_ease(Tween.EASE_IN)
	tween.tween_interval(0.2)
	tween.tween_property(overlay, 'modulate:a', 0, 0.6).set_ease(Tween.EASE_OUT)
	tween.set_speed_scale(Utils.anim_speed())
	tween.play()
	await tween.finished

# Internals

func _insert_into_discards(card_type: CardType) -> void:
	var index := _random_state.rand_int(0, _discard_pile.size())
	_discard_pile.insert(index, card_type)

func _on_card_hovered(card: Card) -> void:
	_hovered_card = card
	card_hover_changed.emit()

func _on_card_unhovered(card: Card) -> void:
	if _hovered_card == card:
		_hovered_card = null
	card_hover_changed.emit()

func _on_card_right_clicked(card: Card) -> void:
	card_right_clicked.emit(card)

func _update_indicators() -> void:
	(%DrawPileCount as Label).text = str(_draw_pile.size())
	(%DiscardPileCount as Label).text = str(_discard_pile.size())
	(%DiscardPileCount as Label).visible = _discard_pile.size() > 0

	# Aspect counts.
	var counts: Dictionary[AspectType, int] = {}
	for card_type in _draw_pile:
		for aspect_type in card_type.aspects:
			counts[aspect_type] = counts.get(aspect_type, 0) + 1
	var counters: Array[AspectCounter] = [
		%AspectCounter_Life,
		%AspectCounter_Stability,
		%AspectCounter_Change,
		%AspectCounter_Craft,
		%AspectCounter_Connection,
		%AspectCounter_Illumination,
		%AspectCounter_Spirit,
	]
	for counter: AspectCounter in counters:
		counter.count = counts.get(counter.aspect_type, 0)

func _on_view_deck_button_mouse_entered() -> void:
	_deck_button_hovered = true
	_update_deck_highlight()

func _on_view_deck_button_mouse_exited() -> void:
	_deck_button_hovered = false
	_update_deck_highlight()

func _on_view_deck_button_pressed() -> void:
	GlobalAudioSystem.play(AK.EVENTS.UI_GAMEPLAY_SELECT_DRAWSTACK_SELECT)
	_draw_deck_viewer = DECK_VIEWER_SCENE.instantiate_loaded_scene() as CardDeckViewer
	_draw_deck_viewer.title = tr('Draw Stack')
	_draw_deck_viewer.practice_mode = practice_mode
	_draw_deck_viewer.cards = (%CardDeck as CardDeck).get_draw_pile_cards().duplicate()
	var run := Utils.get_active_run()
	if not run or not run.get_var(RunVars.Var.DRAW_DECK_ORDERED):
		_draw_deck_viewer.cards.shuffle()
		_draw_deck_viewer.cards.sort_custom(CardType.compare)
	GlobalUI.add_layer_content(_draw_deck_viewer, UI.Layer.GAME_MENU)

func _on_view_discard_button_mouse_entered() -> void:
	GlobalAudioSystem.play(AK.EVENTS.UI_GAMEPLAY_SELECT_DRAWSTACK_HOVER)

func _on_view_discard_button_pressed() -> void:
	GlobalAudioSystem.play(AK.EVENTS.UI_GAMEPLAY_SELECT_DRAWSTACK_SELECT)
	_discard_deck_viewer = DECK_VIEWER_SCENE.instantiate_loaded_scene() as CardDeckViewer
	_discard_deck_viewer.title = tr('Discards')
	_discard_deck_viewer.practice_mode = practice_mode
	_discard_deck_viewer.cards = (%CardDeck as CardDeck).get_discard_pile_cards().duplicate()
	_discard_deck_viewer.cards.shuffle()
	_discard_deck_viewer.cards.sort_custom(CardType.compare)
	GlobalUI.add_layer_content(_discard_deck_viewer, UI.Layer.GAME_MENU)

func _make_tooltip_text() -> String:
	var text := '<related_term:hand_size>'

	var term := load('res://glossary/terms/standalone/term_draw_pile.tres') as Term
	text += (tr('<header_font_size>[b]%s[/b][/font_size]\n\n%s') %
			[term.get_term_name(true), term.get_markedup_description()])

	text += '\n\n'
	if _draw_pile.size() == 0:
		text += 'There are currently [b]no[/b] <term_lower:glyph>s in your <term_lower:draw_pile>.'
	else:
		text += tr_n(
			'There is currently [b]%d[/b] <term_lower:glyph> in your <term_lower:draw_pile>.',
			'There are currently [b]%d[/b] <term_lower:glyph>s in your <term_lower:draw_pile>.',
			_draw_pile.size()) % _draw_pile.size()
	if _draw_pile.size() == 0:
		text += tr(' You will reshuffle your <term:discard_pile> into the <term:draw_pile> the next time your <term_lower:draw>.')

	var hand_size := get_hand_size()
	text += tr('\n\nYour current <term_lower:hand_size> is [b]%d[/b],') % get_hand_size()
	text += tr(' so you will <term_lower:draw> [b]%d[/b] <term_lower:glyph>s next time you <term_lower:redraw>.') % hand_size
	text += '\n\n' + tr('[i]%s to view the <term_lower:glyph>s in your <term_lower:draw_pile>.[/i]') % InputPrompts.get_input_markup(
				InputPrompts.InputType.LEFT_CLICK)

	return text

func _make_discards_tooltip_text() -> String:
	var term := load('res://glossary/terms/standalone/term_discard_pile.tres') as Term
	var text := ('<header_font_size>[b]%s[/b][/font_size]\n\n%s' %
			[term.get_term_name(true), term.get_markedup_description()])

	var count_text: String = 'are currently [b]%d[/b] <term_lower:glyph>s' % _draw_pile.size()
	if _discard_pile.size() == 0:
		count_text = 'are currently [b]no[/b] <term_lower:glyph>s'
	elif _discard_pile.size() == 1:
		count_text = 'is currently [b]1[/b] <term_lower:glyph>'
	text += '\n\nThere %s in your <term_lower:discard_pile>.' % count_text

	text += '\n\n'
	if _draw_pile.size() == 0:
		text += 'There are currently [b]no[/b] <term_lower:glyph>s in your <term_lower:discard_pile>.'
	else:
		text += tr_n(
			'There is currently [b]%d[/b] <term_lower:glyph> in your <term_lower:discard_pile>.',
			'There are currently [b]%d[/b] <term_lower:glyph>s in your <term_lower:discard_pile>.',
			_discard_pile.size()) % _discard_pile.size()

	text += '\n\n' + tr('[i]%s to view the <term_lower:glyph>s in your <term_lower:discard_pile>.[/i]') % InputPrompts.get_input_markup(
				InputPrompts.InputType.LEFT_CLICK)

	return text

func _on_aspect_counter_mouse_entered() -> void:
	_aspect_counter_hovered = true
	_update_deck_highlight()

func _on_aspect_counter_mouse_exited() -> void:
	_aspect_counter_hovered = false
	_update_deck_highlight()

func _update_deck_highlight() -> void:
	var should_highlight := _deck_button_hovered or _aspect_counter_hovered
	if should_highlight:
		if not (%ViewDeckButton as Control).modulate.a:
			GlobalAudioSystem.play(AK.EVENTS.UI_GAMEPLAY_SELECT_DRAWSTACK_HOVER)
		(%ViewDeckButton as Control).modulate.a = 1
	else:
		(%ViewDeckButton as Control).modulate.a = 0

func _on_sort_button_pressed() -> void:
	var sorted_cards := %HandList.get_children()
	sorted_cards.sort_custom(func(a: Card, b: Card) -> bool:
		return CardType.compare(a.card_type, b.card_type)
	)
	for i in sorted_cards.size():
		%HandList.move_child(sorted_cards[i], i)

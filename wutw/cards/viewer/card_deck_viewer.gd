class_name CardDeckViewer
extends Node2D

signal card_selected(card: Card)
signal canceled
signal closed

static var CARD_SCENE := AsyncLoadedResource.new('res://cards/card.tscn')

const MINIMIZE_BUTTON_ANIMATION_DURATION := 0.15
const MINIMIZE_ANIMATION_DURATION := 0.6

@export var cards: Array[CardType]:
	set(value):
		cards = value
		if is_node_ready():
			_update()
@export var title: String = tr('Glyph Deck'):
	set(value):
		title = value
		if is_node_ready():
			_update()
@export var close_button_label: String = tr('Close'):
	set(value):
		close_button_label = value
		if is_node_ready():
			_update()
@export var allow_card_selection: bool = false
@export var allow_quick_dismiss: bool = true
@export var show_minimize_button: bool = false
@export var practice_mode: bool = false

var _closing := false
var _minimize_tween: Tween
var _minimized: bool = false

func _ready() -> void:
	_update()
	for aspect in AspectType.get_all_types():
		(%AspectFilterDropdown as Dropdown).add_item(aspect.get_term_tag(), aspect)
	(%ScrollPanel as ScrollPanel).animate_unroll()
	if show_minimize_button:
		(%MinimizeButton as Control).visible = true
		var tween := create_tween()
		(%MinimizeButton as Control).modulate.a = 0.0
		tween.tween_property(%MinimizeButton, 'modulate:a', 0.75, 0.5)
		tween.play()
	else:
		(%MinimizeButton as Control).visible = false

func _enter_tree() -> void:
	UI.register_zoomable(%ScrollPanel as ScrollPanel, 0.5, 0.5)
	GlobalAudioSystem.is_in_deck_menu = true

func _exit_tree() -> void:
	GlobalAudioSystem.is_in_deck_menu = false

func _shortcut_input(input_event: InputEvent) -> void:
	if show_minimize_button and input_event.is_action_pressed('minimize', false):
		_on_minimize_button_pressed()
		get_viewport().set_input_as_handled()

func _on_bg_clicked() -> void:
	if allow_quick_dismiss:
		_on_close_button_pressed()

func _handle_esc() -> bool:
	if allow_quick_dismiss:
		close()
	return true

func get_main_control() -> Control:
	return %CenterContainer as Control

func close() -> void:
	if not _closing:
		_closing = true
		Utils.set_input_enabled(get_main_control(), false)
		(%BG as FadedBackground).fade_out()
		if show_minimize_button:
			var tween := create_tween()
			tween.tween_property(%MinimizeButton, 'modulate:a', 0.0, 0.5)
			tween.play()
		await (%ScrollPanel as ScrollPanel).animate_roll()
		queue_free()
		closed.emit()

func _update() -> void:
	(%TitleLabel as Label).text = title
	(%CloseButton as Button).text = close_button_label

	# HACK: Guess whether we should show innate card markers.
	var to_mark_innate: Array[CardType]
	var run := Utils.get_active_run()
	if run and run.get_innate_cards() and cards.size() == run.get_deck_cards().size():
		var matched_all := true
		for card in cards:
			if card not in run.get_deck_cards():
				matched_all = false
				break
		if matched_all:
			to_mark_innate = run.get_innate_cards()

	(%AspectCountersPanel as AspectCountersPanel).card_types = cards
	if cards.size() <= 1:
		(%TotalCountLabel as Label).text = ''
	else:
		(%TotalCountLabel as Label).text = tr('%s total glyphs') % cards.size()

	# Create the cards.
	Utils.clear_node(%CardList)
	for card_type in cards:
		var new_card := CARD_SCENE.instantiate_loaded_scene() as Card
		new_card.card_type = card_type
		new_card.playable = false
		new_card.practice_mode = practice_mode
		if card_type in to_mark_innate:
			new_card.display_state = Card.DisplayState.INNATE
			to_mark_innate.erase(card_type)
		new_card.selected.connect(_on_card_selected.bind(new_card))
		%CardList.add_child(new_card)
		await get_tree().process_frame  # Avoid stutter.

func _on_close_button_pressed() -> void:
	canceled.emit()
	close()

func _on_card_selected(card: Card) -> void:
	if allow_card_selection:
		card_selected.emit(card)
	else:
		card.is_selected = false  # Hacky way to prevent selection.

func _on_search_input_text_changed(_new_text: String) -> void:
	_update_filter()

func _on_aspect_filter_dropdown_selected(_item: DropdownItem) -> void:
	_update_filter()

func _update_filter() -> void:
	var aspect_filter := (%AspectFilterDropdown as Dropdown).get_selected_value() as AspectType
	(%FilterLabel as Control).visible = false
	for card: Card in %CardList.get_children():
		var passes_filter := Utils.matches_query(card.card_type.get_search_text(), (%SearchInput as LineEdit).text)
		if passes_filter and aspect_filter:
			if aspect_filter not in card.card_type.aspects:
				passes_filter = false
		if not passes_filter:
			(%FilterLabel as Control).visible = true
		card.visible = passes_filter

func _extract_text(card_type: CardType) -> Array[String]:
	var result: Array[String] = [card_type.card_name, card_type.symbol]
	for aspect in card_type.aspects:
		result.append(aspect.name)
	for ability in card_type.abilities:
		result.append(ability.get_search_text())
	return result

func _on_minimize_button_pressed() -> void:
	Utils.set_input_enabled(%ScrollPanel as Control, false)
	Utils.set_input_enabled(%MinimizeButton as Control, false)
	_minimize_tween = create_tween()
	if _minimized:
		(%BG as Control).mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
		_minimize_tween.set_ease(Tween.EASE_OUT)
		var visible_y := (%CenterContainer as Control).position.y - 1000
		_minimize_tween.tween_property(%CenterContainer, 'position:y', visible_y, MINIMIZE_ANIMATION_DURATION)
		_minimize_tween.parallel().tween_property(%BG, 'modulate:a', 1.0, MINIMIZE_ANIMATION_DURATION)
		_minimize_tween.parallel().tween_property(%MinimizeButton, 'modulate:a', 0.9, MINIMIZE_ANIMATION_DURATION)
	else:
		(%BG as Control).mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
		_minimize_tween.set_ease(Tween.EASE_IN)
		var hidden_y := (%CenterContainer as Control).position.y + 1000
		_minimize_tween.tween_property(%CenterContainer, 'position:y', hidden_y, MINIMIZE_ANIMATION_DURATION)
		_minimize_tween.parallel().tween_property(%BG, 'modulate:a', 0.2, MINIMIZE_ANIMATION_DURATION)
		_minimize_tween.parallel().tween_property(%MinimizeButton, 'modulate:a', 0.5, MINIMIZE_ANIMATION_DURATION)
	_minimize_tween.parallel().tween_callback(func() -> void:
		await get_tree().create_timer(MINIMIZE_ANIMATION_DURATION * 0.3).timeout
		(%MinimizeButton as Button).icon = (
			load('res://events/system/scenes/minimize_arrow_down.png') if _minimized
			else load('res://events/system/scenes/minimize_arrow_up.png'))
		(%MinimizeButton as Button).text = tr('Hide') if _minimized else tr('Show')
		_minimized = not _minimized
	)
	_minimize_tween.set_speed_scale(Utils.anim_speed())
	_minimize_tween.play()
	await _minimize_tween.finished
	Utils.set_input_enabled(%ScrollPanel as Control, true)
	Utils.set_input_enabled(%MinimizeButton as Control, true)

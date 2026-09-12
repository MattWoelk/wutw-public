class_name DialogueDisplay
extends Node2D

signal finished

const TIME_PER_CHAR := 0.035
const NAME_ANIMATION_WAIT := 0.1
const LINE_ANIMATION_WAIT := 0.5
const DIALOGUE_TEXT_SPEED := 3.0

@export var dialogue: Dialogue

var _pages: Array[Dialogue.Page]
var _current_page_index := 0
var _current_line_index := 0
var _reveal_tween: Tween
var _last_line: Dialogue.Line
var _sfx_playing_id: int = 0

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_pages = dialogue.get_pages()
	Utils.set_input_enabled(%ScrollPanel as Control, false)
	_start_page(_pages[0], true)
	GlobalSaveGame.mark_dialogue_seen(dialogue)

func _enter_tree() -> void:
	GlobalAudioSystem.is_in_dialog = true

func _exit_tree() -> void:
	_stop_sfx()
	GlobalAudioSystem.is_in_dialog = false

func _update_font_size() -> void:
	Utils._scale_font_size(%RichText as RichTextLabel, false, 18)

func _start_page(page: Dialogue.Page, first: bool) -> void:
	# Setup portraits.
	var portrait1 := %PortraitDisplay1 as DialoguePortraitDisplay
	var portrait2 := %PortraitDisplay2 as DialoguePortraitDisplay
	portrait1.modulate.a = 0
	portrait2.modulate.a = 0
	if page.characters.size() > 0:
		portrait1.modulate.a = 1
		portrait1.character = page.characters[0]
		if page.characters.size() > 1:
			Utils.ensure(page.characters.size() == 2)
			portrait2.modulate.a = 1
			portrait2.character = page.characters[1]

	# Setup buttons.
	(%ContinueButton as Button).mouse_filter = Control.MOUSE_FILTER_IGNORE
	(%ContinueButton as Button).modulate.a = 0
	(%SkipButton as Button).visible = true

	# Start page.
	var scroll_panel := %ScrollPanel as ScrollPanel
	(%RichText as RichTextLabel).text = ''
	await scroll_panel.animate_unroll(scroll_panel.default_unroll_duration, first)
	(%RichText as RichTextLabel).visible_characters = 0
	Utils.set_input_enabled(scroll_panel, true)
	_last_line = null
	_current_line_index = 0
	_reveal_next_line()

func _reveal_next_line() -> void:
	var portrait1 := %PortraitDisplay1 as DialoguePortraitDisplay
	var portrait2 := %PortraitDisplay2 as DialoguePortraitDisplay
	if _current_line_index >= _pages[_current_page_index].lines.size():
		portrait1.highlighted = false
		portrait2.highlighted = false
		(%ContinueButton as Button).mouse_filter = Control.MOUSE_FILTER_STOP
		(%ContinueButton as Button).modulate.a = 1
		(%SkipButton as Button).visible = false
	else:
		var line := _pages[_current_page_index].lines[_current_line_index]
		_run_reveal_tween(line, not _last_line or _last_line.character != line.character)
		portrait1.highlighted = portrait1.character == line.character
		portrait2.highlighted = portrait2.character == line.character
		_current_line_index += 1
		_last_line = line

func _run_reveal_tween(line: Dialogue.Line, show_name: bool) -> void:
	Utils.ensure(not _reveal_tween or not _reveal_tween.is_running())
	var label := %RichText as RichTextLabel
	_reveal_tween = create_tween()
	var revealed_length := label.visible_characters
	if show_name:
		label.text += '[b][font_size=%d]%s[/font_size][/b]\n' % [
			roundi(22 * GameSettings.Interface.paragraph_font_scale.value()),
			tr(line.character.character_name)]
		await get_tree().process_frame  # Let size update.
		var name_duration := TIME_PER_CHAR * line.character.character_name.length()
		_reveal_tween.tween_callback(_start_sfx)
		_reveal_tween.tween_property(label, 'visible_characters', label.get_total_character_count(), name_duration)
		_reveal_tween.tween_callback(_stop_sfx)
		_reveal_tween.tween_interval(NAME_ANIMATION_WAIT)
		revealed_length = label.get_total_character_count()
	label.text += line.text
	if _current_line_index < _pages[_current_page_index].lines.size():
		label.text += '\n\n'
	var text_duration := TIME_PER_CHAR * (label.get_total_character_count() - revealed_length)
	_reveal_tween.tween_callback(_start_sfx)
	_reveal_tween.tween_property(label, 'visible_characters', label.get_total_character_count(), text_duration)
	_reveal_tween.tween_callback(_stop_sfx)
	_reveal_tween.tween_interval(LINE_ANIMATION_WAIT)

	_reveal_tween.set_speed_scale(Utils.anim_speed())
	_reveal_tween.play()

	# Auto-scroll if needed.
	await get_tree().process_frame  # Let size update.
	var scroll_amount := label.size.y - (%ScrollContainer as Control).size.y
	if scroll_amount > 0:
		var scroll_tween := create_tween()
		scroll_tween.parallel().tween_property(%ScrollContainer, 'scroll_vertical', scroll_amount, 0.2).set_ease(Tween.EASE_OUT)
		scroll_tween.play()

	# Auto end on last line.
	_reveal_tween.finished.connect(func() -> void:
		if _current_line_index >= _pages[_current_page_index].lines.size():
			_reveal_next_line()
	)

func _on_skip_button_pressed() -> void:
	if Utils.ensure(_reveal_tween != null):
		if _reveal_tween.is_running():
			_reveal_tween.set_speed_scale(100)
			await _reveal_tween.finished
	_reveal_next_line()

func _start_sfx() -> void:
	GlobalAudioSystem.set_parameter(AK.GAME_PARAMETERS.TEXT_SPEED, DIALOGUE_TEXT_SPEED)
	_stop_sfx()
	_sfx_playing_id = GlobalAudioSystem.start_loop(AK.EVENTS.UI_DIALOGUE_TEXT_LOOP)

func _stop_sfx() -> void:
	if _sfx_playing_id:
		GlobalAudioSystem.stop_loop(_sfx_playing_id)
		_sfx_playing_id = 0

func _on_continue_button_pressed() -> void:
	Utils.set_input_enabled(%ScrollPanel as ScrollPanel, false)
	_current_page_index += 1
	if _current_page_index >= _pages.size():
		(%BG as FadedBackground).fade_out()
		await (%ScrollPanel as ScrollPanel).animate_roll()
		finished.emit()
		queue_free()
	else:
		var scroll_panel := %ScrollPanel as ScrollPanel
		await scroll_panel.animate_roll(scroll_panel.default_roll_duration, false)
		_start_page(_pages[_current_page_index], false)

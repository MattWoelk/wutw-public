@tool
class_name SpeechBubble
extends Tooltip

const TIME_PER_CHAR := 0.035
const DIALOGUE_TEXT_SPEED := 3.0

enum State {HIDDEN, APPEARING, VISIBLE_EMPTY, REVEALING_TEXT, REVEALED, HIDING}

var hub_character: HubCharacter:
	set(value):
		hub_character = value
		_update()
var is_flipped: bool = false:
	set(value):
		is_flipped = value
		_update()
var hide_text: bool = false:
	set(value):
		hide_text = value
		_update()
var interactive: bool = false:
	set(value):
		interactive = value
		_update()

var _state: State = State.HIDDEN
var _reveal_tween: Tween
var _sfx_playing_id: int = 0

func _ready() -> void:
	super._ready()
	material = null  # Override UkiyoePanelContainer
	_update()

func _process(_delta: float) -> void:
	# Skip super._process() to avoid reacting to Ctrl.
	if not _attached_to and not _hiding:
		hide_tooltip()
	_position()
	var label := %MarkedUpLabel as MarkedUpLabel
	label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT if ' ' in _markedup_text else HORIZONTAL_ALIGNMENT_CENTER)

func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event:
		return
	if not mouse_event.pressed:
		return
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if _state == State.REVEALING_TEXT:
		fast_forward()
	elif _state == State.REVEALED:
		hide_tooltip()

func _exit_tree() -> void:
	_stop_sfx()  # Just in case.

func show_line(text: String) -> void:  # Input already translated.
	_markedup_text = ' ' if text.is_empty() else text

	if _state == State.APPEARING:
		_appear_tween.kill()  # Cancels previous await.
		_state = State.HIDDEN

	if _state in [State.HIDDEN, State.HIDING]:
		_state = State.APPEARING
		await super.show_tooltip()
		_state = State.VISIBLE_EMPTY

	if _state == State.REVEALING_TEXT:
		if Utils.ensure(_reveal_tween != null):
			_reveal_tween.kill()
		_state = State.VISIBLE_EMPTY

	if _state == State.REVEALED:
		_state = State.VISIBLE_EMPTY

	await _reveal_text()

func fast_forward() -> void:
	if _state == State.REVEALING_TEXT:
		_reveal_tween.set_speed_scale(999)

func get_state() -> State:
	return _state

func hide_tooltip(_stop_processing: bool = true) -> void:
	if _state == State.HIDING or _state == State.HIDDEN:
		return
	if _reveal_tween:
		_reveal_tween.kill()
	_stop_sfx()
	_state = State.HIDING
	await super.hide_tooltip(false)
	set_process(false)  # After it's already hidden, unlike the superclass.
	_state = State.HIDDEN

func _update() -> void:
	if not hub_character:
		return
	var spec := hub_character.character
	var character := spec.get_character()

	if hide_text:
		(%TextContainer as Control).visible = false
	else:
		(%TextContainer as Control).visible = true
		if spec.main_character:
			(%NameLabel as Label).text = tr(character.character_name)
		else:
			var job_name := tr(hub_character.job.job_name)
			if spec.gender == HubCharacterSpec.Gender.FEMALE and hub_character.job.female_job_name_override:
				job_name = tr(hub_character.job.female_job_name_override)
			(%NameLabel as Label).text = tr(hub_character.first_name) + ', ' + job_name

	(%Portrait as TextureRect).texture = character.dialogue_portrait
	(%PortraitContainer as Control).visible = character.dialogue_portrait != null
	(%Portrait as TextureRect).flip_h = is_flipped
	(%DirectionHBox as HBoxContainer).layout_direction = Control.LAYOUT_DIRECTION_RTL if is_flipped else Control.LAYOUT_DIRECTION_LTR

	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED if interactive else Control.MOUSE_BEHAVIOR_DISABLED

func _setup_text() -> void:
	var font_size := roundi(16 * GameSettings.Interface.paragraph_font_scale.value())
	(%NameLabel as Label).add_theme_font_size_override('font_size', font_size)
	var label := %MarkedUpLabel as MarkedUpLabel
	Utils._scale_font_size(label, false, 16)
	label.set_markedup_text(_markedup_text, MarkedUpLabel.LinkMode.NONE)
	label.visible_characters = 0

func _setup_extras(_direction: RelativeDirection) -> void:
	# No extras to setup, so skip parent's method.
	pass

func _position() -> void:
	# Override: hardcode direction, avoid irrelevant code (extras, etc.), and hide when out of view.
	if not _attached_to:  # Tween callback called after the node is freed.
		return
	var control_global_rect := Utils.get_screen_rect(_rect_control if _rect_control else _attached_to)
	var viewport_rect := _attached_to.get_viewport_rect()

	var pos := _try_compute_position(control_global_rect, viewport_rect, size, Tooltip.RelativeDirection.ABOVE, _preferred_alignments[0])
	global_position = pos + _get_margin(Tooltip.RelativeDirection.ABOVE)

	if not viewport_rect.has_point(pos + size / 2.0) and interactive:
		# IMPORTANT: Only do this for interactive bubbles, or it breaks cutscenes.
		hide_tooltip()

func _try_compute_position(control_rect: Rect2, _viewport_rect: Rect2, tooltip_size: Vector2,
 							_direction: RelativeDirection, alignment: Alignment) -> Vector2:
	# Override: don't adjust to fit viewport, and hardcode direction.
	var pos := Vector2(-1, -1)
	pos.y = control_rect.position.y - tooltip_size.y
	match alignment:
		Alignment.BEGIN:
			pos.x = control_rect.position.x
		Alignment.CENTERED:
			pos.x = control_rect.position.x + (control_rect.size.x - tooltip_size.x) * 0.5
		Alignment.END:
			pos.x = control_rect.position.x + control_rect.size.x - tooltip_size.x
	return pos

func _reveal_text() -> void:
	if not Utils.ensure(_state == State.VISIBLE_EMPTY):
		return

	_state = State.REVEALING_TEXT
	var label := %MarkedUpLabel as MarkedUpLabel
	_setup_text()
	var text_duration := TIME_PER_CHAR * label.get_total_character_count()
	if _markedup_text == '...':
		text_duration = TIME_PER_CHAR * 30

	_reveal_tween = create_tween()
	_reveal_tween.tween_callback(_start_sfx)
	_reveal_tween.tween_property(label, 'visible_characters', label.get_total_character_count(), text_duration)
	_reveal_tween.tween_callback(_stop_sfx)
	_reveal_tween.set_speed_scale(Utils.anim_speed())
	_reveal_tween.play()

	await _reveal_tween.finished

	if _state == State.REVEALING_TEXT:  # Not hidden while revealing.
		_state = State.REVEALED

func _start_sfx() -> void:
	GlobalAudioSystem.set_parameter(AK.GAME_PARAMETERS.TEXT_SPEED, DIALOGUE_TEXT_SPEED)
	_stop_sfx()
	_sfx_playing_id = GlobalAudioSystem.start_loop(AK.EVENTS.UI_DIALOGUE_TEXT_LOOP)

func _stop_sfx() -> void:
	if _sfx_playing_id:
		GlobalAudioSystem.stop_loop(_sfx_playing_id)
		_sfx_playing_id = 0

@tool
class_name BlanksPracticeProblem
extends UkiyoePanelContainer

signal solved

static var PRACTICE_TOKEN_SCENE := AsyncLoadedResource.new('res://japanese/practice_blanks/practice_token.tscn', true, AsyncLoadedResource.LoadPhase.SPECULATIVE)

const ANIM_DURATION := 0.2

@export var prompt: String:
	set(value):
		prompt = value
		if is_node_ready():
			_update()
@export var tokens: Array[JapaneseToken]:
	set(value):
		tokens = value
		if is_node_ready():
			_update()
@export var kanji_blanks: Array[String]:
	set(value):
		kanji_blanks = value
		if is_node_ready():
			_update()
@export var universal_probability: float = 0.1:
	set(value):
		universal_probability = value
		if is_node_ready():
			_update()
@export var hide_native: bool = false:
	set(value):
		hide_native = value
		if is_node_ready():
			_update()

var _practice_tokens: Array[PracticeToken]
var _faded_out := false
var _solved := false
var _state_tween: Tween
var _mistake_tween: Tween

func _ready() -> void:
	super._ready()
	_update()

	if not Utils.is_in_editor():
		var accepted_aspects: Array[AspectType]
		for slot in get_aspect_slots():
			if slot.is_universal:
				accepted_aspects.assign(AspectType.get_all_types())
				break
			elif slot.aspect_type not in accepted_aspects:
				accepted_aspects.append(slot.aspect_type)
		mouse_entered.connect(_request_slots)
		mouse_exited.connect(_retract_slot_request)
		tree_exiting.connect(_retract_slot_request)
		GlobalContextHighlight.offer_changed.connect(func(offered: ContextHighlight.Context) -> void:
			if offered and offered.aspect_types:
				var any_matched := false
				for slot in get_aspect_slots():
					if not slot.is_filled and slot.can_be_filled_by(offered.aspect_types):
						any_matched = true
						break
				set_faded_out(not any_matched)
			else:
				set_faded_out(false)
		)

	if kanji_blanks.size() > 1:
		GlobalTooltipSystem.attach(self, func() -> String:
			return tr('Get a bonus <term_lower:insight> for solving this one!')
		, [Tooltip.RelativeDirection.ABOVE], [Tooltip.Alignment.CENTERED])
		await get_tree().process_frame
		var outline := %OutlineContainer as Control
		_set_outline_shape(%VFX_Top as GPUParticles2D, Rect2(0, 0, outline.size.x, 0.1))
		_set_outline_shape(%VFX_Bottom as GPUParticles2D, Rect2(0, outline.size.y, outline.size.x, 0.1))
		_set_outline_shape(%VFX_Left as GPUParticles2D, Rect2(0, 0, 0.1, outline.size.y))
		_set_outline_shape(%VFX_Right as GPUParticles2D, Rect2(outline.size.x, 0, 0.1, outline.size.y))
		for vfx: GPUParticles2D in outline.get_children():
			vfx.emitting = true

	await get_tree().process_frame  # Let sizing finish.
	_setup_zoomable()

func _gui_input(event: InputEvent) -> void:
	if not _solved:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event:
		return
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		var answer := ''
		for token in tokens:
			answer += token.raw_text
		DisplayServer.clipboard_set(prompt + '\n' + answer)

func get_aspect_slots() -> Array[AspectSlot]:
	var result: Array[AspectSlot]
	for practice_token in _practice_tokens:
		result.append_array(practice_token.get_aspect_slots())
	return result

func get_kanji_slots() -> Array[KanjiSlot]:
	var result: Array[KanjiSlot]
	for practice_token in _practice_tokens:
		result.append_array(practice_token.get_kanji_slots())
	return result

func set_faded_out(is_faded_out: bool) -> void:
	_faded_out = is_faded_out
	_update_state_style()

func play_mistake_anim() -> void:
	GlobalAudioSystem.play(AK.EVENTS.UI_GAMEPLAY_INSPIRATION_LOST)
	if _mistake_tween:
		_mistake_tween.kill()
	_mistake_tween = create_tween()
	_mistake_tween.set_ease(Tween.EASE_OUT)
	_mistake_tween.set_trans(Tween.TRANS_QUINT)
	_mistake_tween.tween_property(%MistakeFlasher, 'color', Color('#ffa0a0ff'), 0.2)
	_mistake_tween.tween_interval(0.5)
	_mistake_tween.tween_property(%MistakeFlasher, 'color', Color.WHITE, 0.5)
	_mistake_tween.set_speed_scale(Utils.anim_speed())
	_mistake_tween.play()

func is_solved() -> bool:
	return _solved

func _update_state_style() -> void:
	if _state_tween:
		_state_tween.kill()
	_state_tween = create_tween()
	_state_tween.tween_property(self, 'modulate:a', 0.35 if _faded_out else 1.0, ANIM_DURATION)
	_state_tween.parallel().tween_property(self, 'self_modulate', Color(1.2, 1.2, 1.2, 1) if _solved else Color(1.0, 1.0, 1.0, 1), ANIM_DURATION)
	_state_tween.play()

	if _faded_out:
		mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	else:
		mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED

func _update() -> void:
	if not prompt or not tokens:
		return
	(%NativeLabel as Label).text = prompt
	if hide_native:
		(%NativeLabel as Label).modulate.a = 0 if hide_native else 1

	Utils.clear_node(%JapaneseBox)
	var remaining_kanji_blanks := kanji_blanks.duplicate()
	for token in tokens:
		var practice_token := PRACTICE_TOKEN_SCENE.instantiate_loaded_scene() as PracticeToken
		practice_token.japanese = token.raw_text
		practice_token.reading = token.reading
		practice_token.vocab = token.vocab
		for c in token.raw_text:
			if c in remaining_kanji_blanks:
				practice_token.kanji_blanks.append(c)
				remaining_kanji_blanks.erase(c)
		practice_token.universal_probability = universal_probability
		practice_token.slot_filled.connect(_on_slot_filled)
		_practice_tokens.append(practice_token)
		%JapaneseBox.add_child(practice_token)

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	assert(data is Card)
	return SlotUtils.match_slot(get_aspect_slots(), (data as Card).card_type.aspects, true) != null

func _drop_data(_pos: Vector2, data: Variant) -> void:
	assert(data is Card)
	var slot := SlotUtils.match_slot(get_aspect_slots(), (data as Card).card_type.aspects, true)
	assert(slot)
	slot.card_dropped.emit(data as Card)

func _on_slot_filled() -> void:
	for slot in get_aspect_slots():
		if not slot.is_filled:
			return
	mark_solved()
	for practice_token in _practice_tokens:
		practice_token.mark_solved()
	solved.emit()

func mark_solved() -> void:
	_solved = true
	(%NativeLabel as Label).modulate.a = 1
	_update_state_style()
	for vfx: GPUParticles2D in %OutlineContainer.get_children():
		vfx.emitting = false
	if GlobalTooltipSystem.has_attached_tooltip(self):
		GlobalTooltipSystem.detach(self)

func _request_slots() -> void:
	var accepted_aspects: Array[AspectType]
	for slot in get_aspect_slots():
		if not slot.is_filled:
			if slot.is_universal:
				accepted_aspects.assign(AspectType.get_all_types())
				break
			else:
				accepted_aspects.append(slot.aspect_type)
	GlobalContextHighlight.request(ContextHighlight.aspects(self, accepted_aspects))

func _retract_slot_request() -> void:
	GlobalContextHighlight.retract_request(self)

func _set_outline_shape(vfx: GPUParticles2D, shape: Rect2) -> void:
	vfx.process_material = vfx.process_material.duplicate()
	var mat := vfx.process_material as ParticleProcessMaterial
	mat.emission_shape_offset.x = shape.get_center().x
	mat.emission_shape_offset.y = shape.get_center().y
	mat.emission_box_extents.x = shape.size.x / 2.0
	mat.emission_box_extents.y = shape.size.y / 2.0

func _setup_zoomable() -> void:
	var self_rect := Utils.get_screen_rect(self)
	var parent_rect := Utils.get_screen_rect(get_parent() as Control)
	var x_pivot := remap(self_rect.get_center().x, parent_rect.position.x, parent_rect.end.x, 0, 1)
	var y_pivot := remap(self_rect.get_center().y, parent_rect.position.y, parent_rect.end.y, 0, 1)
	UI.register_zoomable(self, x_pivot, y_pivot)

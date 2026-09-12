@tool
class_name AspectSlot
extends Control

signal filled
signal cleared
signal card_dropped(card: Card)

enum State { NORMAL, HIGHLIGHTED, FADED_OUT }

@export var aspect_type: AspectType:
	set(value):
		aspect_type = value
		_update_style()
@export var is_filled: bool:
	set(value):
		if is_filled == value:
			return
		is_filled = value
		_update_style()
		if is_filled:
			var visible_at_time_of_fill := is_visible_in_tree()
			filled.emit()
			var run := Utils.get_active_run()
			if run and visible_at_time_of_fill:
				# HACK: Hidden double-lack recipes shouldn't trigger relics.
				# TODO: Find a cleaner solution.
				run.signals.aspect_slot_filled.emit(self)
		else:
			cleared.emit()
@export var state: State = State.NORMAL:
	set(value):
		state = value
		_update_style()
@export var is_universal: bool:
	set(value):
		is_universal = value
		if is_universal:
			aspect_type = null
		_update_style()
@export var display_as_inaccessible: bool:
	set(value):
		var icon_material := (%IconTexture as ColorRect).material as ShaderMaterial
		display_as_inaccessible = value
		icon_material.set_shader_parameter('dashed', display_as_inaccessible)
@export var detach_glow_on_anim: bool = false  # HACK
@export var icon_material_template: ShaderMaterial

func _ready() -> void:
	(%IconTexture as ColorRect).material = icon_material_template.duplicate()
	_update_style()
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.BELOW], [Tooltip.Alignment.BEGIN])
	if not Utils.is_in_editor():
		GlobalGameSettings.changed.connect(_update_style)
		mouse_entered.connect(_request_slots)
		mouse_exited.connect(_retract_slot_request)
		tree_exiting.connect(_retract_slot_request)
		GlobalContextHighlight.offer_changed.connect(func(offered: ContextHighlight.Context) -> void:
			if offered:
				if not is_filled and can_be_filled_by(offered.aspect_types):
					state = State.HIGHLIGHTED
				else:
					state = State.FADED_OUT
			else:
				state = State.NORMAL
		)
		GlobalContextHighlight.request_changed.connect(func(requested: ContextHighlight.Context) -> void:
			if requested and load('res://glossary/terms/standalone/term_aspect_slot.tres') in requested.terms:
				state = State.HIGHLIGHTED
			else:
				state = State.NORMAL
		)
		GlobalAudioSystem.set_switch(AK.SWITCHES.ESSENCE.GROUP, _get_audio_switch_id(), self)

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	assert(data is Card)
	if SlotUtils.match_slot([self], (data as Card).card_type.aspects):
		return true  # Prioritize self. This is important if we are trying to apply an ambiguous card.
	return SlotUtils.match_slot(_get_slots_within_recipe(), (data as Card).card_type.aspects) != null

func _drop_data(_pos: Vector2, data: Variant) -> void:
	assert(data is Card)
	if SlotUtils.match_slot([self], (data as Card).card_type.aspects):
		card_dropped.emit(data as Card)  # See note in _can_drop_data().
		return
	SlotUtils.match_slot(_get_slots_within_recipe(), (data as Card).card_type.aspects).card_dropped.emit(data as Card)

func can_be_filled_by(aspect_types: Array[AspectType]) -> bool:
	if is_universal:
		# HACK: Kanji practice allows universal slots to be filled by essence-less cards.
		return aspect_types or Utils.get_active_run() == null
	else:
		return aspect_type in aspect_types

func animate_fill() -> void:
	assert(not is_filled)
	_update_style()

	if detach_glow_on_anim:
		# HACK: Detach the glow and manually sync position so it isn't clipped by our container.
		# TODO: This hack can get messy when a slot is filled and re-cleared.
		(%AnimGlow as TextureRect).top_level = true
		(%AnimGlow as TextureRect).z_index = Utils.get_absolute_z_index(%AnimGlow)
		var sync_pos := func() -> void:
			(%AnimGlow as TextureRect).position = global_position - Vector2(12, 12)
			(%AnimGlow as TextureRect).scale = get_global_transform().get_scale()
		get_tree().process_frame.connect(sync_pos)
		(%AnimationPlayer as AnimationPlayer).animation_finished.connect(func(_anim: StringName) -> void:
			get_tree().process_frame.disconnect(sync_pos)
		)

	(%AnimationPlayer as AnimationPlayer).stop()
	(%AnimationPlayer as AnimationPlayer).play('fill', -1, Utils.anim_speed(1))
	GlobalAudioSystem.play(AK.EVENTS.UI_GAMEPLAY_ESSENCE_FILLED, self)

	await get_tree().create_timer(Utils.anim_duration(0.7)).timeout

	is_filled = true  # Triggers events

func animate_clear() -> void:
	assert(is_filled)
	_update_style()

	(%AnimationPlayer as AnimationPlayer).stop()
	(%AnimationPlayer as AnimationPlayer).play('fill', -1, Utils.anim_speed(-1), true)
	await get_tree().create_timer(Utils.anim_duration(0.5)).timeout

	is_filled = false  # Triggers events

func _get_slots_within_recipe() -> Array[AspectSlot]:
	var self_and_siblings: Array[AspectSlot] = []
	for child in get_parent().get_children():
		if child is AspectSlot:
			self_and_siblings.append(child)
	return self_and_siblings

func _request_slots() -> void:
	if not is_filled:
		var accepted_aspects: Array[AspectType]
		accepted_aspects.assign(AspectType.get_all_types() if is_universal else [aspect_type])
		GlobalContextHighlight.request(ContextHighlight.aspects(self, accepted_aspects))

func _retract_slot_request() -> void:
	GlobalContextHighlight.retract_request(self)

func _update_style() -> void:
	if not is_node_ready():
		return

	var icon_material := (%IconTexture as ColorRect).material as ShaderMaterial
	var color := Color.WHITE
	icon_material.set_shader_parameter('is_accessible', GameSettings.Interface.aspect_icons.value() != GameSettings.AspectIconStyle.CLASSIC)
	icon_material.set_shader_parameter('is_super_accessible', GameSettings.Interface.aspect_icons.value() == GameSettings.AspectIconStyle.SUPER_ACCESSIBLE)
	if is_universal:
		icon_material.set_shader_parameter('accessible_filled_tex', load('res://aspects/types/universal_slot.png'))
		icon_material.set_shader_parameter('frame_shape', 2)
		color = Color(0.547, 0.576, 0.76)
	elif aspect_type:
		if GameSettings.Interface.aspect_icons.value() == GameSettings.AspectIconStyle.SUPER_ACCESSIBLE:
			icon_material.set_shader_parameter('accessible_filled_tex', aspect_type.accessible_icon_slot_filled)
		else:
			icon_material.set_shader_parameter('accessible_filled_tex', aspect_type.accessible_icon)
		icon_material.set_shader_parameter('accessible_empty_tex', aspect_type.accessible_icon_slot_empty)
		icon_material.set_shader_parameter('accessible_highlighted_tex', aspect_type.accessible_icon_slot_highlighted)
		icon_material.set_shader_parameter('frame_shape', 1 if aspect_type.is_advanced else 0)
		icon_material.set_shader_parameter('aspect_tex', aspect_type.icon)
		color = aspect_type.color
	icon_material.set_shader_parameter('frame_color', color)
	(%AnimGlow as TextureRect).modulate.r = color.r * 1.2
	(%AnimGlow as TextureRect).modulate.g = color.g * 1.2
	(%AnimGlow as TextureRect).modulate.b = color.b * 1.2
	icon_material.set_shader_parameter('highlight', float(state == State.HIGHLIGHTED))
	icon_material.set_shader_parameter('fade_progress', float(is_filled))

	match state:
		State.NORMAL:
			modulate.a = 1
			mouse_filter = Control.MOUSE_FILTER_STOP
		State.HIGHLIGHTED:
			modulate.a = 1
			mouse_filter = Control.MOUSE_FILTER_IGNORE if is_filled else Control.MOUSE_FILTER_STOP
		State.FADED_OUT:
			modulate.a = 1.0 if is_filled else 0.3
			mouse_filter = Control.MOUSE_FILTER_IGNORE

func _make_tooltip_text() -> String:
	if Utils.is_in_editor():
		return ''
	var state_str := tr('Filled', 'SLOT') if is_filled else tr('Empty', 'SLOT')
	var aspect_name := tr('Universal', 'SLOT') if is_universal else aspect_type.get_term_name(true)
	var description := tr('This slot can be filled by [b]any[/b] <term_lower:aspect>.') if is_universal else aspect_type.get_markedup_description()
	return (tr('<related_term:aspect_slot><header_font_size>[b]%s Slot: %s[/b][/font_size]\n\n%s') %
			[state_str, aspect_name, description])

func _get_audio_switch_id() -> int:
	if is_universal:
		return AK.SWITCHES.ESSENCE.SWITCH.CHANGE  # TODO: Add a separate SFX for this.
	else:
		return aspect_type.audio_switch.id

@tool
class_name SpotRecipe
extends Recipe

enum State { AVAILABLE, ACTIVE, UNAVAILABLE, LOCKED_OUT }

signal activated
signal clicked  # Used only in the museum.

static var ASPECT_SLOT_SCENE := AsyncLoadedResource.new('res://aspects/slot/aspect_slot.tscn')

@export var spot_upgrade: SpotUpgrade:
	set(value):
		spot_upgrade = value
		if is_node_ready():
			_recreate()
@export var state: State:
	set(value):
		if state == value:
			return
		state = value
		if is_node_ready():
			_update_state_style()
@export var faded_out: bool = false:
	set(value):
		if faded_out == value:
			return
		faded_out = value
		if is_node_ready():
			_update_state_style()
@export var event: Event_Stage:
	set(value):
		event = value
		if is_node_ready():
			_update_state_style()
@export var tooltip_direction: Array[Tooltip.RelativeDirection] = [
	Tooltip.RelativeDirection.RIGHT, Tooltip.RelativeDirection.LEFT, Tooltip.RelativeDirection.BELOW]
var _fadeout_tween: Tween

func _ready() -> void:
	_recreate()
	super._ready()  # After slots are created.
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			tooltip_direction,
			[Tooltip.Alignment.BEGIN, Tooltip.Alignment.CENTERED, Tooltip.Alignment.END])
	if not Utils.is_in_editor():
		GlobalContextHighlight.request_changed.connect(func(requested: ContextHighlight.Context) -> void:
			if requested and requested.bonus_types:
				var any_matched := false
				for bonus_type in spot_upgrade.granted_bonuses:
					if bonus_type in requested.bonus_types:
						any_matched = true
						break
				set_faded_out(not any_matched)
			else:
				set_faded_out(false)
		)

func get_aspect_slots() -> Array[AspectSlot]:
	var aspect_slots: Array[AspectSlot]
	for aspect_slot in %AspectsList.get_children():
		aspect_slots.append(aspect_slot as AspectSlot)
	return aspect_slots

func set_faded_out(is_faded_out: bool) -> void:
	faded_out = is_faded_out
	if faded_out:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		mouse_filter = Control.MOUSE_FILTER_STOP

func is_available() -> bool:
	return state == State.AVAILABLE and not (Utils.get_typed_ancestor(self, Spot) as Spot).is_locked

func get_bonus_counters() -> Array[BonusCounter]:
	return [%Bonus1, %Bonus2, %Bonus3, %Bonus4]

func _update_state_style() -> void:
	var bonuses_panel := %BonusesPanel as Control
	var aspects_panel := %AspectsPanel as Control
	modulate = Color.WHITE
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
	match state:
		State.ACTIVE:
			bonuses_panel.self_modulate = Color(1.2, 1.2, 1.2, 1)
			aspects_panel.self_modulate = Color(1.2, 1.2, 1.2, 1)
		State.AVAILABLE:
			bonuses_panel.self_modulate = Color(0.9, 0.9, 0.9, 1)
			aspects_panel.self_modulate = Color(0.9, 0.9, 0.9, 1)
		State.UNAVAILABLE:
			bonuses_panel.self_modulate = Color(0.7, 0.7, 0.7, 1)
			aspects_panel.self_modulate = Color(0.7, 0.7, 0.7, 1)
		State.LOCKED_OUT:
			bonuses_panel.self_modulate = Color(0.7, 0.7, 0.7, 1)
			aspects_panel.self_modulate = Color(0.7, 0.7, 0.7, 0.5)
			modulate = Color(0.5, 0.5, 0.5, 0.2)
			mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	(%NamePanel as Control).self_modulate = bonuses_panel.self_modulate
	if state != State.LOCKED_OUT:
		if _fadeout_tween:
			_fadeout_tween.kill()
		_fadeout_tween = create_tween()
		_fadeout_tween.tween_property(self, 'modulate:a', 0.35 if faded_out else 1.0, FADEOUT_ANIM_DURATION)
		_fadeout_tween.play()
		if faded_out:
			mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED

	for aspect_slot: AspectSlot in %AspectsList.get_children():
		aspect_slot.display_as_inaccessible = state == State.UNAVAILABLE

	# Event outline
	if is_inside_tree():
		await get_tree().process_frame
		var outline := %OutlineContainer as Control
		if event:
			outline.visible = true
			if Event.Category.MAIN_STORY in event.categories:
				outline.modulate = Color(0.725, 0.338, 1.112)
			elif Event.Category.LANDMARK in event.categories:
				outline.modulate = Color(0.154, 0.923, 1.202, 1.0)
			elif Event.Category.COMPANION in event.categories:
				outline.modulate = Color(0.165, 0.9, 0.0)
			else:
				outline.modulate = Color(1.09, 0.963, 0.0, 1.0)
			_set_outline_shape(%VFX_Top as GPUParticles2D, Rect2(0, 0, outline.size.x, 0.1))
			_set_outline_shape(%VFX_Bottom as GPUParticles2D, Rect2(0, outline.size.y, outline.size.x, 0.1))
			_set_outline_shape(%VFX_Left as GPUParticles2D, Rect2(0, 0, 0.1, outline.size.y))
			_set_outline_shape(%VFX_Right as GPUParticles2D, Rect2(outline.size.x, 0, 0.1, outline.size.y))
			for vfx: GPUParticles2D in outline.get_children():
				vfx.emitting = true
		else:
			outline.visible = false

func _set_outline_shape(vfx: GPUParticles2D, shape: Rect2) -> void:
	vfx.process_material = vfx.process_material.duplicate()
	var mat := vfx.process_material as ParticleProcessMaterial
	mat.emission_shape_offset.x = shape.get_center().x
	mat.emission_shape_offset.y = shape.get_center().y
	mat.emission_box_extents.x = shape.size.x / 2.0
	mat.emission_box_extents.y = shape.size.y / 2.0

func _recreate() -> void:
	if not spot_upgrade:
		return
	(%NameLabel as Label).text = tr(spot_upgrade.name)
	(%UniqueIcon as Control).visible = spot_upgrade.unique_per_run

	Utils.clear_node(%AspectsList)
	var sorted_aspects := spot_upgrade.required_aspects.duplicate()
	sorted_aspects.sort_custom(AspectType.compare)
	for aspect_type: AspectType in sorted_aspects:
		var aspect_slot := ASPECT_SLOT_SCENE.instantiate_loaded_scene() as AspectSlot
		aspect_slot.aspect_type = aspect_type
		aspect_slot.detach_glow_on_anim = true
		aspect_slot.filled.connect(_on_aspect_filled)
		%AspectsList.add_child(aspect_slot)

	var bonus_types := spot_upgrade.granted_bonuses.keys() as Array[BonusType]
	bonus_types.sort_custom(func(a: BonusType, b: BonusType) -> bool:
			return abs(spot_upgrade.granted_bonuses[a]) > abs(spot_upgrade.granted_bonuses[b]))
	for i in range(4):
		var bonus_node := [%Bonus1, %Bonus2, %Bonus3, %Bonus4][i] as BonusCounter
		if i < bonus_types.size():
			bonus_node.visible = true
			var bonus_type := bonus_types[i]
			bonus_node.bonus_type = bonus_type
			bonus_node.current_value = spot_upgrade.granted_bonuses[bonus_type]
		else:
			bonus_node.visible = false

	_update_state_style()

func _make_tooltip_text() -> String:
	if Utils.is_in_editor():
		return ''

	var pieces: Array[String]
	pieces.append('<related_term:spot_upgrade>')
	pieces.append('<related_term:spot>')
	pieces.append('<header_font_size>[b]%s[/b][/font_size]' % tr(spot_upgrade.name))
	if spot_upgrade.unique_per_run:
		pieces.append(tr(' (Unique)'))

	pieces.append('\n\n')
	pieces.append(tr('Requires: '))
	var sorted_aspects: Array[AspectType] = spot_upgrade.required_aspects.duplicate()
	sorted_aspects.sort_custom(AspectType.compare)
	for i in range(sorted_aspects.size()):
		if i > 0:
			pieces.append(', ')
		pieces.append(sorted_aspects[i].get_term_tag())

	pieces.append('\n')
	pieces.append(tr('Provides: '))
	var bonuses: Array[BonusType] = spot_upgrade.granted_bonuses.keys()
	var first := true
	var negative_bonuses: Array[BonusType]
	for bonus_type in bonuses:
		if spot_upgrade.granted_bonuses.get(bonus_type) > 0:
			if not first:
				pieces.append(', ')
			pieces.append(bonus_type.get_term_tag())
			first = false
		else:
			negative_bonuses.append(bonus_type)
	if negative_bonuses:
		pieces.append('\n')
		pieces.append(tr('Consumes: '))
		var first_negative := true
		for bonus_type in negative_bonuses:
			if spot_upgrade.granted_bonuses.get(bonus_type) < 0:
				if not first_negative:
					pieces.append(', ')
				pieces.append(bonus_type.get_term_tag())
				first_negative = false

	var run := Utils.get_active_run()
	if run and run.get_var(RunVars.Var.CARES_ABOUT_UPGRADE_TAGS):
		if spot_upgrade.tags:
			pieces.append('\n')
			for tag in spot_upgrade.tags:
				pieces.append('\n')
				match tag:
					SpotUpgrade.Tag.NATURAL:
						pieces.append(tr('This is a [b]natural[/b] <term_lower:spot_upgrade>.'))
					SpotUpgrade.Tag.AGRICULTURAL:
						pieces.append(tr('This is an [b]agricultural[/b] <term_lower:spot_upgrade>.'))
					SpotUpgrade.Tag.INDUSTRIAL:
						pieces.append(tr('This is an [b]industrial[/b] <term_lower:spot_upgrade>.'))
					SpotUpgrade.Tag.SPIRITUAL:
						pieces.append(tr('This is a [b]spiritual[/b] <term_lower:spot_upgrade>.'))

	if spot_upgrade.unique_per_run and not Skill.get_skill_var(Skill.Var.IGNORE_UNIQUES):
		pieces.append('\n\n')
		pieces.append(tr('[b]This <term_lower:spot_upgrade> can only be activated once per expedition.[/b]'))

	pieces.append('\n\n')
	pieces.append(tr('[i]“%s”[/i]') % tr(spot_upgrade.description))

	if event:
		var landmark := event.get_associated_landmark()
		if landmark:
			pieces.append('\n\n')
			pieces.append(tr('[center]──── [b]Landmark: %s[/b] ────[/center]') % landmark.get_term_tag())
			pieces.append('\n')
			pieces.append(tr('Activating this <term_lower:spot_upgrade> may allow you to establish this <term:shop>.'))
		else:
			pieces.append('\n\n')
			pieces.append(tr('[center]──── [b]Event: %s[/b] ────[/center]') % tr(event.event_name))
			pieces.append('\n')
			pieces.append(tr('Activating this <term_lower:spot_upgrade> will start this <term:event>.'))
		if Event.Category.MAIN_STORY in event.categories:
			pieces.append('\n\n')
			pieces.append(tr('[b]This event is part of the main story.[/b]'))
		var reqs_hint := event.get_markedup_requirements_hint()
		if reqs_hint:
			pieces.append('\n')
			pieces.append(tr('[b]May require[/b]: %s') % reqs_hint)
		var outcomes_hint := event.get_markedup_outcomes_hint()
		if outcomes_hint:
			pieces.append('\n')
			pieces.append(tr('[b]May grant[/b]: %s') % outcomes_hint)

		if GlobalSaveGame.has_seen_event(event):
			if Utils.is_museum_unlocked():
				pieces.append('\n\n')
				pieces.append(tr('[i]%s to open museum entry.[/i]') % InputPrompts.get_input_markup(
				InputPrompts.InputType.RIGHT_CLICK))
		else:
			pieces.append('\n\n')
			pieces.append(tr('[b]This event has not been discovered yet.[/b]'))

	return ''.join(pieces)

func _on_aspect_filled() -> void:
	var all_filled := true
	for slot in %AspectsList.get_children():
		if not (slot as AspectSlot).is_filled:
			all_filled = false
			break
	if all_filled:
		state = State.ACTIVE
		GlobalSaveGame.mark_upgrade_seen(spot_upgrade)
		activated.emit()
		Utils.get_active_run().signals.spot_recipe_activated.emit(self)

func _gui_input(input_event: InputEvent) -> void:
	var mouse_event := input_event as InputEventMouseButton
	if not mouse_event:
		return
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		if Utils.is_museum_unlocked():
			if event:
				if GlobalSaveGame.has_seen_event(event):
					MuseumBrowser.open_museum_entry(event, GlobalUI.choose_dynamic_menu_layer())
				else:
					GlobalUI.show_error(tr('The <term_lower:event> hasn\'t been discovered yet.'))
			else:
				if not GlobalSaveGame.has_seen_upgrade(spot_upgrade):
					GlobalSaveGame.mark_upgrade_seen(spot_upgrade)  # We're looking at it now.
				MuseumBrowser.open_museum_entry(spot_upgrade, GlobalUI.choose_dynamic_menu_layer())

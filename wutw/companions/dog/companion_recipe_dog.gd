class_name CompanionRecipe_Dog
extends CompanionRecipe

func _ready() -> void:
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.END], %TooltipAnchor as Control)

	if _is_active():
		for aspect_slot: AspectSlot in %AspectsList.get_children():
			aspect_slot.is_filled = true
	elif not _is_available():
		Utils.clear_node(%AspectsList)
	else:
		for aspect_slot: AspectSlot in %AspectsList.get_children():
			aspect_slot.filled.connect(_on_slot_filled)

	super._ready()

	(%AnimationPlayer as AnimationPlayer).queue('idle')

func get_aspect_slots() -> Array[AspectSlot]:
	var result: Array[AspectSlot]
	result.assign(%AspectsList.get_children())
	return result

func _make_tooltip_text() -> String:
	var companion_resource := _get_companion()
	var text := (tr('<header_font_size>[b]%s <term:companion> Ability[/b][/font_size]\n%s') %
				 [tr(companion_resource.companion_name), tr(companion_resource.ability_description)])
	if _is_active():
		text += '\n\n' + tr('[b]Already active.[/b]')
	elif not _is_available():
		text += '\n\n' + tr('[b]Already used this <term_lower:season>.[/b]')
	return text

func _is_available() -> bool:
	var run := Utils.get_active_run()
	return run.get_current_season_index() != _get_last_used_season_index()

func _is_active() -> bool:
	var run := Utils.get_active_run()
	return run.signals.inspiration_exhausted.is_connected(_on_inspiration_exhausted.bind(run))

func _on_slot_filled() -> void:
	for slot in get_aspect_slots():
		if not slot.is_filled:
			return

	_on_all_slots_filled()

func _on_all_slots_filled() -> void:
	assert(_is_available() and not _is_active())
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	stage.queue_action(func() -> void:
		run.signals.companion_ability_started.emit(_get_companion())
		if (%AnimationPlayer as AnimationPlayer).current_animation != 'react':
			(%AnimationPlayer as AnimationPlayer).play('react', -1, Utils.anim_speed())
			(%AnimationPlayer as AnimationPlayer).queue('idle')
			GlobalAudioSystem.play(AK.EVENTS.SFX_ANIMAL_COMPANION_DOG)
		run.signals.inspiration_exhausted.connect(_on_inspiration_exhausted.bind(run))
		_set_last_used_season_index(run.get_current_season_index())
		run.signals.companion_ability_finished.emit(_get_companion())
	)

func _set_last_used_season_index(index: int) -> void:
	Utils.get_active_run().get_events_state().set_int('_companion_state', 'dog', index)

func _get_last_used_season_index() -> int:
	return Utils.get_active_run().get_events_state().get_int_or_default('_companion_state', 'dog', -1)

static func _on_inspiration_exhausted(_reason: Run.InspirationChangeReason, run: Run) -> void:
	var current_inspiration := run.get_var(RunVars.Var.CURRENT_INSPIRATION)
	if current_inspiration > 0:
		# This can happen if another effect has saved the player from exahusting inspiration.
		return
	run.get_vars().modify_base_value(RunVars.Var.CURRENT_INSPIRATION, 1)
	run.signals.inspiration_exhausted.disconnect(_on_inspiration_exhausted.bind(run))

func _get_companion() -> Companion:
	return load('res://companions/dog/companion_dog.tres') as Companion

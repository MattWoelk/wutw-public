class_name CompanionRecipe_Crane
extends CompanionRecipe

static var ASPECT_SLOT_SCENE := AsyncLoadedResource.new('res://aspects/slot/aspect_slot.tscn')

const MAX_SLOTS := 5

func _ready() -> void:
	super._ready()
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.END], %TooltipAnchor as Control)
	(%AspectSlot as AspectSlot).filled.connect(_on_slot_filled)
	(%AspectSlot2 as AspectSlot).filled.connect(_on_slot_filled)

	(%AnimationPlayer as AnimationPlayer).queue('idle')

	var run := Utils.get_active_run()
	if _get_stacks() >= 2 and run.get_current_stage().mode == Stage.Mode.REGULAR:
		for bonus_type in BonusType.get_all_types():
			run.gain_bonus(BonusGain.new(bonus_type, floori(_get_stacks() / 2.0), self))

func _add_slot() -> void:
	var aspect_slot := ASPECT_SLOT_SCENE.instantiate_loaded_scene() as AspectSlot
	aspect_slot.is_universal = true
	aspect_slot.filled.connect(_on_slot_filled)
	%AspectsList.add_child(aspect_slot)

func get_aspect_slots() -> Array[AspectSlot]:
	var result: Array[AspectSlot]
	result.assign(%AspectsList.get_children())
	return result

func _make_tooltip_text() -> String:
	var companion_resource := _get_companion()
	var text := (tr('<header_font_size>[b]%s <term:companion> Ability[/b][/font_size]\n%s') %
				 [tr(companion_resource.companion_name), tr(companion_resource.ability_description)])
	text += '\n\n' + tr('[b]Accumulated Devotion: %d[/b]') % _get_stacks()
	return text

func _get_stacks() -> int:
	var run := Utils.get_active_run()
	return run.get_events_state().get_int_or_default('_companion_state', 'crane', 0)

func _on_slot_filled() -> void:
	for slot in get_aspect_slots():
		if not slot.is_filled:
			return

	_on_all_slots_filled()

func _on_all_slots_filled() -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	stage.queue_action(func() -> void:
		run.signals.companion_ability_started.emit(_get_companion())
		if (%AnimationPlayer as AnimationPlayer).current_animation != 'react':
			(%AnimationPlayer as AnimationPlayer).play('react', -1, Utils.anim_speed())
			(%AnimationPlayer as AnimationPlayer).queue('idle')
			GlobalAudioSystem.play(AK.EVENTS.SFX_ANIMAL_COMPANION_CRANE)
		run.get_events_state().set_int('_companion_state', 'crane', _get_stacks() + 1)

		var slots := get_aspect_slots()
		if slots.size() < MAX_SLOTS:
			# Make reusable.
			for aspect_slot: AspectSlot in slots:
				aspect_slot.animate_clear()
			# Increase cost.
			_add_slot()

		run.signals.companion_ability_finished.emit(_get_companion())
	)

func _get_companion() -> Companion:
	return load('res://companions/crane/companion_crane.tres') as Companion

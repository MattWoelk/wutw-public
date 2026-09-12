class_name CompanionRecipe_Turtle
extends CompanionRecipe

const RESILIENCE_PER_HARMONIZATION := 10

func _ready() -> void:
	super._ready()
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.END], %TooltipAnchor as Control)
	(%AspectSlot as AspectSlot).filled.connect(_on_slot_filled)

	(%AnimationPlayer as AnimationPlayer).queue('idle')

	# WARNING: This binding hack allows us to run this function even after the node is destroyed.
	#          The key is to never reference `self`, directly or indirectly.
	var run := Utils.get_active_run()
	if run.get_current_stage().mode == Stage.Mode.HARMONIZATION:
		var add_resilience := func(this: Callable) -> void:
			var resilience := _get_resilience() + RESILIENCE_PER_HARMONIZATION
			GlobalSaveGame.get_events_state().set_int('_companion_state', 'turtle', resilience)
			run.signals.harmonization_finished.disconnect(this.bind(this))
		run.signals.harmonization_finished.connect(add_resilience.bind(add_resilience))

func get_aspect_slots() -> Array[AspectSlot]:
	return [%AspectSlot as AspectSlot]

func _make_tooltip_text() -> String:
	var companion_resource := _get_companion()
	return (tr('<header_font_size>[b]%s <term:companion> Ability[/b][/font_size]\n%s\n\n[b]Current Resilience: %d') %
			[tr(companion_resource.companion_name), tr(companion_resource.ability_description), _get_resilience()])

func _get_resilience() -> int:
	return GlobalSaveGame.get_events_state().get_int_or_default('_companion_state', 'turtle', 0)

func _on_slot_filled() -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	stage.queue_action(func() -> void:
		run.signals.companion_ability_started.emit(_get_companion())
		if (%AnimationPlayer as AnimationPlayer).current_animation != 'react':
			(%AnimationPlayer as AnimationPlayer).play('react', -1, Utils.anim_speed())
			(%AnimationPlayer as AnimationPlayer).queue('idle')
			GlobalAudioSystem.play(AK.EVENTS.SFX_ANIMAL_COMPANION_TURTLE)
		var max_inspiration := run.get_var(RunVars.Var.MAX_INSPIRATION)
		var current_inspiration := run.get_var(RunVars.Var.CURRENT_INSPIRATION)
		var recovered := mini(_get_resilience(), max_inspiration - current_inspiration)
		run.modify_inspiration(recovered, Run.InspirationChangeReason.COMPANION)
		GlobalSaveGame.get_events_state().set_int('_companion_state', 'turtle', _get_resilience() - recovered)

		# Make reusable.
		await (%AspectSlot as AspectSlot).animate_clear()
		run.signals.companion_ability_finished.emit(_get_companion())
	)

func _get_companion() -> Companion:
	return load('res://companions/turtle/companion_turtle.tres') as Companion

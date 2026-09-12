class_name CompanionRecipe_Spider
extends CompanionRecipe

const INSPIRATION_RATIO_LOST := 0.3

func _ready() -> void:
	super._ready()
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.END], %TooltipAnchor as Control)
	(%AspectSlot as AspectSlot).filled.connect(_on_slot_filled)
	(%AnimationPlayer as AnimationPlayer).play('idle')

func get_aspect_slots() -> Array[AspectSlot]:
	return [%AspectSlot as AspectSlot]

func _make_tooltip_text() -> String:
	var companion_resource := _get_companion()
	return (tr('<header_font_size>[b]%s <term:companion> Ability[/b][/font_size]\n%s') %
			[tr(companion_resource.companion_name), tr(companion_resource.ability_description)])

func _on_slot_filled() -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	stage.queue_action(func() -> void:
		run.signals.companion_ability_started.emit(_get_companion())
		(%AnimationPlayer as AnimationPlayer).play('react', -1, Utils.anim_speed())
		(%AnimationPlayer as AnimationPlayer).queue('idle')
		GlobalAudioSystem.play(AK.EVENTS.SFX_ANIMAL_COMPANION_SPIDER)
		# Line up the effect with the jump anim.
		await get_tree().create_timer(Utils.anim_duration(1.2)).timeout
		var current_inspiration := run.get_var(RunVars.Var.CURRENT_INSPIRATION)
		var inspiration_loss := floori(current_inspiration * INSPIRATION_RATIO_LOST)
		run.modify_inspiration(-inspiration_loss, Run.InspirationChangeReason.COMPANION)
		run.get_current_stage().add_redraws(1)
		# Not reusable! Otherwise easy to abuse.
		run.signals.companion_ability_finished.emit(_get_companion())
	)

func _get_companion() -> Companion:
	return load('res://companions/spider/companion_spider.tres') as Companion

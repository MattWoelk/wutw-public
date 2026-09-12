class_name CompanionRecipe_Tiger
extends CompanionRecipe

static var ASPECT_SLOT_SCENE := AsyncLoadedResource.new('res://aspects/slot/aspect_slot.tscn')

func _ready() -> void:
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.END], %TooltipAnchor as Control)

	(%AspectSlot as AspectSlot).filled.connect(_on_slot_filled)
	(%AspectSlot2 as AspectSlot).filled.connect(_on_slot_filled)

	(%AnimationPlayer as AnimationPlayer).queue('idle')

	super._ready()

func get_aspect_slots() -> Array[AspectSlot]:
	return [%AspectSlot as AspectSlot, %AspectSlot2 as AspectSlot]

func _make_tooltip_text() -> String:
	var companion_resource := _get_companion()
	return (tr('<header_font_size>[b]%s <term:companion> Ability[/b][/font_size]\n%s') %
			[tr(companion_resource.companion_name), tr(companion_resource.ability_description)])

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
			GlobalAudioSystem.play(AK.EVENTS.SFX_ANIMAL_COMPANION_TIGER)

		await stage.get_card_deck().draw(CardDeck.CardDrawReason.COMPANION, true)

		# Make reusable.
		for slot in get_aspect_slots():
			slot.animate_clear()
		run.signals.companion_ability_finished.emit(_get_companion())
	)

func _get_companion() -> Companion:
	return load('res://companions/tiger/companion_tiger.tres') as Companion

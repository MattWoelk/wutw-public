class_name CompanionRecipe_Cat
extends CompanionRecipe

const RARITY_PERCENT_PER_SLOT := 7

func _ready() -> void:
	super._ready()
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.END], %TooltipAnchor as Control)

	(%AnimationPlayer as AnimationPlayer).play('idle')

	if Utils.get_active_run().get_current_stage().mode == Stage.Mode.HARMONIZATION:
		visible = false
		return

	for aspect_slot: AspectSlot in %AspectsList.get_children():
		aspect_slot.filled.connect(_on_slot_filled)

	# WARNING: This binding hack allows us to run this function even after the node is destroyed.
	#          The key is to never reference `self`, directly or indirectly.
	var run := Utils.get_active_run()
	var clear_modifier := func(id: String, this: Callable) -> void:
		run.get_vars().remove_modifier(id)
		run.signals.card_choice_finished.disconnect(this.bind(id, this))
	var companion_resource := load('res://companions/cat/companion_cat.tres') as Companion
	run.signals.card_choice_finished.connect(
		clear_modifier.bind(companion_resource.get_term_id(), clear_modifier))

func get_aspect_slots() -> Array[AspectSlot]:
	var result: Array[AspectSlot]
	result.assign(%AspectsList.get_children())
	return result

func _make_tooltip_text() -> String:
	var companion_resource := _get_companion()
	return (tr('<header_font_size>[b]%s <term:companion> Ability[/b][/font_size]\n%s') %
			[tr(companion_resource.companion_name), tr(companion_resource.ability_description)])

func _on_slot_filled() -> void:
	var companion_resource := load('res://companions/cat/companion_cat.tres') as Companion
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	stage.queue_action(func() -> void:
		run.signals.companion_ability_started.emit(_get_companion())
		var total_rarity := 0
		for aspect_slot: AspectSlot in %AspectsList.get_children():
			if aspect_slot.is_filled:
				total_rarity += RARITY_PERCENT_PER_SLOT
		run.get_vars().add_modifier(RunVars.Var.CARD_TIER_BONUS_PERCENT, total_rarity, companion_resource.get_term_id())
		if (%AnimationPlayer as AnimationPlayer).current_animation != 'react':
			GlobalAudioSystem.play(AK.EVENTS.SFX_ANIMAL_COMPANION_CAT)
			(%AnimationPlayer as AnimationPlayer).play('react', -1, Utils.anim_speed())
			(%AnimationPlayer as AnimationPlayer).queue('idle')
			await get_tree().create_timer(Utils.anim_duration(0.5)).timeout
		run.signals.companion_ability_finished.emit(_get_companion())
	)

func _get_companion() -> Companion:
	return load('res://companions/cat/companion_cat.tres') as Companion

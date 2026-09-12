class_name CompanionRecipe_Deer
extends CompanionRecipe

static var ASPECT_SLOT_SCENE := AsyncLoadedResource.new('res://aspects/slot/aspect_slot.tscn')

func _ready() -> void:
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.END], %TooltipAnchor as Control)

	(%AnimationPlayer as AnimationPlayer).play('idle')

	(%AspectSlot as AspectSlot).filled.connect(_on_slot_filled)

	if Utils.get_active_run().get_current_stage().mode != Stage.Mode.REGULAR:
		visible = false
		return

	super._ready()

func get_aspect_slots() -> Array[AspectSlot]:
	return [%AspectSlot as AspectSlot]

func _make_tooltip_text() -> String:
	var companion_resource := _get_companion()
	var result := (tr('<header_font_size>[b]%s <term:companion> Ability[/b][/font_size]\n%s') %
			[tr(companion_resource.companion_name), tr(companion_resource.ability_description)])
	var recipe := _choose_recipe()
	if recipe:
		result += '\n\n' + tr('[b]Will target %s.[/b]') % tr(recipe.spot_upgrade.name)
	else:
		result += '\n\n' + tr('[b]None of the available <term_lower:spot_upgrade>s provide unfulfilled <term_lower:stage_goal>s.[/b]')
	return result

func _on_slot_filled() -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	stage.queue_action(func() -> void:
		run.signals.companion_ability_started.emit(_get_companion())
		if (%AnimationPlayer as AnimationPlayer).current_animation != 'react':
			(%AnimationPlayer as AnimationPlayer).play('react', -1, Utils.anim_speed())
			(%AnimationPlayer as AnimationPlayer).queue('idle')
			GlobalAudioSystem.play(AK.EVENTS.SFX_ANIMAL_COMPANION_DOE)

		var pool := _get_slot_pool()
		if pool:
			var slot := stage.get_card_deck().get_random_state().pick(pool) as AspectSlot
			await stage.ensure_slot_visible(slot)
			await slot.animate_fill()
		else:
			GlobalUI.show_error(tr('No valid <term_lower:aspect_slot>s to fill.'))

		# Make reusable.
		for slot in get_aspect_slots():
			slot.animate_clear()
		run.signals.companion_ability_finished.emit(_get_companion())
	)

func _get_slot_pool() -> Array[AspectSlot]:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	var aspect_slots_availability := stage.get_aspect_slots_availability()
	var pool: Array[AspectSlot] = []
	var recipe := _choose_recipe()
	if recipe:
		for slot in recipe.get_aspect_slots():
			if aspect_slots_availability.get(slot):
				pool.append(slot)
	return pool

func _choose_recipe() -> SpotRecipe:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	var remaining_goals := stage.get_remaining_requirements()
	var max_goal := 0
	var best_recipe: SpotRecipe
	for recipe in stage.get_all_recipes():
		if recipe is SpotRecipe:
			var spot_recipe := recipe as SpotRecipe
			if spot_recipe.is_available():
				var goal_yields := 0
				for bonus_type in remaining_goals:
					goal_yields += spot_recipe.spot_upgrade.granted_bonuses.get(bonus_type, 0)
				if goal_yields > max_goal:
					max_goal = goal_yields
					best_recipe = spot_recipe
	return best_recipe

func _get_companion() -> Companion:
	return load('res://companions/deer/companion_deer.tres') as Companion

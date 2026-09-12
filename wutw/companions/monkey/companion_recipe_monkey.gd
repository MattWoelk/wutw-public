class_name CompanionRecipe_Monkey
extends CompanionRecipe

static var ASPECT_SLOT_SCENE := AsyncLoadedResource.new('res://aspects/slot/aspect_slot.tscn')

const MAX_SLOTS := 6

func _ready() -> void:
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.END], %TooltipAnchor as Control)

	Utils.clear_node(%AspectsList)
	_add_slot()
	super._ready()

	(%AnimationPlayer as AnimationPlayer).queue('idle')

func get_aspect_slots() -> Array[AspectSlot]:
	var result: Array[AspectSlot]
	result.assign(%AspectsList.get_children())
	return result

func _make_tooltip_text() -> String:
	var companion_resource := _get_companion()
	return (tr('<header_font_size>[b]%s <term:companion> Ability[/b][/font_size]\n%s') %
			[tr(companion_resource.companion_name), tr(companion_resource.ability_description)])

func _add_slot() -> void:
	var aspect_slot := ASPECT_SLOT_SCENE.instantiate_loaded_scene() as AspectSlot
	aspect_slot.is_universal = true
	aspect_slot.filled.connect(_on_slot_filled)
	%AspectsList.add_child(aspect_slot)

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
			await get_tree().create_timer(Utils.anim_duration(0.2)).timeout
			GlobalAudioSystem.play(AK.EVENTS.SFX_ANIMAL_COMPANION_MONKEY)

		var deck := stage.get_card_deck()
		var total_tier := 0
		var total_count := 0
		for card_type in run.get_deck_cards():
			if card_type.rarity < CardType.Rarity.NEGATIVE:
				total_tier += card_type.rarity
				total_count += 1
		var avg_tier := float(total_tier) / maxi(total_count, 1)
		var actual_tier := floori(avg_tier)
		if deck.get_random_state().rand_float() <= fmod(avg_tier, 1):
			actual_tier += 1

		var card_type := deck.get_random_state().pick(CardType.get_all_card_types_by_tier(actual_tier)) as CardType
		await deck.add_card_to_hand(card_type, CardDeck.CardDrawReason.COMPANION)

		var slots := get_aspect_slots()
		if slots.size() < MAX_SLOTS:
			# Make reusable.
			for slot in slots:
				slot.animate_clear()
			# Increase cost.
			_add_slot()

		run.signals.companion_ability_finished.emit(_get_companion())
	)

func _get_companion() -> Companion:
	return load('res://companions/monkey/companion_monkey.tres') as Companion

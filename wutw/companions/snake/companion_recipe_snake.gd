class_name CompanionRecipe_Snake
extends CompanionRecipe

var _stored_card: CardType

func _ready() -> void:
	super._ready()
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.END], %TooltipAnchor as Control)
	(%AspectSlot as AspectSlot).filled.connect(_on_slot_filled)

	(%AnimationPlayer as AnimationPlayer).queue('idle')

func get_aspect_slots() -> Array[AspectSlot]:
	return [%AspectSlot as AspectSlot]

func _make_tooltip_text() -> String:
	var companion_resource := _get_companion()
	var text := (tr('<header_font_size>[b]%s <term:companion> Ability[/b][/font_size]\n%s') %
				 [tr(companion_resource.companion_name), tr(companion_resource.ability_description)])
	if _stored_card:
		text += tr('\n\n[b]Stored Glyph: %s[/b]') % _stored_card.get_term_tag()
	return text

func _on_slot_filled() -> void:
	assert(not _stored_card)
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	stage.queue_action(func() -> void:
		run.signals.companion_ability_started.emit(_get_companion())
		if (%AnimationPlayer as AnimationPlayer).current_animation != 'react':
			(%AnimationPlayer as AnimationPlayer).play('react', -1, Utils.anim_speed())
			(%AnimationPlayer as AnimationPlayer).queue('idle')
			GlobalAudioSystem.play(AK.EVENTS.SFX_ANIMAL_COMPANION_SNAKE)
		_stored_card = stage.get_processing_card().card_type
		await stage.get_card_deck().discard(stage.get_processing_card(), CardDeck.DiscardReason.COMPANION, true)
		run.signals.redraw_finished.connect(_on_redraw, ConnectFlags.CONNECT_ONE_SHOT)
		run.signals.companion_ability_finished.emit(_get_companion())
	)

func _on_redraw(_is_first: bool) -> void:
	assert(_stored_card)
	var run := Utils.get_active_run()
	run.run_or_queue_action(func() -> void:
		if (%AnimationPlayer as AnimationPlayer).current_animation != 'react':
			(%AnimationPlayer as AnimationPlayer).play('react', -1, Utils.anim_speed())
			(%AnimationPlayer as AnimationPlayer).queue('idle')
			GlobalAudioSystem.play(AK.EVENTS.SFX_ANIMAL_COMPANION_SNAKE)
		(%AspectSlot as AspectSlot).animate_clear()
		var deck := run.get_current_stage().get_card_deck()
		await deck.add_card_to_hand(_stored_card, CardDeck.CardDrawReason.COMPANION)
		_stored_card = null
	)

func _get_companion() -> Companion:
	return load('res://companions/snake/companion_snake.tres') as Companion

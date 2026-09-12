class_name CompanionRecipe_Dragon
extends CompanionRecipe

static var ASPECT_SLOT_SCENE := AsyncLoadedResource.new('res://aspects/slot/aspect_slot.tscn')

@export var wildcard: CardType

const MAX_SLOTS := 3

func _ready() -> void:
	super._ready()
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.END], %TooltipAnchor as Control)

	for aspect_slot: AspectSlot in %AspectsList.get_children():
		aspect_slot.filled.connect(_on_slot_filled)

func get_aspect_slots() -> Array[AspectSlot]:
	var result: Array[AspectSlot]
	result.assign(%AspectsList.get_children())
	return result

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
			get_tree().create_timer(0.25).timeout.connect(
				GlobalAudioSystem.play.bind(AK.EVENTS.SFX_ANIMAL_COMPANION_DRAGON))

		var deck := stage.get_card_deck()
		await deck.add_card_to_hand(wildcard, CardDeck.CardDrawReason.COMPANION)

		var slots := get_aspect_slots()
		if slots.size() < MAX_SLOTS:
			# Make reusable.
			for aspect_slot: AspectSlot in slots:
				aspect_slot.animate_clear()
			# Increase cost.
			_add_slot()

		run.signals.companion_ability_finished.emit(_get_companion())
	)

func _add_slot() -> void:
	var aspect_slot := ASPECT_SLOT_SCENE.instantiate_loaded_scene() as AspectSlot
	aspect_slot.aspect_type = AspectType.get_aspect_type_by_id('illumination')
	aspect_slot.filled.connect(_on_slot_filled)
	%AspectsList.add_child(aspect_slot)

func _get_companion() -> Companion:
	return load('res://companions/dragon/companion_dragon.tres') as Companion

@tool
class_name Relic_TravelersPouch
extends Relic

@export var base_hand_size_reduction: int = 2
@export var cards_added: int = 2

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	if apply_modifiers:
		_run.get_vars().add_modifier(RunVars.Var.HAND_SIZE, -base_hand_size_reduction, _get_modifier_tag())
	_run.signals.redraw_finished.connect(_on_redrew)

func on_removed() -> void:
	_run.get_vars().remove_modifier(_get_modifier_tag())
	_run.signals.redraw_finished.disconnect(_on_redrew)
	super.on_removed()

func _on_redrew(_is_first: bool) -> void:
	_run.run_or_queue_action(func() -> void:
		triggered.emit()

		var deck := _run.get_current_stage().get_card_deck()

		var total_tier := 0
		var total_count := 0
		for card_type in _run.get_deck_cards():
			if card_type.rarity < CardType.Rarity.NEGATIVE:
				total_tier += card_type.rarity
				total_count += 1
		var avg_tier := float(total_tier) / maxi(total_count, 1)

		for i in cards_added:
			var actual_tier := floori(avg_tier)
			if deck.get_random_state().rand_float() <= fmod(avg_tier, 1):
				actual_tier += 1
			var options: Array[CardType]
			for option in CardType.get_all_card_types_by_tier(actual_tier):
				if CardType.Tag.NOT_RANDOMLY_SELECTED in option.tags:
					continue
				# HACK: Hide Pacify cards until hauntings are unlocked.
				if not Utils.are_hauntings_unlocked():
					var has_pacify := false
					for ability in option.abilities:
						if ability is CardAbility_Pacify:
							has_pacify = true
					if has_pacify:
						continue
				options.append(option)
			var card_type_to_add := deck.get_random_state().pick(options) as CardType
			await deck.add_card_to_hand(card_type_to_add, CardDeck.CardDrawReason.HARMONIZATION_RECIPE)
	)

func get_description() -> String:
	return tr(default_description) % [base_hand_size_reduction, cards_added]

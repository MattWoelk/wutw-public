@tool
class_name CardAbility_Echo
extends CardAbility

func get_ability_name(_markedup: bool = false, _short: bool = false) -> String:
	return tr('Echo', 'ABILITY')

func get_ability_tooltip(card: Card) -> String:
	var result := tr('Repeat the effects of the most recently <term_lower:cast_card> <term_lower:glyph>')
	var deck := _get_ancestor_deck(card)
	if deck:
		var most_recent_card := _get_ancestor_deck(card).get_most_recently_cast_card()
		if most_recent_card:
			var repeated_abilities: Array[String]
			for ability in most_recent_card.abilities:
				repeated_abilities.append('<related_term:%s>%s' % [
					ability.get_term().get_term_id(), ability.get_ability_name()])
			result += ' ([b]%s: %s[/b])' % [most_recent_card.symbol, ', '.join(repeated_abilities)]
		else:
			result += tr(' ([b]currently none[/b])', 'REPEATED_ABILITIES')
	result += tr('.')
	return result

func get_term() -> Term:
	return load('res://cards/abilities/terms/term_card_ability_echo.tres')

func cast(card: Card) -> void:
	var stage := Utils.get_active_run().get_current_stage()
	var deck := stage.get_card_deck()
	if deck.get_most_recently_cast_card():
		for ability in deck.get_most_recently_cast_card().abilities:
			stage.queue_action(func() -> void:
				await stage.cast_ability(card, ability)
			)
	else:
		GlobalUI.show_error(tr('No other cards have been <term_lower:cast_card> yet.'))

func should_destroy_on_cast() -> bool:
	var run := Utils.get_active_run()
	if not run:
		return false
	var stage := run.get_current_stage()
	if not stage:
		return false
	var deck := stage.get_card_deck()
	if not deck.get_most_recently_cast_card():
		return false
	for ability in deck.get_most_recently_cast_card().abilities:
		if ability.should_destroy_on_cast():
			return true
	return false

func estimate_power(_card_type: CardType) -> int:
	return 30  # This is just a weird one...

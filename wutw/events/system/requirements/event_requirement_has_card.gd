@tool
class_name EventRequirement_HasCard
extends EventRequirement

@export var card_type: CardType

func is_satisfied(run: Run, _event: Event) -> bool:
	return card_type in run.get_deck_cards()

func to_expression() -> String:
	return 'has_card(' + card_type.card_name.to_lower() + ')'

func describe(_run: Run, detailed: bool) -> String:
	if detailed:
		return tr('Must have the %s <term_lower:glyph> in your <term_lower:card_deck>.') % card_type.get_term_tag()
	else:
		return '%s <term:glyph>' % card_type.symbol

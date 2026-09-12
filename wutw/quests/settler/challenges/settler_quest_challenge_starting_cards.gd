class_name SettlerQuestChallenge_StartingCards
extends SettlerQuestChallenge

@export var card_types: Array[CardType]

func apply_starting_modifiers(_quest: Quest_Settler, run: Run) -> void:
	assert(card_types)
	for card_type in card_types:
		run.add_card_to_deck(card_type)

func describe() -> String:
	if card_types.size() == 1:
		return tr('Add a %s <term_lower:glyph> to the starting <term_lower:card_deck>.') % card_types[0].get_term_tag()
	else:
		var card_tags: Array[String]
		var all_same := true
		for i in range(1, card_types.size()):
			if card_types[i] != card_types[0]:
				all_same = false
				break
		if all_same:
			return tr('Add %d %s <term_lower:glyph>s to the starting <term_lower:card_deck>.') % [
				card_types.size(), card_types[0].get_term_tag()]
		else:
			card_tags.assign(card_types.map(func(c: CardType) -> String: return c.get_term_tag()))
			return tr('Add %s <term_lower:glyph>s to the starting <term_lower:card_deck>.') % Utils.format_conjunction(card_tags)

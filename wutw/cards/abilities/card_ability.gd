@tool @abstract
class_name CardAbility
extends Resource

static func _get_ancestor_deck(node: Card) -> CardDeck:
	if not node:
		return null
	var parent := node.get_parent()
	while parent and parent is not CardDeck:
		parent = parent.get_parent()
	return parent as CardDeck

@abstract func get_term() -> Term
@abstract func get_ability_name(markedup: bool = false, short: bool = false) -> String
@abstract func get_ability_tooltip(card: Card) -> String
@abstract func cast(_card: Card) -> void
# Rough units:
#   1 targeted slot fill = 10
#   1 bonus = 0.8
#   1 inspiration = 3
@abstract func estimate_power(_card_type: CardType) -> int

func should_destroy_on_cast() -> bool:
	return false

func scales_when_looped() -> bool:
	return true

func get_search_text() -> String:
	return get_ability_name(false)

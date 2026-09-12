@tool
class_name ShardType_Poets
extends ShardType

@export var min_beauty: int = 100
@export var beauty: BonusType
@export var poem_card: CardType

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0: return run_data.bonus_amounts.get_amount(beauty) / float(min_beauty)
		1: return 1 if poem_card in run_data.deck_cards else 0
		_: return -1

func describe_requirements() -> Array[String]:
	return [
		tr('At least %d %s.') % [min_beauty, beauty.get_term_tag()],
		tr('A %s <term_lower:glyph> in the <term_lower:card_deck>.') % poem_card.get_term_tag(),
	]

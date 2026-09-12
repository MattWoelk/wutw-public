@tool
class_name CardAbility_AddRandomCard
extends CardAbility

@export var count: int = 1
@export var negative: bool = false

func get_ability_name(_markedup: bool = false, _short: bool = false) -> String:
	var text := tr('Conjure', 'ABILITY') + ' '
	if count > 1:
		text += '%d ' % count

	if negative:
		text += tr('Negative')
	else:
		text += tr('Random')

	return text

func get_ability_tooltip(_card: Card) -> String:
	if negative:
		if count == 1:
			return tr('Add a random <term_lower:negative_glyph> to your <term:hand>.')
		else:
			return tr('Add %d random <term_lower:negative_glyph>s to your <term:hand>') % count
	else:
		if count == 1:
			return tr('Add a random <term_lower:glyph> to your <term:hand> based on the current <term_lower:card_rarity_tier>.')
		else:
			return (tr('Add %d random <term_lower:glyph>s to your <term:hand> based on the current <term_lower:card_rarity_tier>.') %
					count)

func get_term() -> Term:
	return load('res://cards/abilities/terms/term_card_ability_add_card.tres')

func cast(card: Card) -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	var deck := stage.get_card_deck()
	for _i in count:
		stage.queue_action(func() -> void:
			var card_type: CardType
			if negative:
				const WEIGHTS_BY_ASPECT_COUNT: Array[float] = [1, 0.3, 0.15, 0.05, 0.05, 0.05, 0.05, 0.05]
				var options: Dictionary[CardType, float]
				for option in CardType.get_all_card_types_by_tier(CardType.Rarity.NEGATIVE):
					options[option] = WEIGHTS_BY_ASPECT_COUNT[option.aspects.size()]
				card_type = run.get_card_reward_random().pick_weighted_dict(options)[0]
			else:
				var tier_weights := run.get_current_card_reward_weights()
				var card_types := Utils.choose_card_rewards(run, tier_weights, 1, true)
				if Utils.ensure(not card_types.is_empty()):
					card_type = card_types[0]
			if not Utils.ensure(card_type != null):
				card_type = card.card_type
			await deck.add_card_to_hand(card_type, CardDeck.CardDrawReason.ABILITY)
		)

func estimate_power(_card_type: CardType) -> int:
	if negative:
		return -5 * count

	match count:
		1: return 10
		2: return 22
		3: return 36
		4: return 50
		_: return 100

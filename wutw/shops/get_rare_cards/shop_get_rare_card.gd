@tool
class_name ShopGetRareCard
extends ShopBase

static var CARD_REWARD_SCENE := AsyncLoadedResource.new('res://stage/card_reward_choice.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)
const TIER_BONUS_PERCENT: int = 75
const MODIFIER_TAG := 'shop_get_rare_cards'

var _reward_choice: CardRewardChoice

func _handle_esc() -> bool:
	if not _reward_choice:
		_close()
		return true
	else:
		return false

func _on_action_pressed() -> void:
	Utils.get_active_run().get_vars().add_modifier(
		RunVars.Var.CARD_TIER_BONUS_PERCENT, TIER_BONUS_PERCENT, MODIFIER_TAG)
	_reward_choice = CARD_REWARD_SCENE.instantiate_loaded_scene() as CardRewardChoice
	_reward_choice.allow_removal = false
	_reward_choice.selection_finished.connect(_on_card_selected)
	add_child(_reward_choice)

func _on_card_selected() -> void:
	Utils.get_active_run().get_vars().remove_modifier(MODIFIER_TAG)
	_pay_cost()
	_update_action_availability()

	await _reward_choice.close()
	_reward_choice = null

func _get_action_button_tooltip() -> String:
	return tr('Retrieve a <related_term:card_rarity_tier>powerful <term:glyph>' +
			' from the portal to <term_lower:add_card> to your <term:card_deck>.')

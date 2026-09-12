@tool
class_name ShopHeal
extends ShopBase

const HEAL_AMOUNT: int = 10

func _on_action_pressed() -> void:
	Utils.get_active_run().modify_inspiration(HEAL_AMOUNT, Run.InspirationChangeReason.SHOP)
	_pay_cost()
	_update_action_availability()

func _get_action_button_tooltip() -> String:
	return tr('Restore %d points of <term:inspiration>.') % HEAL_AMOUNT

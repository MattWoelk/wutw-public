@tool
class_name ShopTrade
extends ShopBase

const BUY_AMOUNT: int = 25

var _sell_type: BonusType
var _buy_type: BonusType

func _ready() -> void:
	super._ready()
	if Utils.is_in_editor():
		return

	var run := Utils.get_active_run()
	run.get_bonus_amounts().changed.connect(_update_buttons)

	for child in %SellBox.get_children():
		var button := child as Button
		if not button:
			continue  # Label
		var listing := child.get_child(0) as BonusCounter
		listing.current_value = -_get_scaled_cost()
		(listing.get_node('%Bonus') as Control).mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE
		button.pressed.connect(func() -> void: _sell_type = listing.bonus_type; _update_buttons())

	for child in %BuyBox.get_children():
		var button := child as Button
		if not button:
			continue  # Label
		var listing := child.get_child(0) as BonusCounter
		listing.current_value = BUY_AMOUNT
		(listing.get_node('%Bonus') as Control).mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE
		button.pressed.connect(func() -> void: _buy_type = listing.bonus_type; _update_buttons())

	_update_buttons()

func _update_buttons() -> void:
	var run := Utils.get_active_run()

	for child in %SellBox.get_children():
		var button := child as Button
		if not button:
			continue  # Label
		var listing := child.get_child(0) as BonusCounter
		button.disabled = listing.bonus_type == _buy_type or run.get_bonus_amounts().get_amount(listing.bonus_type) < _get_scaled_cost()
		if button.disabled:
			button.button_pressed = false
			if _sell_type == listing.bonus_type:
				_sell_type = null

	for child in %BuyBox.get_children():
		var button := child as Button
		if not button:
			continue  # Label
		var listing := child.get_child(0) as BonusCounter
		button.disabled = listing.bonus_type == _sell_type
		if button.disabled:
			button.button_pressed = false
			if _buy_type == listing.bonus_type:
				_buy_type = null

	_update_action_availability()

func _on_action_pressed() -> void:
	var run := Utils.get_active_run()
	# These changes automatically trigger trading UI updates.
	run.gain_bonus(BonusGain.new(_buy_type, BUY_AMOUNT, self))
	run.gain_bonus(BonusGain.new(_sell_type, -_get_scaled_cost(), self))
	run.notify_shop_transaction(shop_type)
	_update_action_availability()

func _update_action_availability() -> void:
	var run := Utils.get_active_run()
	if _buy_type and _sell_type and not run.has_shop_been_used_this_round(shop_type):
		(%ActionButton as Button).disabled = false
	else:
		(%ActionButton as Button).disabled = true
	(%ActionButton as Button).text = tr('Confirm')

func _get_scaled_cost() -> int:
	return floori(shop_type.base_cost * (100 - Skill.get_skill_var(Skill.Var.TRADE_DISCOUNT_PERCENTAGE)) / 100.0)

func _get_action_button_tooltip() -> String:
	var text := tr('Shift the priorities of your <term_lower:settlement>s')
	if _buy_type and _sell_type:
		text += (tr(' to focus on %s in favor of %s.\n\n[ul]\n Gain %d %s\n Lose %d %s\n[/ul]') %
				 [_buy_type.get_term_tag(), _sell_type.get_term_tag(),
				  BUY_AMOUNT, _buy_type.get_term_tag(),
				  _get_scaled_cost(), _sell_type.get_term_tag()])
	elif _buy_type:
		text += (tr(' to focus on %s.\n\n[b]You must choose a <term:bonus> to sacrifice in return.[/b]') %
				 _buy_type.get_term_tag())
	elif _sell_type:
		text += (tr(' to focus less on %s.\n\n[b]You must choose a <term:bonus> to gain in return.[/b]') %
				 _sell_type.get_term_tag())
	else:
		text += tr('.')
		text += '\n\n'
		text += tr('[b]You must choose a <term:bonus> to focus on, and a <term:bonus> to sacrifice in return.[/b]')
	return text

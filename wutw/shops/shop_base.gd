@tool
class_name ShopBase
extends Node

signal finished

@export var shop_type: ShopType:
	set(value):
		shop_type = value
		if is_node_ready():
			_update()

var _closing := false

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_update()
	Utils.get_active_run().signals.bonus_gained.connect(_update_action_availability.unbind(3))
	Utils.get_active_run().signals.bonus_lost.connect(_update_action_availability.unbind(3))
	(%ActionButton as Button).pressed.connect(_on_action_pressed)
	(%FinishButton as Button).pressed.connect(_close)
	GlobalTooltipSystem.attach(%ActionButton as Button, _get_action_button_tooltip_full,
			[Tooltip.RelativeDirection.BELOW, Tooltip.RelativeDirection.ABOVE, Tooltip.RelativeDirection.RIGHT],
			[Tooltip.Alignment.CENTERED])

	(%ScrollPanel as ScrollPanel).animate_unroll()

func _update_font_size() -> void:
	var font_size := roundi(16 * GameSettings.Interface.paragraph_font_scale.value())
	(%IntroLabel as Label).add_theme_font_size_override('font_size', font_size)

func _update() -> void:
	if not shop_type:
		assert(Utils.is_in_editor())
		return
	(%BGArt as TextureRect).texture = shop_type.background_texture
	(%CreditsIcon as CreditsIcon).art_piece = shop_type.background_credit
	(%TitleLabel as Label).text = tr(shop_type.title)
	(%IntroLabel as Label).text = tr(shop_type.intro)
	(%ActionLabel as Label).text = tr(shop_type.action_description)
	(%ActionButton as Button).text = tr(shop_type.action_button_label)

	_update_action_availability()

func _handle_esc() -> bool:
	_close()
	return true

func _close() -> void:
	if not _closing:
		_closing = true
		Utils.set_input_enabled(%ScrollPanel as ScrollPanel, false)
		(%BG as FadedBackground).fade_out()
		await (%ScrollPanel as ScrollPanel).animate_roll()
		finished.emit()

func _update_action_availability() -> void:
	var run := Utils.get_active_run()
	var available := run.get_bonus_amounts().get_amount(shop_type.cost_type) if run else 9999
	(%ActionLabel as Label).visible = true
	(%CostBox as Control).visible = true
	if shop_type.cost_type:
		(%CostProgress as UkiyoeProgressBar).value = available
		(%CostProgress as UkiyoeProgressBar).max_value = _get_scaled_cost()
		(%CostBonus as Bonus).bonus_type = shop_type.cost_type
	if run.has_shop_been_used_this_round(shop_type):
		(%ActionButton as Button).disabled = true
	else:
		(%ActionButton as Button).disabled = available < _get_scaled_cost()

func _get_scaled_cost() -> int:
	return shop_type.get_scaled_cost(Utils.get_active_run())

func _on_action_pressed() -> void:
	assert(false, 'Subclass must implement _on_action_pressed()')

func _get_action_button_tooltip() -> String:
	assert(false, 'Subclass must implement _get_action_button_tooltip()')
	return ''

func _get_action_button_tooltip_full() -> String:
	var result := _get_action_button_tooltip()
	var run := Utils.get_active_run()
	if run.has_shop_been_used_this_round(shop_type):
		result += '\n\n'
		result += tr('[b]Only one transaction in each <term_lower:shop> can be performed per <term_lower:stage>.[/b]')
	return result

func _pay_cost() -> void:
	var run := Utils.get_active_run()
	run.notify_shop_transaction(shop_type)

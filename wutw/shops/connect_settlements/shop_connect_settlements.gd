@tool
class_name ShopConnectSettlements
extends ShopBase

func _on_action_pressed() -> void:
	var unconnected := _get_unconnected_settlements()
	assert(unconnected)
	unconnected[0].connect_to_capital()
	(%ResultLabel as Label).text = tr('Connected %s.') % unconnected[0].state.settlement_name.get_native_display_name()
	(%ResultLabel as Label).visible = true
	_pay_cost()
	_update_action_availability()

func _update_action_availability() -> void:
	super._update_action_availability()
	if not _get_unconnected_settlements():
		(%ActionButton as Button).disabled = true

func _get_unconnected_settlements() -> Array[Settlement]:
	var run := Utils.get_active_run()
	var map := run.get_map()
	var unconnected: Array[Settlement]
	for map_object in map.get_map_objects():
		if map_object is Settlement:
			if not (map_object as Settlement).is_settlement_connected():
				unconnected.append(map_object)
	return unconnected

func _get_action_button_tooltip() -> String:
	if _get_unconnected_settlements():
		return tr('Establish a <term_lower:connect_settlement>ion between a random <term_lower:settlement> and the <term:capital>.')
	else:
		return tr('All the <term_lower:settlement>s are already <term_lower:connect_settlement>ed to the <term:capital>.')

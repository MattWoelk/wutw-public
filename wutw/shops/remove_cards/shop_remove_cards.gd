@tool
class_name ShopRemoveCards
extends ShopBase

static var DECK_VIEWER_SCENE := AsyncLoadedResource.new('res://cards/viewer/card_deck_viewer.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)

var _remove_selector: CardDeckViewer

func _handle_esc() -> bool:
	if not _remove_selector:
		_close()
		return true
	else:
		return false

func _on_action_pressed() -> void:
	_remove_selector = DECK_VIEWER_SCENE.instantiate_loaded_scene() as CardDeckViewer
	_remove_selector.cards = Utils.get_active_run().get_deck_cards().duplicate()
	_remove_selector.cards.sort_custom(func(a: CardType, b: CardType) -> bool:
		return CardType.compare(a, b, true)
	)
	_remove_selector.title = tr('Choose Glyph to Remove')
	_remove_selector.close_button_label = tr('Cancel')
	_remove_selector.allow_card_selection = true
	_remove_selector.allow_quick_dismiss = false
	_remove_selector.card_selected.connect(_on_card_remove_selected)
	GlobalUI.add_layer_content(_remove_selector, UI.Layer.GAME_MENU_SUBMENU)

func _on_card_remove_selected(card: Card) -> void:
	Utils.get_active_run().remove_card_from_deck(card.card_type)

	Utils.set_input_enabled(%ScrollPanel as ScrollPanel, false)
	Utils.set_input_enabled(_remove_selector.get_main_control(), false)
	_remove_selector.allow_quick_dismiss = false
	await card.tear_up()
	await get_tree().create_timer(Utils.anim_duration(0.5)).timeout
	await _remove_selector.close()
	Utils.set_input_enabled(%ScrollPanel as ScrollPanel, true)

	_pay_cost()
	_update_action_availability()
	_remove_selector.close()
	_remove_selector = null

func _update_action_availability() -> void:
	super._update_action_availability()
	var run := Utils.get_active_run()
	var min_deck_size := run.get_var(RunVars.Var.MIN_DECK_SIZE)
	if run.get_deck_cards().size() <= min_deck_size:
		(%ActionButton as Button).disabled = true

func _get_action_button_tooltip() -> String:
	var run := Utils.get_active_run()
	var min_deck_size := run.get_var(RunVars.Var.MIN_DECK_SIZE)
	if run.get_deck_cards().size() <= min_deck_size:
		return tr('The <term:card_deck> cannot contain fewer than %d <term:glyph>s.') % min_deck_size
	else:
		return tr('<term:remove_card> a chosen <term:glyph> from your <term:card_deck>.')

@tool
class_name ShopRecallCards
extends ShopBase

static var DECK_VIEWER_SCENE := AsyncLoadedResource.new('res://cards/viewer/card_deck_viewer.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)

var _card_selector: CardDeckViewer

func _handle_esc() -> bool:
	if not _card_selector:
		_close()
		return true
	else:
		return false

func _on_action_pressed() -> void:
	_card_selector = DECK_VIEWER_SCENE.instantiate_loaded_scene() as CardDeckViewer
	var recallable_cards := GlobalSaveGame.get_unlocked_cards()
	for card in Utils.get_active_run().get_deck_cards():
		recallable_cards.erase(card)
	if not recallable_cards:
		# Somehow, we already have all the cards we could recall. Allow copies.
		recallable_cards = GlobalSaveGame.get_unlocked_cards()
	_card_selector.cards = recallable_cards
	_card_selector.cards.sort_custom(CardType.compare)
	_card_selector.title = tr('Choose Glyph to Recall')
	_card_selector.close_button_label = tr('Cancel')
	_card_selector.allow_card_selection = true
	_card_selector.card_selected.connect(_on_card_selected)
	GlobalUI.add_layer_content(_card_selector, UI.Layer.GAME_MENU_SUBMENU)

func _on_card_selected(card: Card) -> void:
	Utils.get_active_run().add_card_to_deck(card.card_type)
	_pay_cost()
	_update_action_availability()
	_card_selector.close()
	_card_selector = null

func _get_action_button_tooltip() -> String:
	return tr('Recall an <term:craft>d <term:glyph> to <term_lower:add_card> to your <term:card_deck>.')

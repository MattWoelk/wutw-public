@tool
class_name ShopMakeInnateCards
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
	var run := Utils.get_active_run()
	var cards := run.get_deck_cards().duplicate()
	for card in run.get_innate_cards():
		cards.erase(card)
	_card_selector.cards = cards
	_card_selector.cards.sort_custom(CardType.compare)
	_card_selector.title = tr('Choose Card to Make Innate')
	_card_selector.close_button_label = tr('Cancel')
	_card_selector.allow_card_selection = true
	_card_selector.allow_quick_dismiss = false
	_card_selector.card_selected.connect(_on_card_selected)
	GlobalUI.add_layer_content(_card_selector, UI.Layer.GAME_MENU_SUBMENU)

func _on_card_selected(card: Card) -> void:
	Utils.get_active_run().make_card_innate(card.card_type)
	_pay_cost()
	_update_action_availability()
	_card_selector.close()
	_card_selector = null

func _get_action_button_tooltip() -> String:
	return tr('Make a <term:glyph> <term:innate>.')

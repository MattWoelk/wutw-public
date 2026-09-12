@tool
class_name CardAbility_Imitate
extends CardAbility

static var DIALOG_SCENE := AsyncLoadedResource.new('res://cards/viewer/card_deck_viewer.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var count: int = 1

func get_ability_name(_markedup: bool = false, _short: bool = false) -> String:
	var result := tr('Imitate', 'ABILITY')
	return (result + ' ' + str(count)) if count > 1 else result

func get_ability_tooltip(_card: Card) -> String:
	if count == 1:
		return tr('Choose a <term_lower:glyph> from your <term_lower:hand> and add a copy of it to your <term_lower:hand>.')
	else:
		return tr('Choose a <term_lower:glyph> from your <term_lower:hand> and add %d copies of it to your <term_lower:hand>.') % count

func get_term() -> Term:
	return load('res://cards/abilities/terms/term_card_ability_imitate.tres')

func cast(_card: Card) -> void:
	var stage := Utils.get_active_run().get_current_stage()
	var deck := stage.get_card_deck()
	stage.queue_action(func() -> void:
		for i in count:
			var cards: Array[CardType]
			for card in deck.get_hand_cards():
				cards.append(card.card_type)
			if not cards:
				GlobalUI.show_error(tr('No more <term_lower:glyph>s in the <term_lower:hand>.'))
				break
			var viewer := DIALOG_SCENE.instantiate_loaded_scene() as CardDeckViewer
			viewer.cards = cards.duplicate()
			viewer.title = tr('Pick a Glyph to Imitate')
			viewer.allow_card_selection = true
			viewer.allow_quick_dismiss = false
			viewer.close_button_label = tr('Skip Imitating')
			viewer.card_selected.connect(func(card: Card) -> void:
				deck.add_card_to_hand(card.card_type, CardDeck.CardDrawReason.ABILITY)
				viewer.close()
			)
			GlobalUI.add_layer_content(viewer, UI.Layer.GAME_MENU)
			await viewer.closed
	)

func estimate_power(_card_type: CardType) -> int:
	return 4 + 13 * count

func scales_when_looped() -> bool:
	return true

@tool
class_name CardAbility_Recall
extends CardAbility

static var DIALOG_SCENE := AsyncLoadedResource.new('res://cards/viewer/card_deck_viewer.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var count: int = 1

func get_ability_name(_markedup: bool = false, _short: bool = false) -> String:
	var result := tr('Recall', 'ABILITY')
	if count > 1:
		result += ' ' + str(count)
	return result

func get_ability_tooltip(_card: Card) -> String:
	if count == 1:
		return tr('Choose a <term_lower:glyph> from the <term_lower:discard_pile> and <term:draw> it.')
	else:
		return tr('Choose %s <term_lower:glyph>s from the <term_lower:discard_pile> and <term:draw> them.') % count

func get_term() -> Term:
	return load('res://cards/abilities/terms/term_card_ability_recall.tres')

func cast(_card: Card) -> void:
	var stage := Utils.get_active_run().get_current_stage()
	var deck := stage.get_card_deck()
	stage.queue_action(func() -> void:
		for i in count:
			var cards := deck.get_discard_pile_cards()
			if not cards:
				GlobalUI.show_error(tr('No more <term_lower:glyph>s in the <term_lower:discard_pile>.'))
				break
			var viewer := DIALOG_SCENE.instantiate_loaded_scene() as CardDeckViewer
			viewer.cards = cards.duplicate()
			viewer.title = tr('Pick a Glyph to Recall')
			viewer.allow_card_selection = true
			viewer.allow_quick_dismiss = false
			viewer.close_button_label = tr('Skip Recalling')
			viewer.show_minimize_button = true
			viewer.card_selected.connect(func(card: Card) -> void:
				deck.draw_specific_card(card.card_type, CardDeck.CardDrawReason.ABILITY, true)
				viewer.close()
			)
			GlobalUI.add_layer_content(viewer, UI.Layer.GAME_MENU)
			await viewer.closed
	)

func estimate_power(card_type: CardType) -> int:
	if card_type.abilities.size() == 1 and count > 1:
		return 1000  # Can allow infinite loops!
	if card_type.abilities.size() > 1:
		var other_ability := card_type.abilities[1 if card_type.abilities[0] == self else 0]
		if other_ability.scales_when_looped() and other_ability.estimate_power(card_type) > 0:
			return 1000  # Can allow infinite loops!
	match count:
		1: return 17
		2: return 60
		3: return 120
		4: return 180
		_: return count * 30

func scales_when_looped() -> bool:
	return true

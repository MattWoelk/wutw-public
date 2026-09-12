@tool
class_name CardAbility_Divine
extends CardAbility

static var DIALOG_SCENE := AsyncLoadedResource.new('res://cards/abilities/divine_ability_dialog.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var count: int = 1

func get_ability_name(_markedup: bool = false, _short: bool = false) -> String:
	if Utils.is_realistic_era():
		return tr('Predict', 'ABILITY') + ' ' + str(count)
	else:
		return tr('Divine', 'ABILITY') + ' ' + str(count)

func get_ability_tooltip(_card: Card) -> String:
	if count == 1:
		return tr('See the top <term_lower:glyph> of the <term_lower:draw_pile>, and move it to the <term_lower:discard_pile> if desired.')
	else:
		return tr('See the top %d <term_lower:glyph>s of the <term_lower:draw_pile>, in order, and move any to the <term_lower:discard_pile> if desired.') % count

func get_term() -> Term:
	return load('res://cards/abilities/terms/term_card_ability_divine.tres')

func cast(_card: Card) -> void:
	var stage := Utils.get_active_run().get_current_stage()
	var deck := stage.get_card_deck()
	stage.queue_action(func() -> void:
		var dialog_scene := DIALOG_SCENE.instantiate_loaded_scene() as DivineAbilityDialog
		var run := Utils.get_active_run()
		dialog_scene.cards = deck.get_draw_pile_cards().slice(0, count + run.get_var(RunVars.Var.DIVINE_ABILITY_BONUS))
		GlobalUI.add_layer_content(dialog_scene, UI.Layer.GAME_MENU)
		await dialog_scene.closed
	)

func estimate_power(_card_type: CardType) -> int:
	@warning_ignore('integer_division')
	return 4 + count + count / 2

func scales_when_looped() -> bool:
	return false

func get_search_text() -> String:
	return ' '.join([tr('Divine', 'ABILITY'), tr('Predict', 'ABILITY'), str(count)])

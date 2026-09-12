@tool
class_name ShopAccordMonument
extends ShopBase

static var DECK_VIEWER_SCENE := AsyncLoadedResource.new('res://cards/viewer/card_deck_viewer.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)
static var RELIC_SELECTOR_SCENE := AsyncLoadedResource.new('res://relics/selector/relic_selector.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)

# This is an awkward subclass that replaces almost all behavior. It's only a ShopBase subclass
# so we can reuse the functionality of unlocking the "shop" and opening/closing the UI.

func _ready() -> void:
	# Skip most of parent's logic.

	_update()
	_reveal_layer(%BG_Shrine as TextureRect, [%Button_Knowledge, %Button_Productivity], false)
	_reveal_layer(%BG_Temple as TextureRect, [%Button_Spirit, %Button_Illumination, %Button_Connection], false)
	_reveal_layer(%BG_Pagoda as TextureRect, [%Button_Relic1, %Button_Relic2], false)
	_reveal_layer(%BG_Crowd as TextureRect, [%Button_Crowd], false)

	(%ScrollPanel as ScrollPanel).animate_unroll()

func _update() -> void:
	if Utils.is_in_editor():
		return
	var run := Utils.get_active_run()

	(%Button_Knowledge as AccordButton).available = run.get_bonus_amounts().get_amount(
		BonusType.get_bonus_type_by_id('knowledge')) >= 100
	(%Button_Productivity as AccordButton).available = run.get_bonus_amounts().get_amount(
		BonusType.get_bonus_type_by_id('productivity')) >= 200

	(%Button_Spirit as AccordButton).available = false
	(%Button_Illumination as AccordButton).available = false
	(%Button_Connection as AccordButton).available = false
	for card_type in run.get_deck_cards():
		if card_type.rarity >= CardType.Rarity.RARE:
			if AspectType.get_aspect_type_by_id('spirit') in card_type.aspects:
				(%Button_Spirit as AccordButton).available = true
			if AspectType.get_aspect_type_by_id('illumination') in card_type.aspects:
				(%Button_Illumination as AccordButton).available = true
			if AspectType.get_aspect_type_by_id('connection') in card_type.aspects:
				(%Button_Connection as AccordButton).available = true

	(%Button_Relic1 as AccordButton).available = not run.get_current_relics().is_empty()
	(%Button_Relic2 as AccordButton).available = ((%Button_Relic1 as AccordButton).is_fulfilled()
	 											   and not run.get_current_relics().is_empty())

	(%Button_Crowd as AccordButton).available = (
		(%Button_Knowledge as AccordButton).is_fulfilled() and
		(%Button_Productivity as AccordButton).is_fulfilled() and
		(%Button_Spirit as AccordButton).is_fulfilled() and
		(%Button_Illumination as AccordButton).is_fulfilled() and
		(%Button_Connection as AccordButton).is_fulfilled() and
		(%Button_Relic1 as AccordButton).is_fulfilled() and
		(%Button_Relic2 as AccordButton).is_fulfilled()
	)

	_reveal_layer(%BG_Shrine as TextureRect, [%Button_Knowledge, %Button_Productivity], true)
	_reveal_layer(%BG_Temple as TextureRect, [%Button_Spirit, %Button_Illumination, %Button_Connection], true)
	_reveal_layer(%BG_Pagoda as TextureRect, [%Button_Relic1, %Button_Relic2], true)
	_reveal_layer(%BG_Crowd as TextureRect, [%Button_Crowd], true)

func _reveal_layer(layer: TextureRect, buttons: Array[AccordButton], animate: bool) -> void:
	var revealed := true
	for button in buttons:
		if not button.is_fulfilled():
			revealed = false
			break

	if animate:
		var tween := create_tween()
		tween.tween_property(layer, 'modulate:a', 1 if revealed else 0, 2.0)
		tween.play()
	else:
		layer.modulate.a = 1 if revealed else 0

func _update_action_availability() -> void:
	assert(false)

func _get_scaled_cost() -> int:
	assert(false)
	return 9999

func _on_action_pressed() -> void:
	assert(false)

func _get_action_button_tooltip() -> String:
	assert(false)
	return ''

func _get_action_button_tooltip_full() -> String:
	assert(false)
	return ''

func _pay_cost() -> void:
	assert(false)

func _on_button_knowledge_pressed() -> void:
	var run := Utils.get_active_run()
	run.gain_bonus(BonusGain.new(BonusType.get_bonus_type_by_id('knowledge'), -100, self))
	(%Button_Knowledge as AccordButton).mark_fulfilled()
	_update()

func _on_button_productivity_pressed() -> void:
	var run := Utils.get_active_run()
	run.gain_bonus(BonusGain.new(BonusType.get_bonus_type_by_id('productivity'), -200, self))
	(%Button_Productivity as AccordButton).mark_fulfilled()
	_update()

func _on_button_spirit_pressed() -> void:
	_ask_remove_card(AspectType.get_aspect_type_by_id('spirit'), (%Button_Spirit as AccordButton))

func _on_button_illumination_pressed() -> void:
	_ask_remove_card(AspectType.get_aspect_type_by_id('illumination'), (%Button_Illumination as AccordButton))

func _on_button_connection_pressed() -> void:
	_ask_remove_card(AspectType.get_aspect_type_by_id('connection'), (%Button_Connection as AccordButton))

func _on_button_relic_1_pressed() -> void:
	_ask_remove_relic(%Button_Relic1 as AccordButton)

func _on_button_relic_2_pressed() -> void:
	_ask_remove_relic(%Button_Relic2 as AccordButton)

func _on_button_crowd_pressed() -> void:
	(%Button_Crowd as AccordButton).mark_fulfilled()
	_update()
	GlobalSaveGame.get_events_state().set_bool('global', 'accord_monument_built', true)
	GlobalSaveGame.save_game()

func _ask_remove_card(aspect_type: AspectType, button: AccordButton) -> void:
	var run := Utils.get_active_run()
	var options: Array[CardType]
	for card_type in run.get_deck_cards():
		if card_type.rarity >= CardType.Rarity.RARE and aspect_type in card_type.aspects:
			options.append(card_type)
	assert(not options.is_empty())

	var remove_selector := DECK_VIEWER_SCENE.instantiate_loaded_scene() as CardDeckViewer
	remove_selector.cards = options
	remove_selector.cards.sort_custom(CardType.compare)
	remove_selector.title = tr('Choose Glyph to Dedicate')
	remove_selector.close_button_label = tr('Cancel')
	remove_selector.allow_card_selection = true
	remove_selector.allow_quick_dismiss = false
	remove_selector.card_selected.connect(func(card: Card) -> void:
		run.remove_card_from_deck(card.card_type)
		button.mark_fulfilled()
		_update()
		remove_selector.close()
	)
	GlobalUI.add_layer_content(remove_selector, UI.Layer.GAME_MENU_SUBMENU)

func _ask_remove_relic(button: AccordButton) -> void:
	var run := Utils.get_active_run()
	var relic_selector := RELIC_SELECTOR_SCENE.instantiate_loaded_scene() as RelicSelector
	relic_selector.relic_reward_pool = run.get_current_relics()
	relic_selector.manual_select = true
	relic_selector.add_selected = false
	relic_selector.selected.connect(func(relic: Relic) -> void:
		run.remove_relic(relic)
		button.mark_fulfilled()
		_update()
	)
	GlobalUI.add_layer_content(relic_selector, UI.Layer.GAME_MENU_SUBMENU)

class_name CraftingPurchase
extends Node2D

const CARD_TIER_WEIGHTS := [1.0, 1.0 / 2, 1.0 / 4, 1.0 / 8, 1.0 / 16, 1.0 / 32, 0]

var _animating := false
var _sfx_playing_id: int = 0
var _closing := false

func _ready() -> void:
	(%VBox_Strokes as Control).visible = Skill.get_skill_var(Skill.Var.BUY_STROKES) > 0
	(%VBox_Card as Control).visible = Skill.get_skill_var(Skill.Var.BUY_CARDS) > 0
	_update_buy_button()
	GlobalSaveGame.changed.connect(_update_buy_button)

	GlobalTooltipSystem.attach(%BuyButton as Control, _make_buy_button_tooltip_text,
			[Tooltip.RelativeDirection.BELOW], [Tooltip.Alignment.CENTERED])

	(%ScrollPanel as ScrollPanel).animate_unroll()

func _handle_esc() -> bool:
	if not _animating:
		close()
	return true

func close() -> void:
	if not _closing:
		_closing = true
		Utils.set_input_enabled(%ScrollPanel as Control, false)
		(%BG as FadedBackground).fade_out()
		await (%ScrollPanel as ScrollPanel).animate_roll()
		queue_free()

func _on_close_button_pressed() -> void:
	close()

func _update_buy_button() -> void:
	(%BuyButton as Button).disabled = _get_available_cards().is_empty() or GlobalSaveGame.insights < _get_card_cost()
	(%BuyButton as Button).text = str(_get_card_cost())

func _get_available_cards() -> Array[CardType]:
	var result: Array[CardType]
	for card_type in CardType.get_all_card_types():
		if GlobalSaveGame.has_seen_card(card_type):
			continue
		result.append(card_type)
	return result

func _get_card_cost() -> int:
	return GlobalSaveGame.get_seen_cards().size() * 2

func _on_buy_button_pressed() -> void:
	var options: Dictionary[CardType, float]
	for card_type in _get_available_cards():
		options[card_type] = CARD_TIER_WEIGHTS[card_type.rarity]

	var rng := GlobalSaveGame.get_hub_random().snapshot()
	var selected_card_type := rng.pick_weighted_dict(options)[0] as CardType

	_animating = true
	Utils.set_input_enabled(%ScrollPanel as Control, false)
	(%CloseButton as Button).disabled = true
	(%BuyButton as Button).disabled = true

	var _revealed := %RevealedCard as Card
	var _unknown := %UnknownCard as UnknownCard
	_revealed.animate_roll()
	_unknown.animate_roll()
	await get_tree().create_timer(1.0).timeout
	_start_sfx()
	await get_tree().create_timer(2.0).timeout
	_stop_sfx()
	_unknown.visible = false
	_revealed.card_type = selected_card_type
	_revealed.visible = true
	GlobalAudioSystem.play(AK.EVENTS.SFX_MAP_EXPEDITION_FINISH_NAME)
	await _revealed.animate_unroll()

	(%BuyButton as Button).disabled = false
	(%CloseButton as Button).disabled = false
	Utils.set_input_enabled(%ScrollPanel as Control, true)
	_animating = false

	GlobalSaveGame.mark_card_seen(selected_card_type)
	GlobalSaveGame.insights -= _get_card_cost()
	GlobalSaveGame.save_game()

func _start_sfx() -> void:
	_stop_sfx()
	_sfx_playing_id = GlobalAudioSystem.start_loop(AK.EVENTS.UI_DIALOGUE_TEXT_LOOP)

func _stop_sfx() -> void:
	if _sfx_playing_id:
		GlobalAudioSystem.stop_loop(_sfx_playing_id)
		_sfx_playing_id = 0

func _make_buy_button_tooltip_text() -> String:
	var text := tr('Invest <term:insight>s to discover a random new <term_lower:glyph>.')
	text += '\n\n' + tr('It will still need to be <term_lower:craft>d before use.')
	return text

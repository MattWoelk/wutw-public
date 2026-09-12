@tool
class_name AspectCounter
extends Control

signal clicked

const RADIUS: int = 12

@export var aspect_type: AspectType:
	set(value):
		aspect_type = value
		if is_node_ready():
			_update()
@export var count: int:
	set(value):
		count = value
		if is_node_ready():
			_update()
@export var tooltip_directions: Array[Tooltip.RelativeDirection] = [Tooltip.RelativeDirection.BELOW]

func _ready() -> void:
	_update()
	GlobalTooltipSystem.attach(
		self, _make_tooltip_text, tooltip_directions, [Tooltip.Alignment.CENTERED])
	if not Utils.is_in_editor():
		GlobalContextHighlight.request_on_hover(ContextHighlight.aspects(self, [aspect_type]))
		GlobalContextHighlight.offer_changed.connect(func(offered: ContextHighlight.Context) -> void:
			if offered:
				if aspect_type in offered.aspect_types:
					modulate.a = 1.1
					scale = Vector2(1.2, 1.2)
				else:
					modulate.a = 0.6
					scale = Vector2(1, 1)
			else:
				modulate.a = 1
				scale = Vector2(1, 1)
		)

func _get_minimum_size() -> Vector2:
	return Vector2(RADIUS * 2, RADIUS * 2)

func _gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if not mouse_event:
		return
	if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()

func _update() -> void:
	(%TextureRect as TextureRect).texture = aspect_type.slot_icon
	(%Label as Label).text = str(count)

func _make_tooltip_text() -> String:
	var run := Utils.get_active_run()
	if not run:
		return (tr('Your <term:card_deck> contains %d <term:glyph>(s) with %s <term:aspect>.') %
				[count, aspect_type.get_term_tag()])
	var stage := Utils.get_active_run().get_current_stage()
	if stage:
		var text := tr('Your <term:draw_pile> contains %d <term:glyph>(s) with %s <term:aspect>') % [count, aspect_type.get_term_tag()]
		if stage.get_card_deck().get_discard_pile_cards():
			var num_in_discards := 0
			for card_type in stage.get_card_deck().get_discard_pile_cards():
				if aspect_type in card_type.aspects:
					num_in_discards += 1
			text += tr(' and your <term:discard_pile> contain %d') % num_in_discards
		text += tr('.')
		if stage.get_redraws_left():
			var chance := roundi(_draw_probability(run.get_var(RunVars.Var.HAND_SIZE), true) * 100)
			text += (tr('\n\nYou have a %d%% chance to <term_lower:draw> a %s <term_lower:glyph> on your next full redraw.') %
					 [chance, aspect_type.get_term_tag()])
		else:
			text += (tr('\n\nYou have a %d%% chance to <term_lower:draw> a %s <term_lower:glyph> if you draw one card.') %
					 [roundi(_draw_probability(1, false) * 100), aspect_type.get_term_tag()])
		return text
	else:
		var cards_in_deck := run.get_deck_cards().size()
		var percent := roundi(float(count) / float(cards_in_deck) * 100.0)
		var type_hint: String
		if aspect_type.is_advanced:
			type_hint = tr('%s is an <term:advanced_aspect>, only useful for higher-level <term_lower:spot_upgrade>s.') % aspect_type.get_term_tag()
		else:
			type_hint = tr('%s is a <term:basic_aspect>, critical for starting initial <term_lower:spot_upgrade>s.') % aspect_type.get_term_tag()
		return (tr('Your <term:card_deck> contains %d <term:glyph>(s) providing %s,' +
				 ' which is %d%% of your <term_lower:glyph>s.\n\n%s') %
				[count, aspect_type.get_term_tag(), percent, type_hint])

func _draw_probability(draw_count: int, discard_hand: bool) -> float:
	var stage := Utils.get_active_run().get_current_stage()
	var card_deck := stage.get_card_deck()
	var draw_pile: Array[CardType] = card_deck.get_draw_pile_cards().duplicate()
	var discard_pile: Array[CardType] = card_deck.get_discard_pile_cards().duplicate()
	if discard_hand:
		for card in card_deck.get_hand_cards():  # Simulate drawing after discards
			discard_pile.append(card.card_type)

	var p_failed := 1.0
	for i in draw_count:
		if not draw_pile:
			draw_pile = discard_pile
			discard_pile = []
		if not draw_pile:
			break
		var num_matching := 0
		for card_type in draw_pile:
			if aspect_type in card_type.aspects:
				num_matching += 1
		if num_matching == draw_pile.size():
			return 1.0
		p_failed *= (1.0 - float(num_matching) / draw_pile.size())
		# Simulate drawing a non-matching card.
		for card_type in draw_pile:
			if aspect_type not in card_type.aspects:
				draw_pile.erase(card_type)
				break

	return 1 - p_failed

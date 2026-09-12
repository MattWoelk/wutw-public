@tool
class_name Relic_ArchivistSeal
extends Relic

var _most_recent_addition: CardType

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.card_added.connect(_on_card_added)
	_run.signals.redraw_finished.connect(_on_redraw_finished)

func on_removed() -> void:
	_run.signals.card_added.disconnect(_on_card_added)
	_run.signals.redraw_finished.disconnect(_on_redraw_finished)
	super.on_removed()

func save_data() -> Dictionary:
	var result := super.save_data()
	if _most_recent_addition:
		result['card'] = _most_recent_addition.symbol
	return result

func load_data(encoded_data: Dictionary) -> void:
	super.load_data(encoded_data)
	var symbol := encoded_data.get('card', '') as String
	if symbol:
		_most_recent_addition = CardType.get_card_type_by_name_or_symbol(symbol)
		_state = State.ACTIVE

func _on_card_added(card_type: CardType) -> void:
	_most_recent_addition = card_type
	_state = State.ACTIVE

func _on_redraw_finished(is_first: bool) -> void:
	if is_first and _most_recent_addition:
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			await _run.get_current_stage().get_card_deck().add_card_to_hand(
				_most_recent_addition, CardDeck.CardDrawReason.RELIC)
		)

func get_description() -> String:
	var result := tr(default_description)
	result += '\n\n'
	if _most_recent_addition:
		result += tr('Recorded glyph: %s') % _most_recent_addition.get_term_tag()
	else:
		result += tr('No glyph recorded yet.')
	return result

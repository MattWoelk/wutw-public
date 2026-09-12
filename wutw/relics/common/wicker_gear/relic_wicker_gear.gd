@tool
class_name Relic_WickerGear
extends Relic

@export var percent_chance: int = 50

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.ability_finished.connect(_on_ability_finished)

func on_removed() -> void:
	_run.signals.ability_finished.disconnect(_on_ability_finished)
	super.on_removed()

func _on_ability_finished(_card: Card, ability: CardAbility) -> void:
	if ability is CardAbility_Recycle:
		var deck := _run.get_current_stage().get_card_deck()
		if _run.get_card_deck_random().rand_float() <= percent_chance / 100.0:
			_run.run_or_queue_action(func() -> void:
				triggered.emit()
				await deck.draw(CardDeck.CardDrawReason.ABILITY, true, true)
			)

func get_description() -> String:
	return tr(default_description) % percent_chance

@tool
class_name Relic_TeaWhisk
extends Relic

@export var slots_required: int = 3

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.spot_recipe_activated.connect(_on_recipe_activated)
	_state = State.ACTIVE

func on_removed() -> void:
	_run.signals.spot_recipe_activated.disconnect(_on_recipe_activated)
	super.on_removed()

func _on_recipe_activated(spot_recipe: SpotRecipe) -> void:
	if spot_recipe.get_aspect_slots().size() >= slots_required:
		var deck := _run.get_current_stage().get_card_deck()
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			await deck.draw(CardDeck.CardDrawReason.RELIC, true)
		)

func get_description() -> String:
	return tr(default_description) % slots_required

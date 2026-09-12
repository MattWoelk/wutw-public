@tool
class_name HauntingTrigger_AbilityCast
extends HauntingTrigger

@export var abillity_class: CardAbility

func get_description(_mode: HauntingTrigger.Mode) -> String:
	if abillity_class:
		return tr('a %s <term_lower:card_ability> is <term_lower:cast_card>') % abillity_class.get_term().get_term_tag()
	else:
		return tr('an <term_lower:card_ability> is <term_lower:cast_card>')

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	if abillity_class:
		return tr('%s <term:cast_card>') % abillity_class.get_term().get_term_tag()
	else:
		return tr('<term:card_ability> <term:cast_card>')

func setup(_spot: Spot, _settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.ability_finished.connect(_on_ability_finished)

func cleanup(_spot: Spot, _settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.ability_finished.disconnect(_on_ability_finished)

func _on_ability_finished(card: Card, ability: CardAbility) -> void:
	if not abillity_class or abillity_class.get_script() == ability.get_script():
		triggered.emit(null, null, card.card_type)

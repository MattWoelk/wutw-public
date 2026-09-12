@tool
class_name Relic_DustyMirror
extends Relic

@export var percent_chance_to_block_discard: int = 50

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.ability_started.connect(_on_ability_started)

func on_removed() -> void:
	_run.signals.ability_started.disconnect(_on_ability_started)
	super.on_removed()

func _on_ability_started(_card: Card, ability: CardAbility) -> void:
	if ability is CardAbility_Discard:
		var deck := _run.get_current_stage().get_card_deck()
		var random := deck.get_random_state()
		var blocked := random.rand_float() <= float(percent_chance_to_block_discard) / 100.0
		if blocked:
			_run.get_vars().set_base_value(RunVars.Var.ABILITY_CASTS_BLOCKED, 1)
			triggered.emit()

func get_description() -> String:
	return tr(default_description) % percent_chance_to_block_discard

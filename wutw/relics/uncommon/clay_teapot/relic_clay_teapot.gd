@tool
class_name Relic_ClayTeapot
extends Relic

@export var aspect: AspectType
@export var hand_size_increase: int = 2

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.stage_started.connect(_on_stage_started)
	_run.signals.ability_started.connect(_on_ability_started)

func on_removed() -> void:
	_run.signals.stage_started.disconnect(_on_stage_started)
	_run.signals.ability_started.disconnect(_on_ability_started)
	super.on_removed()

func _on_stage_started() -> void:
	_state = State.ACTIVE

func _on_ability_started(card: Card, ability: CardAbility) -> void:
	if _state == State.PASSIVE:
		return
	if ability is CardAbility_Reserve and aspect in card.card_type.aspects:
		_run.get_current_stage().add_modifier(RunVars.Var.HAND_SIZE, hand_size_increase)
		_state = State.PASSIVE
		triggered.emit()
		await _brief_wait()

func get_description() -> String:
	return tr(default_description) % [aspect.get_term_tag(), hand_size_increase]

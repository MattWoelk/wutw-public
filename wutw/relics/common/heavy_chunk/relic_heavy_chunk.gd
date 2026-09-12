@tool
class_name Relic_HeavyChunk
extends Relic

@export var aspect_type: AspectType
@export var bonus_type: BonusType
@export var amount_lost: int = 10

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.stage_started.connect(_on_stage_started)
	_run.signals.card_cast_finished.connect(_on_card_cast_finished)

func on_removed() -> void:
	_run.signals.stage_started.disconnect(_on_stage_started)
	_run.signals.card_cast_finished.disconnect(_on_card_cast_finished)
	super.on_removed()

func _on_stage_started() -> void:
	_state = State.ACTIVE

func _on_card_cast_finished(card: Card) -> void:
	_run.run_or_queue_action(func() -> void:
		if _state == State.ACTIVE and aspect_type in card.card_type.aspects:
			triggered.emit()
			_run.gain_bonus(BonusGain.new(bonus_type, -amount_lost, self))
			for ability in card.card_type.abilities:
				await _run.get_current_stage().cast_ability(card, ability)
			_state = State.PASSIVE
	)

func get_description() -> String:
	return tr(default_description) % [aspect_type.get_term_tag(), amount_lost, bonus_type.get_term_tag()]

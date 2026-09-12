@tool
class_name Relic_EmptyBox
extends Relic

@export var granted_card: CardType

var _achieved_goals: Array[BonusType]

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.foray_started.connect(_on_stage_started)
	_run.signals.bonus_gained.connect(_on_bonus_gained)
	if _run.get_current_stage() and _run.get_current_stage().mode == Stage.Mode.REGULAR:
		_state = State.ACTIVE

func on_removed() -> void:
	_run.signals.foray_started.disconnect(_on_stage_started)
	super.on_removed()

func _on_stage_started() -> void:
	_achieved_goals.clear()
	_state = State.ACTIVE

func _on_bonus_gained(bonus_type: BonusType, _amount: int, _reason: BonusGain.Reason) -> void:
	if bonus_type in _achieved_goals:
		return
	var stage := _run.get_current_stage()
	if not stage:
		return  # E.g. shops.
	var goal := stage.get_goal()
	if not goal:
		return  # Harmonization
	var required := goal.bonus_requirements.get(bonus_type, 0) as int
	if required:
		if stage.get_stage_bonus_amounts().get_amount(bonus_type) >= required:
			_achieved_goals.append(bonus_type)
			stage.get_card_deck().add_card_to_hand(granted_card, CardDeck.CardDrawReason.RELIC)
			triggered.emit()
			if not goal.get_remaining_requirements(stage.get_stage_bonus_amounts()):
				_state = State.PASSIVE

func get_description() -> String:
	return tr(default_description) % granted_card.get_term_tag()

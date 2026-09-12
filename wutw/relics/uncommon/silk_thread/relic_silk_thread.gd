@tool
class_name Relic_SilkThread
extends Relic

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.pre_inspiration_gained.connect(_on_pre_inspiration_gained)
	_run.signals.stage_started.connect(_on_stage_started)

func on_removed() -> void:
	_run.signals.pre_inspiration_gained.disconnect(_on_pre_inspiration_gained)
	_run.signals.stage_started.disconnect(_on_stage_started)
	super.on_removed()

func _on_stage_started() -> void:
	_state = State.ACTIVE

func _on_pre_inspiration_gained(amount: int, _reason: Run.InspirationChangeReason) -> void:
	if _state != State.ACTIVE:
		return
	if amount <= 0:
		return
	var stage := _run.get_current_stage()
	if not stage:
		return
	if _run.get_var(RunVars.Var.CURRENT_INSPIRATION) >= _run.get_var(RunVars.Var.MAX_INSPIRATION):
		return

	_run.run_or_queue_action(func() -> void:
		triggered.emit()
		var deck := stage.get_card_deck()
		await deck.draw(CardDeck.CardDrawReason.RELIC, true)
		_state = State.PASSIVE
	)

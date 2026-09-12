@tool
class_name Relic_WisdomBell
extends Relic

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.inspiration_lost.connect(_on_inspiration_lost)

func on_removed() -> void:
	_run.signals.inspiration_lost.disconnect(_on_inspiration_lost)
	super.on_removed()

func _on_inspiration_lost(amount: int, _reason: Run.InspirationChangeReason) -> void:
	_run.run_or_queue_action(func() -> void:
		var stage := _run.get_current_stage()
		if not stage:
			return
		var remaining_reqs := stage.get_remaining_requirements()
		var bonus_type: BonusType = _run.get_card_deck_random().pick(remaining_reqs.keys())
		if bonus_type:
			triggered.emit()
			var clamped_points := mini(amount * 2, remaining_reqs.get(bonus_type, 0) as int)
			Utils.ensure(clamped_points > 0)
			_run.gain_bonus(BonusGain.new(bonus_type, clamped_points, self))
			await _brief_wait()
	)

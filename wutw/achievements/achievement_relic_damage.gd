class_name Achievement_RelicDamage
extends Achievement_RunBase

func on_run_entered(run: Run) -> void:
	run.signals.inspiration_lost.connect(_on_inspiration_lost)

func on_run_exited(run: Run) -> void:
	run.signals.inspiration_lost.disconnect(_on_inspiration_lost)

func _on_inspiration_lost(amount: int, reason: Run.InspirationChangeReason) -> void:
	if reason != Run.InspirationChangeReason.RELIC:
		return
	var existing := GlobalAchievements.get_stat(stat_id)
	stat_changed.emit(existing + amount)
	# Achievement unlocked automatically based on stat range.
	# HACK: This is exploitable by reloading, but if you wanna cheat, I don't care.

func check_in_run(_run: Run) -> void:
	return  # Accumulated naturally.

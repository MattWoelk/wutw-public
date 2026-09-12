class_name Achievement_RunVar
extends Achievement_RunBase

@export var run_var: RunVars.Var

func on_run_entered(run: Run) -> void:
	run.get_vars().modified.connect(_on_var_updated)
	check_in_run(run)

func on_run_exited(run: Run) -> void:
	run.get_vars().modified.disconnect(_on_var_updated)

func _on_var_updated(type: RunVars.Var, _old: int, _new: int) -> void:
	if type == run_var:
		check_in_run(Utils.get_active_run())

func check_in_run(run: Run) -> void:
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(run.get_var(run_var))
	# Achievement unlocked automatically based on stat range.

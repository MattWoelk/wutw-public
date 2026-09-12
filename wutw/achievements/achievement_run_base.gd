@abstract
class_name Achievement_RunBase
extends Achievement

@abstract func on_run_entered(run: Run) -> void
@abstract func on_run_exited(run: Run) -> void
@abstract func check_in_run(run: Run) -> void

func start_listening() -> void:
	GlobalSaveGame.run_entered.connect(on_run_entered)
	GlobalSaveGame.run_exited.connect(on_run_exited)
	var run := Utils.get_active_run()
	if run:
		on_run_entered(run)

func stop_listening() -> void:
	GlobalSaveGame.run_entered.disconnect(on_run_entered)
	GlobalSaveGame.run_exited.disconnect(on_run_exited)

func check() -> void:
	var run := Utils.get_active_run()
	if not run:
		return
	check_in_run(run)

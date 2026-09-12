class_name Tutorial_ArtCredits
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().signals.event_started.connect(_on_event_started)

func stop_listening() -> void:
	Utils.get_active_run().signals.event_started.disconnect(_on_event_started)

func _on_event_started(event: Event) -> void:
	if not event.steps:
		return
	if event.steps[0].background_credit is not ArtPiece_Single:
		return
	var credit := event.steps[0].background_credit
	if not credit.blurb:
		return
	if GlobalSaveGame.get_total_playtime() < 2 * 60 * 60 and not Utils.is_dev():
		return  # Don't bother the player until we know they're invested.
	ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()
	# Wait for animation.
	await run.get_tree().create_timer(1.0).timeout

	var text := tr('''
These icons indicate usages of historical artwork.

%s on one to open the Art Viewer, which contains uncropped, high-resolution versions of the art, \
as well as relevant historical details.
''').strip_edges() % InputPrompts.get_input_markup(InputPrompts.InputType.LEFT_CLICK)

	var step_scene := run.get_current_event_scene().get_current_step_scene()
	var credits := step_scene.get_node('%CreditsIcon') as CreditsIcon
	var credits_icon := credits.get_node('%Icon') as Control
	_outline_controls([credits_icon])
	_show_tooltip(credits_icon, text, [Tooltip.RelativeDirection.ABOVE])

func get_skip_id() -> String:
	return 'art_credits'

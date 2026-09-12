class_name EventOutcomeWidget_AddRelic
extends EventOutcomeWidget

var relic: Relic

func _ready() -> void:
	assert(relic)
	var run := Utils.get_active_run()
	run.add_relic(relic)

	(%RelicChoice as RelicChoice).relic = relic
	# HACK: Survey UI is not as wide.
	if Utils.get_active_run().get_state() == RunData.State.SURVEY:
		(%RelicChoice as RelicChoice).min_text_width = 250
		(%RelicChoice as RelicChoice).max_text_width = 250

	var tween := create_tween()
	(%Label as Control).modulate.a = 0
	(%RelicChoice as RelicChoice).modulate.a = 0
	tween.tween_property(%Label, 'modulate:a', 1.0, Utils.anim_duration(0.4))
	tween.tween_property(%RelicChoice, 'modulate:a', 1.0, Utils.anim_duration(0.4))
	tween.play()
	await tween.finished

	finished.emit()

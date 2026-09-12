class_name EventOutcomeWidget_RemoveRelic
extends EventOutcomeWidget

var is_random: bool = false
var relic: Relic

func _ready() -> void:
	var run := Utils.get_active_run()
	if not Utils.ensure(is_random or relic):
		visible = false
		finished.emit()
		return
	var removed_relic: Relic = run.get_events_random().pick(run.get_current_relics()) if is_random else relic
	if not removed_relic:
		visible = false
		finished.emit()
		return

	run.remove_relic(removed_relic)

	(%RelicChoice as RelicChoice).relic = removed_relic

	var tween := create_tween()
	modulate.a = 0
	var tear_material := (%TornRelic as Control).material as ShaderMaterial
	tear_material.set_shader_parameter('progress', 0)
	tween.tween_property(self, 'modulate:a', 1.0, Utils.anim_duration(0.5))
	tween.tween_method(func(value: float) -> void:
		tear_material.set_shader_parameter('progress', value)
	, 0.0, 1.0, Utils.anim_duration(1.0))
	tween.play()
	await tween.finished

	finished.emit()

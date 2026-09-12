@tool
class_name PracticeInsightsScore
extends UkiyoePanelContainer

const ANIMATION_DURATION := 0.8

@export_multiline var tooltip: String

var score: float = 0:
	set(value):
		score = value
		if is_node_ready():
			_update()

func _ready() -> void:
	super._ready()
	_update(false)
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.BELOW], [Tooltip.Alignment.END])

func _update(animate: bool = true) -> void:
	assert(score >= 0)
	var granted := floori(score)
	var leftover := score - floorf(score)
	var label := %ExcessLabel as Label
	var icon := %ExcessIcon as Control
	var icon_material := icon.material as ShaderMaterial
	var new_text := str(granted)
	if animate:
		var tween := create_tween()
		var cur_progress := icon_material.get_shader_parameter('progress') as float
		var new_progress := leftover
		var update_progress := func(p: float) -> void: icon_material.set_shader_parameter('progress', p)
		if label.text != new_text:
			if label.text.to_int() < granted:
				# Animate to end.
				tween.tween_method(update_progress, cur_progress, 1.0, (1.0 - cur_progress))
				cur_progress = 0
				tween.tween_callback(update_progress.bind(0))
			else:
				# Animate to start.
				tween.tween_method(update_progress, cur_progress, 0.0, cur_progress)
				cur_progress = 1
				tween.tween_callback(update_progress.bind(1))
			tween.tween_property(label, 'scale', Vector2(1.2, 1.2), 0.2)
			tween.tween_callback(func() -> void: label.text = new_text)
			tween.tween_property(label, 'scale', Vector2(1, 1), 0.4)
		tween.tween_method(update_progress, cur_progress, new_progress, absf(new_progress - cur_progress))
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.set_ease(Tween.EASE_IN)
		tween.set_speed_scale(Utils.anim_speed())
		tween.play()
	else:
		label.text = new_text
		icon_material.set_shader_parameter('progress', leftover)

func _make_tooltip_text() -> String:
	return tr(tooltip)

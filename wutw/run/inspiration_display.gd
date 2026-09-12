@tool
class_name InspirationDisplay
extends UkiyoePanelContainer

enum ChangeType { SET, INCREASE, REDUCE, MAX_INCREASE, MAX_REDUCE }

var _current_tween: Tween

func _ready() -> void:
	super._ready()
	if Utils.is_in_editor():
		return

	await get_tree().process_frame  # Make sure the run is ready.

	var run := Utils.get_active_run()
	run.get_vars().modified.connect(_on_var_updated)

	_update_damage_estimate()
	run.state_changed.connect(_update_damage_estimate)
	@warning_ignore_start('untyped_declaration')
	run.signals.bonus_gained.connect(_update_damage_estimate.unbind(3))
	run.signals.bonus_lost.connect(_update_damage_estimate.unbind(3))
	run.signals.harmonization_recipe_activated.connect(_update_damage_estimate.unbind(1))
	@warning_ignore_restore('untyped_declaration')

	_update(ChangeType.SET, 0)

	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.BELOW], [Tooltip.Alignment.BEGIN])

func _enter_tree() -> void:
	UI.register_zoomable(self, 0, 0)

func _on_var_updated(type: RunVars.Var, _old: int, _new: int) -> void:
	var duration := 0.1 * absf(_new - _old)
	if type == RunVars.Var.CURRENT_INSPIRATION:
		if _new > _old:
			_update(ChangeType.INCREASE, duration)
		elif _new < _old:
			_update(ChangeType.REDUCE, duration)
	elif type == RunVars.Var.MAX_INSPIRATION:
		if _new > _old:
			_update(ChangeType.MAX_INCREASE, duration)
		elif _new < _old:
			_update(ChangeType.MAX_REDUCE, duration)

func _update(change_type: ChangeType, duration: float) -> void:
	var run := Utils.get_active_run()
	var current_value := run.get_var(RunVars.Var.CURRENT_INSPIRATION)
	var max_value := run.get_var(RunVars.Var.MAX_INSPIRATION)

	var anim_color: Color
	match change_type:
		ChangeType.SET:
			anim_color = Color(1, 1, 1, 1)
		ChangeType.INCREASE:
			anim_color = Color(0, 1.5, 0, 1)
		ChangeType.REDUCE:
			anim_color = Color(1.5, 0, 0, 1)
		ChangeType.MAX_INCREASE:
			anim_color = Color(0, 0, 1.5, 1)
		ChangeType.MAX_REDUCE:
			anim_color = Color(1.5, 0, 1.5, 1)

	if _current_tween:
		_current_tween.kill()  # Not ideal, but makes sure we end up at the right final number.
	_current_tween = create_tween()
	(%ProgressBar as UkiyoeProgressBar).self_modulate = anim_color
	_current_tween.tween_property(%ProgressBar, 'value', current_value, duration)
	_current_tween.parallel()
	_current_tween.tween_property(%ProgressBar, 'max_value', max_value, duration)
	_current_tween.tween_property(%ProgressBar, 'self_modulate', Color(1, 1, 1, 1), 0)
	_current_tween.set_trans(Tween.TRANS_LINEAR)
	_current_tween.set_ease(Tween.EASE_OUT)
	_current_tween.set_speed_scale(Utils.anim_speed())
	_current_tween.play()

func _update_damage_estimate() -> void:
	(%ProgressBar as UkiyoeProgressBar).damage_value = _get_damage_estimate()

func _get_damage_estimate() -> float:
	var run := Utils.get_active_run()
	var damage_estimate := 0
	if run.get_state() == RunData.State.STAGE:
		var stage := run.get_current_stage()
		var remaining_requirements := stage.get_remaining_requirements()
		for req in remaining_requirements:
			damage_estimate += remaining_requirements[req]
		var loss_per_negative := maxi(0, run.get_var(RunVars.Var.INSPIRATION_LOST_PER_NEGATIVE_BONUS))
		for bonus_type in BonusType.get_all_types():
			if run.get_bonus_amounts().get_amount(bonus_type) < 0:
				damage_estimate += loss_per_negative
	elif run.get_state() == RunData.State.HARMONIZATION:
		for map_object in run.get_map().get_map_objects():
			if map_object is Settlement:
				var num_lacks := (map_object as Settlement).get_unsatisfied_lacks().size()
				damage_estimate += run.get_var(RunVars.Var.INSPIRATION_LOSS_PER_LACK) * num_lacks
	return damage_estimate

func _make_tooltip_text() -> String:
	var term := load('res://glossary/terms/standalone/term_inspiration.tres') as Term
	var text := ('<header_font_size>[b]%s[/b][/font_size]\n\n%s' %
			[term.get_term_name(true), term.get_markedup_description()])

	var damage_estimate := _get_damage_estimate()
	if damage_estimate:
		var run := Utils.get_active_run()
		if run.get_state() == RunData.State.STAGE:
			text += '\n\n'
			var stage := run.get_current_stage()
			var requirements_unfinished := not stage.get_remaining_requirements().is_empty()
			if requirements_unfinished:
				text += tr('You have not satisfied all the <term:stage_goal>s yet.')
			var global_penalty_bonuses: Array[String]
			for bonus_type in BonusType.get_all_types():
				if run.get_bonus_amounts().get_amount(bonus_type) < 0:
					global_penalty_bonuses.append(bonus_type.get_term_tag())
			var loss_per_negative := maxi(0, run.get_var(RunVars.Var.INSPIRATION_LOST_PER_NEGATIVE_BONUS))
			if global_penalty_bonuses and loss_per_negative > 0:
				if requirements_unfinished:
					text += tr(' The shard also has a global shortage of %s, resulting in a penalty of %d.') % [
						Utils.format_conjunction(global_penalty_bonuses),
						global_penalty_bonuses.size() * loss_per_negative]
				else:
					text += tr('The shard has a global shortage of %s, resulting in a penalty of %d.') % [
						Utils.format_conjunction(global_penalty_bonuses),
						global_penalty_bonuses.size() * loss_per_negative]
			text += tr(' If you finish the <term:foray> now, you will lose [b]%d[/b] <term:inspiration>.') % damage_estimate
		elif run.get_state() == RunData.State.HARMONIZATION:
			text += '\n\n' + tr('You have not <term_lower:satisfy_lack>ed all the <term:settlement> <term:lack>s yet.')
			text += tr(' If you finish the <term:harmonization> now, you will lose [b]%d[/b] <term:inspiration>.') % damage_estimate
		else:
			Utils.ensure(false)

	return text

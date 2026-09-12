@tool
class_name StageGoalTracker
extends UkiyoePanelContainer

static var BONUS_PROGRESS_SCENE := AsyncLoadedResource.new('res://bonuses/bonus_progress.tscn')

const ANIMATION_DURATION := 0.8

var goal: StageGoal:
	set(value):
		if goal == value:
			return
		goal = value
		if is_node_ready():
			_recreate()

func _ready() -> void:
	super._ready()
	_recreate()
	var run := Utils.get_active_run()
	if not run:
		Utils.ensure(Utils.is_in_editor())
		return
	run.state_changed.connect(func() -> void:
		if run.get_state() == RunData.State.STAGE_SELECTOR and run.get_var(RunVars.Var.GOAL_REROLLS):
			(%RerollButton as Button).visible = true
		else:
			(%RerollButton as Button).visible = false
	)
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.BELOW], [Tooltip.Alignment.CENTERED])
	GlobalTooltipSystem.attach(%ExcessIcon as Control, _make_excess_tooltip_text,
			[Tooltip.RelativeDirection.BELOW], [Tooltip.Alignment.CENTERED])
	GlobalTooltipSystem.pre_tooltip_shown.connect(func(control: Control, tooltip: Tooltip) -> void:
		if control == self:
			tooltip.max_width = 1500
			tooltip.hide_expand_hint = true
			(tooltip.get_node('%MarkedUpLabel') as MarkedUpLabel).autowrap_mode = TextServer.AUTOWRAP_OFF
	)
	_on_stage_bonus_listing_visibility_changed()

func update(bonus_amounts: BonusAmounts, animate: bool = false) -> void:
	assert(goal and bonus_amounts)
	var should_play_sound := false
	for child in %GoalsBox.get_children():
		var progress := child as BonusProgress
		var new_value := bonus_amounts.get_amount(progress.bonus_type)
		if animate and new_value != progress.current_value:
			if new_value > progress.current_value:
				should_play_sound = true
			var tween := create_tween()
			tween.tween_property(progress, 'current_value', new_value, ANIMATION_DURATION)
			tween.set_trans(Tween.TRANS_LINEAR)
			tween.set_ease(Tween.EASE_IN)
			tween.set_speed_scale(Utils.anim_speed())
			tween.play()
		else:
			progress.current_value = new_value

	if should_play_sound and is_visible_in_tree():
		GlobalAudioSystem.play(AK.EVENTS.UI_GAMEPLAY_GOALYILLED_SHORT)

	var excess := goal.get_excess(bonus_amounts)
	if not Utils.ensure(excess >= 0):
		excess = 0
	if Skill.get_skill_var(Skill.Var.INSIGHTS_FROM_EXCESS):
		var run := Utils.get_active_run()
		var points_per_insight := run.get_var(RunVars.Var.EXCESS_BONUS_PER_INSIGHT)
		@warning_ignore('integer_division')
		var granted_insights := mini(run.scaling.max_insights_from_excess, excess / points_per_insight)
		var leftover_insights := excess % points_per_insight
		if granted_insights >= run.scaling.max_insights_from_excess:
			leftover_insights = 0

		var label := %ExcessLabel as Label
		var icon := %ExcessIcon as Control
		var icon_material := icon.material as ShaderMaterial
		if animate:
			var tween := create_tween()
			var new_size := Vector2.ZERO if excess == 0 else Vector2(55, 55)
			if icon.custom_minimum_size.x != new_size.x:
				tween.tween_property(icon, 'custom_minimum_size', new_size, 0.4)
			var new_text := '' if granted_insights == 0 else str(granted_insights)
			var cur_progress := icon_material.get_shader_parameter('progress') as float
			var update_progress := func(p: float) -> void: icon_material.set_shader_parameter('progress', p)
			if label.text != new_text:
				if label.text.to_int() < granted_insights:
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
			var new_progress := float(leftover_insights) / points_per_insight
			tween.tween_method(update_progress, cur_progress, new_progress, absf(new_progress - cur_progress))
			tween.set_trans(Tween.TRANS_LINEAR)
			tween.set_ease(Tween.EASE_IN)
			tween.set_speed_scale(Utils.anim_speed())
			tween.play()
		else:
			icon.custom_minimum_size = Vector2.ZERO if excess == 0 else Vector2(55, 55)
			label.text = '' if granted_insights == 0 else str(granted_insights)
			icon_material.set_shader_parameter('progress', float(leftover_insights) / points_per_insight)

func _recreate() -> void:
	var requirements: Dictionary[BonusType, int]
	if goal:
		requirements.assign(goal.bonus_requirements)

	var tween := create_tween()
	tween.tween_property(%HBoxContainer, 'modulate:a', 0.0, Utils.anim_duration(0.6))
	tween.play()
	await tween.finished

	Utils.clear_node(%GoalsBox)
	var bars: Array[BonusProgress] = []
	for req in requirements:
		var progress := BONUS_PROGRESS_SCENE.instantiate_loaded_scene() as BonusProgress
		progress.bonus_type = req
		progress.goal_value = requirements[req]
		progress.current_value = 0
		progress.custom_icon_size = Vector2(48, 48)
		progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress.size_flags_vertical = Control.SIZE_EXPAND_FILL
		progress.size_flags_stretch_ratio = progress.goal_value
		bars.append(progress)
	bars.sort_custom(func(a: BonusProgress, b: BonusProgress) -> bool: return a.goal_value > b.goal_value)
	for bar in bars:
		%GoalsBox.add_child(bar)
	(%ExcessIcon as Control).custom_minimum_size = Vector2.ZERO
	((%ExcessIcon as Control).material as ShaderMaterial).set_shader_parameter('progress', 0)
	(%ExcessLabel as Label).text = ''

	var run := Utils.get_active_run()
	if run and run.get_state() == RunData.State.STAGE_SELECTOR and run.get_var(RunVars.Var.GOAL_REROLLS):
		if run.get_var(RunVars.Var.GOAL_REROLLS) > 1:
			(%RerollButton as Button).text = tr('Reroll (%d)') % run.get_var(RunVars.Var.GOAL_REROLLS)
		else:
			(%RerollButton as Button).text = tr('Reroll')
		(%RerollButton as Button).visible = true
	else:
		(%RerollButton as Button).visible = false

	tween = create_tween()
	tween.tween_property(%HBoxContainer, 'modulate:a', 1.0, Utils.anim_duration(0.6))
	tween.play()
	await tween.finished

func _make_tooltip_text() -> String:
	var remaining: Array[Array] = []  # [bonus type, current, goal]
	for bonus_progress: BonusProgress in %GoalsBox.get_children():
		if bonus_progress.current_value < bonus_progress.goal_value:
			remaining.append([bonus_progress.bonus_type, bonus_progress.current_value, bonus_progress.goal_value])
	var goals_description: String = ''
	var run_state := Utils.get_active_run().get_state()
	var is_in_stage_end := run_state == RunData.State.STAGE_END
	if remaining:
		var total_damage := 0
		var goal_pieces: Array[String]
		for req in remaining:
			var bonus_type := req[0] as BonusType
			var remaining_amount: int = req[2] - req[1]
			goal_pieces.append('%d %s' % [remaining_amount, bonus_type.get_term_tag()])
			total_damage += remaining_amount
		if is_in_stage_end:
			goals_description += tr(('The following <term_lower:bonus> goals weren\'t fully satisfied during this <term:foray>:\n'))
			goals_description += '    '.join(goal_pieces) + '\n'
			goals_description += tr('As a result, you lost [b]%d[/b] <term:inspiration>.') % total_damage
		else:
			goals_description += ('[center]')
			goals_description += (tr('Produce these <term_lower:bonus>s to avoid losing %d <term:inspiration>\n') % total_damage)
			goals_description += '    '.join(goal_pieces)
			goals_description += ('[/center]')
	else:
		goals_description += tr('All <term:bonus> goals for this <term:foray> have been satisfied!')
		if not is_in_stage_end:
			goals_description += tr(' You can continue to develop this <term:settlement> or safely move on.')
	return goals_description.strip_edges()

func _make_excess_tooltip_text() -> String:
	var run := Utils.get_active_run()
	var run_state := run.get_state()
	var is_in_stage := run_state == RunData.State.STAGE
	var points_per_insight := run.get_var(RunVars.Var.EXCESS_BONUS_PER_INSIGHT)
	var text := ''
	var total_gained := (%ExcessLabel as Label).text.to_int()

	if is_in_stage:
		text += tr('For every %d <term_lower:bonus> points of any type that don\'t directly progress the <term_lower:stage_goal>s,') % points_per_insight
		text += tr(' you will gain one extra <term:insight> at the end of the <term_lower:foray>.')
		if total_gained > 0:
			text += '\n\n'
			text += tr_n(
				'So far you have earned [b]%d[/b] extra <term:insight> during this <term_lower:foray>.',
				'So far you have earned [b]%d[/b] extra <term:insight>s during this <term_lower:foray>.',
				total_gained) % total_gained
			if total_gained >= run.scaling.max_insights_from_excess:
				text += tr(' No more <term:insight>s can be gained this <term_lower:foray>.')
	else:
		if total_gained > 0:
			text += tr_n(
				'You have gained [b]%d[/b] extra <term:insight> from <term_lower:bonus>s that didn\'t directly progress the <term_lower:stage_goal>s,',
				'You have gained [b]%d[/b] extra <term:insight>s from <term_lower:bonus>s that didn\'t directly progress the <term_lower:stage_goal>s,',
				total_gained) % total_gained
			text += tr(' one for every %d points of excess <term_lower:bonus>s.') % points_per_insight
		else:
			text += tr('For every %d points of <term_lower:bonus>s that didn\'t directly progress the <term_lower:stage_goal>s,') % points_per_insight
			text += tr(' you can gain one extra <term:insight>.')
			text += '\n\n'
			text += tr('You did not reach enough excess <term_lower:bonus>s this <term_lower:foray>.')
	return text

func _on_reroll_button_pressed() -> void:
	var run := Utils.get_active_run()
	run.reroll_stage_goal()
	goal = run.get_current_stage_goal()
	(%RerollButton as Button).disabled = true
	await _recreate()
	(%RerollButton as Button).disabled = false

func _on_stage_bonus_listing_visibility_changed() -> void:
	for progress: BonusProgress in %GoalsBox.get_children():
		progress.custom_icon_size = Vector2(32, 32) if (%StageBonusListing as Control).visible else Vector2(48, 48)

class_name StageEnd
extends Node2D

signal finished

static var RELIC_ICON_SCENE := AsyncLoadedResource.new('res://relics/selector/relic_icon.tscn')

var settlement_state: SettlementState

func _ready() -> void:
	if not Utils.ensure(settlement_state.bonus_amounts != null):
		settlement_state.bonus_amounts = BonusAmounts.new()

	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)

	var run := Utils.get_active_run()

	# Show name.
	(%NamingLabel as MarkedUpLabel).set_markedup_text(
		settlement_state.settlement_name.get_markedup_name_explanation(), MarkedUpLabel.LinkMode.LINK)

	# Show bonuses and specialization / lack stats.
	var sorted_bonus_types := settlement_state.get_sorted_bonus_types()
	var show_lacks := Skill.get_skill_var(Skill.Var.CAPITAL_UNLOCKED) > 0
	var show_double_lacks := run.get_current_season_index() >= run.scaling.first_season_with_double_lacks
	var show_specialization := Skill.get_skill_var(Skill.Var.CAPITAL_CONNECTION) > 0
	for bonus_counter: BonusCounter in %BonusesList.get_children():
		bonus_counter.current_value = settlement_state.bonus_amounts.get_amount(bonus_counter.bonus_type)
		if show_specialization and bonus_counter.bonus_type == sorted_bonus_types[0]:
			bonus_counter.highlight_type = Bonus.HighlightType.POSITIVE
		elif show_lacks and bonus_counter.bonus_type == sorted_bonus_types[-1]:
			bonus_counter.highlight_type = Bonus.HighlightType.NEGATIVE
		elif show_double_lacks and bonus_counter.bonus_type == sorted_bonus_types[-2]:
			bonus_counter.highlight_type = Bonus.HighlightType.NEGATIVE
		else:
			bonus_counter.highlight_type = Bonus.HighlightType.NONE
	(%YieldBonus as Bonus).bonus_type = sorted_bonus_types[0]
	(%LackBonus1 as Bonus).bonus_type = sorted_bonus_types[-1]
	(%LackBonus2 as Bonus).bonus_type = sorted_bonus_types[-2]
	(%LackBonus2 as Bonus).visible = show_double_lacks
	(%YieldBox as Control).visible = show_specialization
	(%LackBox as Control).visible = show_lacks

	# Subtract inspiration.
	var inspiration_lost := 0
	var inspiration_loss_explanation := '[ul]'
	var remaining_requirements := settlement_state.goal.get_remaining_requirements(settlement_state.bonus_amounts)
	for req in remaining_requirements:
		inspiration_lost += remaining_requirements[req]
		inspiration_loss_explanation += tr('[b]Foray %s goal: -%d[/b]\n') % [req.get_term_tag(), remaining_requirements[req]]

	var penalty := maxi(0, run.get_var(RunVars.Var.INSPIRATION_LOST_PER_NEGATIVE_BONUS))
	if penalty:
		for bonus_type in BonusType.get_all_types():
			if run.get_bonus_amounts().get_amount(bonus_type) < 0:
				inspiration_lost += penalty
				inspiration_loss_explanation += tr('[b]Global %s shortage: -%d[/b]\n') % [bonus_type.get_term_tag(), penalty]
	inspiration_loss_explanation += '[/ul]'

	# Need to account for relics and run vars that affect inspiration loss.
	var starting_inspiration := run.get_vars().get_current_value(RunVars.Var.CURRENT_INSPIRATION)
	run.modify_inspiration(-inspiration_lost, Run.InspirationChangeReason.STAGE_GOAL)
	var ending_inspiration := run.get_vars().get_current_value(RunVars.Var.CURRENT_INSPIRATION)
	var actual_inspiration_lost := starting_inspiration - ending_inspiration  # Damage value, so positive!
	(%InspirationPenaltyLabel as Label).text = '%d' % actual_inspiration_lost
	(%InspirationBox as Control).visible = actual_inspiration_lost > 0
	(%InspirationExhaustedLabel as Control).visible = ending_inspiration <= 0
	if ending_inspiration > 0:  # No immortality!
		run.modify_inspiration(run.get_var(RunVars.Var.HEAL_PER_STAGE), Run.InspirationChangeReason.PASSIVE)

	# Grant insights.
	var insights_gained := run.scaling.get_rewarded_insights_for_stage(run.get_current_stage_index())
	(%InsightsCountLabel as Label).text = '%+d' % insights_gained
	if Skill.get_skill_var(Skill.Var.INSIGHTS_FROM_EXCESS):
		var excess := settlement_state.goal.get_excess(settlement_state.bonus_amounts)
		var points_per_insight := Utils.get_active_run().get_var(RunVars.Var.EXCESS_BONUS_PER_INSIGHT)
		@warning_ignore('integer_division')  # intentional
		var insights_from_excess := mini(run.scaling.max_insights_from_excess, excess / points_per_insight)
		if insights_from_excess:
			(%ExtraInsightsBox as Control).visible = true
			(%ExtraInsightsCountLabel as Label).text = '%+d' % insights_from_excess
		else:
			(%ExtraInsightsBox as Control).visible = false
		insights_gained += insights_from_excess
	else:
		(%ExtraInsightsBox as Control).visible = false
	run.grant_insights(insights_gained)

	# Show gained relics.
	if run.get_relics_gained_this_stage():
		(%RelicsBox as Control).visible = true
		Utils.clear_node(%RelicsList)
		for relic in run.get_relics_gained_this_stage():
			var relic_icon: RelicIcon = RELIC_ICON_SCENE.instantiate_loaded_scene()
			relic_icon.relic = relic
			relic_icon.forced_size = 80
			%RelicsList.add_child(relic_icon)
	else:
		(%RelicsBox as Control).visible = false

	# React to continue button.
	(%ContinueButton as Button).pressed.connect(finished.emit)

	_setup_tooltip(%YieldBox as Control, load('res://glossary/terms/standalone/term_stage_specialization.tres') as Term,
				   tr('This is based on which <term_lower:bonus> was gained the most during the ' +
					  '<term_lower:foray>.'))
	_setup_tooltip(%LackBox as Control, load('res://glossary/terms/standalone/term_lack.tres') as Term,
				   tr('This is based on which <term_lower:bonus> was gained the least during the ' +
					  '<term_lower:foray>, with ties broken based on potential <term_lower:bonus>s ' +
					  'from inactive <term_lower:spot_upgrade>s.'))
	_setup_tooltip(%InsightsBox as Control, load('res://glossary/terms/standalone/term_insight.tres') as Term,
				   tr('[b]These insights were gained from finishing the foray. More insights are granted later in the <term_lower:run>.[/b]'))
	_setup_tooltip(%ExtraInsightsBox as Control, load('res://glossary/terms/standalone/term_insight.tres') as Term,
				   tr('[b]These insights were gained from excess <term_lower:bonus>s using the Insights from Excess skill.[/b]'))
	_setup_tooltip(%InspirationBox as Control, load('res://glossary/terms/standalone/term_inspiration.tres') as Term,
				   inspiration_loss_explanation.strip_edges())

	# HACK: Eliminate initial resize flicker.
	(%ScrollPanel as ScrollPanel).modulate.a = 0
	await get_tree().process_frame

	(%ScrollPanel as ScrollPanel).animate_unroll()

func _update_font_size() -> void:
	Utils._scale_font_size(%NamingLabel as RichTextLabel, false, 16)
	var font_size := roundi(16 * GameSettings.Interface.paragraph_font_scale.value())
	(%YieldLabel as Label).add_theme_font_size_override('font_size', font_size)
	(%LackLabel as Label).add_theme_font_size_override('font_size', font_size)
	(%InspirationHintLabel as Label).add_theme_font_size_override('font_size', font_size)
	(%InsightsLabel as Label).add_theme_font_size_override('font_size', font_size)
	(%ExtraInsightsLabel as Label).add_theme_font_size_override('font_size', font_size)

func close() -> void:
	Utils.set_input_enabled(%ScrollPanel as ScrollPanel, false)
	(%BG as FadedBackground).fade_out()
	await (%ScrollPanel as ScrollPanel).animate_roll()
	queue_free()

func _setup_tooltip(node: Control, term: Term, extra: String = '') -> void:
	var make_tooltip_text := func() -> String:
		var text := ('<header_font_size>[b]%s[/b][/font_size]\n\n%s' %
					[term.get_term_name(true), term.get_markedup_description()])
		if extra:
			text += '\n\n' + extra
		return text
	GlobalTooltipSystem.attach(node, make_tooltip_text,
			[Tooltip.RelativeDirection.RIGHT], [Tooltip.Alignment.BEGIN, Tooltip.Alignment.CENTERED])

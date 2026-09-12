class_name SeasonEnd
extends Node2D

signal finished
signal salvage_opened(salvage: Salvage)

static var RELIC_SELECTOR_SCENE := AsyncLoadedResource.new('res://relics/selector/relic_selector.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var SALVAGE_SCENE := AsyncLoadedResource.new('res://cards/salvage/salvage.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

func _ready() -> void:
	var run := Utils.get_active_run()
	var insights_gained := run.scaling.get_rewarded_insights_for_harmonization(
		run.get_current_season_index())
	(%InsightsCountLabel as Label).text = '%+d' % insights_gained
	run.grant_insights(insights_gained)

	if Skill.get_skill_var(Skill.Var.SHOP_TRADE):
		GlobalSaveGame.mark_shop_seen(load('res://shops/trade/shop_trade.tres') as ShopType)

	(%RelicButton as Button).disabled = false
	(%SalvageButton as Button).disabled = true
	(%SalvageButton as Button).visible = Skill.get_skill_var(Skill.Var.INSCRIBE_COMMON) > 0
	(%ContinueButton as Button).disabled = true

	GlobalTooltipSystem.attach(%InsightsBox as Control, _make_tooltip_text,
			[Tooltip.RelativeDirection.BELOW], [Tooltip.Alignment.CENTERED])

	(%ScrollPanel as ScrollPanel).animate_unroll()

func _on_relic_button_pressed() -> void:
	var run := Utils.get_active_run()
	var relic_selector := RELIC_SELECTOR_SCENE.instantiate_loaded_scene() as RelicSelector
	relic_selector.relic_reward_pool = run.scaling.season_relic_reward_pool
	relic_selector.manual_select = false
	relic_selector.finished.connect(func() -> void:
		(%RelicButton as Button).disabled = true
		if Skill.get_skill_var(Skill.Var.INSCRIBE_COMMON):
			(%SalvageButton as Button).disabled = false
		else:
			(%ContinueButton as Button).disabled = false
	)
	add_child(relic_selector)

func _on_salvage_button_pressed() -> void:
	var salvage := SALVAGE_SCENE.instantiate_loaded_scene() as Salvage
	salvage.finished.connect(func() -> void:
		(%SalvageButton as Button).disabled = true
		(%ContinueButton as Button).disabled = false
	)
	add_child(salvage)
	salvage_opened.emit(salvage)

func _on_continue_button_pressed() -> void:
	Utils.set_input_enabled(%ScrollPanel as ScrollPanel, false)
	(%BG as FadedBackground).fade_out()
	await (%ScrollPanel as ScrollPanel).animate_roll()
	finished.emit()

func _make_tooltip_text() -> String:
	var term := load('res://glossary/terms/standalone/term_insight.tres') as Term
	return ('<header_font_size>[b]%s[/b][/font_size]\n\n%s' %
			[term.get_term_name(true), term.get_markedup_description()])

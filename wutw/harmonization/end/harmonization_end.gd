class_name HarmonizationEnd
extends Node2D

signal finished

static var BONUS_SCENE := AsyncLoadedResource.new('res://bonuses/bonus.tscn')
static var ENTRY_SCENE := AsyncLoadedResource.new('res://harmonization/end/harmonization_end_entry.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

func _ready() -> void:
	var run := Utils.get_active_run()

	Utils.clear_node(%CapitalYieldsList, 1)
	for bonus_type in run.get_unlocked_capital_bonuses():
		var bonus := BONUS_SCENE.instantiate_loaded_scene() as Bonus
		bonus.bonus_type = bonus_type
		bonus.custom_minimum_size = Vector2(32, 32)
		bonus.highlight_type = Bonus.HighlightType.POSITIVE
		%CapitalYieldsList.add_child(bonus)
	(%CapitalYieldsList as Control).visible = Skill.get_skill_var(Skill.Var.CAPITAL_CONNECTION)

	var total_damage := 0
	Utils.clear_node(%OutcomesList)
	for map_object in run.get_map().get_map_objects():
		if map_object is Settlement:
			var entry := ENTRY_SCENE.instantiate_loaded_scene() as HarmonizationEndEntry
			entry.settlement = map_object as Settlement
			%OutcomesList.add_child(entry)
			total_damage += entry.get_inspiration_damage()

	if total_damage > 0:
		var starting_inspiration := run.get_vars().get_current_value(RunVars.Var.CURRENT_INSPIRATION)
		run.modify_inspiration(-total_damage, Run.InspirationChangeReason.HARMONIZATION_GOAL)
		var ending_inspiration := run.get_vars().get_current_value(RunVars.Var.CURRENT_INSPIRATION)
		var actual_inspiration_lost := starting_inspiration - ending_inspiration  # Damage value, so positive!
		var total_damage_text := tr('Lost a total of %d <term:inspiration>') % actual_inspiration_lost
		if actual_inspiration_lost < total_damage:
			total_damage_text += tr(' (protected from %d)') % (total_damage - actual_inspiration_lost)
		(%TotalLostLabel as MarkedUpLabel).set_markedup_text(
			'[color=800000]' + total_damage_text + tr('.') + '[/color]')
		(%TotalLostLabel as MarkedUpLabel).visible = true

		(%InspirationExhaustedLabel as Control).visible = ending_inspiration <= 0
	else:
		(%TotalLostLabel as MarkedUpLabel).visible = false

	(%ScrollPanel as ScrollPanel).animate_unroll()

func _enter_tree() -> void:
	UI.register_zoomable(%ScrollPanel as ScrollPanel)

func _on_continue_button_pressed() -> void:
	Utils.set_input_enabled(%ScrollPanel as ScrollPanel, false)
	(%BG as FadedBackground).fade_out()
	await (%ScrollPanel as ScrollPanel).animate_roll()
	finished.emit()

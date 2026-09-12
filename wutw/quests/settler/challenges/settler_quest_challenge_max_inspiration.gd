class_name SettlerQuestChallenge_MaxInspiration
extends SettlerQuestChallenge

@export var amount_decrease: int = 10

func apply_starting_modifiers(quest: Quest_Settler, run: Run) -> void:
	Utils.ensure(amount_decrease > 0)
	run.get_vars().add_modifier(RunVars.Var.MAX_INSPIRATION, -amount_decrease, _get_mod_tag(quest))

func describe() -> String:
	return tr('Reduce maximum <term_lower:inspiration> by %d.') % amount_decrease

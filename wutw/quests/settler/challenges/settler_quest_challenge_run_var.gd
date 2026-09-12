class_name SettlerQuestChallenge_RunVar
extends SettlerQuestChallenge

@export var var_type: RunVars.Var
@export var delta: int = 0
@export var description: String

func apply_starting_modifiers(quest: Quest_Settler, run: Run) -> void:
	Utils.ensure(delta != 0)
	run.get_vars().add_modifier(var_type, delta, _get_mod_tag(quest))

func describe() -> String:
	assert(description)
	return tr(description)

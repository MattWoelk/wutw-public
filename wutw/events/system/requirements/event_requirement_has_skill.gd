@tool
class_name EventRequirement_HasSkill
extends EventRequirement

@export var skill: Skill

func is_satisfied(_run: Run, _event: Event) -> bool:
	return GlobalSaveGame.has_unlocked_skill(skill)

func to_expression() -> String:
	return 'has_skill(' + skill.skill_id + ')'

func describe(_run: Run, detailed: bool) -> String:
	if detailed:
		return tr('Requires <term:skill>: ') + skill.get_term_tag()
	else:
		return skill.get_effective_skill_name()

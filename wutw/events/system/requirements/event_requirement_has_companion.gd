@tool
class_name EventRequirement_HasCompanion
extends EventRequirement

@export var companion: Companion

func is_satisfied(_run: Run, _event: Event) -> bool:
	return GlobalSaveGame.has_unlocked_companion(companion)

func to_expression() -> String:
	return 'has_companion(' + companion.companion_id + ')'

func describe(_run: Run, detailed: bool) -> String:
	if detailed:
		return tr('Requires <term:companion>: ') + companion.get_term_tag()
	else:
		return tr(companion.companion_name)

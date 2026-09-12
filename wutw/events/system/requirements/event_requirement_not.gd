@tool
class_name EventRequirement_Not
extends EventRequirement

@export var negated_requirement: EventRequirement

func is_satisfied(run: Run, event: Event) -> bool:
	return not negated_requirement.is_satisfied(run, event)

func to_expression() -> String:
	return 'not(' + negated_requirement.to_expression() + ')'

func describe(run: Run, detailed: bool) -> String:
	push_warning('Event choice has negated requirement; should use a custom description.')
	return tr('Not ') + negated_requirement.describe(run, detailed)

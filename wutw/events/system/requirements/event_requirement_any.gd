@tool
class_name EventRequirement_Any
extends EventRequirement

@export var any_requirements: Array[EventRequirement]

func is_satisfied(run: Run, event: Event) -> bool:
	if not Utils.ensure(not any_requirements.is_empty()):
		return true
	for req in any_requirements:
		if req.is_satisfied(run, event):
			return true
	return false

func to_expression() -> String:
	var result := 'any('
	var first := true
	for req in any_requirements:
		if first:
			first = false
		else:
			result += ', '
		result += req.to_expression()
	result += ')'
	return result

func describe(run: Run, detailed: bool) -> String:
	var texts: Array[String]
	for req in any_requirements:
		texts.append(req.describe(run, detailed))
	if detailed:
		return tr('One of these must be satisfied:\n- ') + tr('\n- ').join(texts)
	else:
		return tr(' OR ').join(texts)

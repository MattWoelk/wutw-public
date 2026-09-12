@tool
class_name EventRequirement_All
extends EventRequirement

@export var all_requirements: Array[EventRequirement]

func is_satisfied(run: Run, event: Event) -> bool:
	if not Utils.ensure(not all_requirements.is_empty()):
		return true
	for req in all_requirements:
		if not req.is_satisfied(run, event):
			return false
	return true

func to_expression() -> String:
	var result := 'all('
	var first := true
	for req in all_requirements:
		if first:
			first = false
		else:
			result += ', '
		result += req.to_expression()
	result += ')'
	return result

func describe(run: Run, detailed: bool) -> String:
	var texts: Array[String]
	for req in all_requirements:
		texts.append(req.describe(run, detailed))
	return tr(', ').join(texts)

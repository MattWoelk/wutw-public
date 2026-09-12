@tool
class_name EventRequirement
extends Resource

@warning_ignore('unused_parameter')
func is_satisfied(run: Run, event: Event) -> bool:
	Utils.ensure(false, 'Subclass must implement is_satisfied().')
	return false

func to_expression() -> String:
	Utils.ensure(false, 'Subclass must implement to_expression().')
	return ''

@warning_ignore('unused_parameter')
func describe(run: Run, detailed: bool) -> String:
	Utils.ensure(false, 'Subclass must implement describe().')
	return ''

@tool
class_name StandaloneTerm
extends Term

@export var term_id: String
@export var term_name: String
@export var long_term_name: String
@export_multiline var markedup_description: String
@export var priority: int = 0

func get_term_id() -> String:
	return term_id

func get_term_name(long: bool) -> String:
	if long and long_term_name:
		return tr(long_term_name)
	else:
		return tr(term_name)

func get_markedup_description() -> String:
	return tr(markedup_description)

func get_term_priority() -> int:
	return priority

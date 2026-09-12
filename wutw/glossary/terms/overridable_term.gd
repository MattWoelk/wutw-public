@tool
class_name OverridableTerm
extends StandaloneTerm

@export var realistic_term_name: String
@export var realistic_long_term_name: String
@export_multiline var realistic_markedup_description: String

func get_term_name(long: bool) -> String:
	if not Utils.is_in_editor() and Utils.is_realistic_era():
		if long and realistic_long_term_name:
			return tr(realistic_long_term_name)
		else:
			return tr(realistic_term_name)
	else:
		return super.get_term_name(long)

func get_markedup_description() -> String:
	if not Utils.is_in_editor() and Utils.is_realistic_era() and realistic_markedup_description:
		return tr(realistic_markedup_description)
	else:
		return super.get_markedup_description()

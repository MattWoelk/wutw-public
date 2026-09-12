@tool
class_name EventRequirement_HasRelic
extends EventRequirement

@export var relic: Relic

func is_satisfied(run: Run, _event: Event) -> bool:
	return run.find_owned_relic(relic.relic_id) != null

func to_expression() -> String:
	return 'has_relic(' + relic.relic_id + ')'

func describe(_run: Run, detailed: bool) -> String:
	if detailed:
		return tr('Requires <term:relic>: ') + relic.get_term_tag()
	else:
		return relic.get_term_tag()

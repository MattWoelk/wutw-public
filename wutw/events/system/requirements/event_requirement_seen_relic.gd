@tool
class_name EventRequirement_SeenRelic
extends EventRequirement

@export var relic: Relic

func is_satisfied(_run: Run, _event: Event) -> bool:
	return Utils.is_in_editor() or GlobalSaveGame.has_seen_relic(relic)

func to_expression() -> String:
	return 'seen_relic(' + relic.relic_id + ')'

func describe(_run: Run, detailed: bool) -> String:
	if detailed:
		return tr('Seen <term:relic>: ') + relic.get_term_tag()
	else:
		return relic.get_term_tag()

@tool
class_name EventRequirementParser
extends RefCounted

var expression: String
var index: int = 0

static func parse(input_expression: String) -> EventRequirement:
	var parser := EventRequirementParser.new()
	parser.expression = input_expression.to_lower()
	var result := parser._parse()
	if result and not input_expression.substr(parser.index).strip_edges():
		return result
	else:
		return parser._error()

func _parse() -> EventRequirement:
	# This could be cleaned up, but it's just a dev tool, already heavily tested, and easy to folow.
	if _try('(?:all|and)\\s*\\('):
		var subreqs := _parse_list()
		if not subreqs:
			return _error()
		var result := EventRequirement_All.new()
		result.all_requirements = subreqs
		if not _try('\\)'):
			return _error()
		return result
	elif _try('(?:any|or)\\s*\\('):
		var subreqs := _parse_list()
		if not subreqs:
			return _error()
		var result := EventRequirement_Any.new()
		result.any_requirements = subreqs
		if not _try('\\)'):
			return _error()
		return result
	elif _try('not\\s*\\('):
		var subreq := _parse()
		if not subreq:
			return _error()
		var result := EventRequirement_Not.new()
		result.negated_requirement = subreq
		if not _try('\\)'):
			return _error()
		return result
	elif _try('has_card\\s*\\('):
		var start_index := index
		if not _try('\\w+'):
			return _error()
		var card_name := expression.substr(start_index, index - start_index)
		if not _try('\\)'):
			return _error()
		var result := EventRequirement_HasCard.new()
		result.card_type = CardType.get_card_type_by_name_or_symbol(card_name)
		if not result.card_type:
			return _error('invalid card name or symbol: ' + card_name)
		return result
	elif _try('has_relic\\s*\\('):
		var start_index := index
		if not _try('\\w+'):
			return _error()
		var relic_id := expression.substr(start_index, index - start_index)
		if not _try('\\)'):
			return _error()
		var result := EventRequirement_HasRelic.new()
		result.relic = Relic.get_relic_by_id(relic_id)
		if not result.relic:
			return _error('invalid relic id: ' + relic_id)
		return result
	elif _try('seen_relic\\s*\\('):
		var start_index := index
		if not _try('\\w+'):
			return _error()
		var relic_id := expression.substr(start_index, index - start_index)
		if not _try('\\)'):
			return _error()
		var result := EventRequirement_SeenRelic.new()
		result.relic = Relic.get_relic_by_id(relic_id)
		if not result.relic:
			return _error('invalid relic id: ' + relic_id)
		return result
	elif _try('has_skill\\s*\\('):
		var start_index := index
		if not _try('\\w+'):
			return _error()
		var skill_id := expression.substr(start_index, index - start_index)
		if not _try('\\)'):
			return _error()
		var result := EventRequirement_HasSkill.new()
		result.skill = Skill.get_skill_by_id(skill_id)
		if not result.skill:
			return _error('invalid skill id: ' + skill_id)
		return result
	elif _try('has_companion\\s*\\('):
		var start_index := index
		if not _try('\\w+'):
			return _error()
		var companion_id := expression.substr(start_index, index - start_index)
		if not _try('\\)'):
			return _error()
		var result := EventRequirement_HasCompanion.new()
		result.companion = Companion.get_companion_by_id(companion_id)
		if not result.companion:
			return _error('invalid companion id: ' + companion_id)
		return result
	elif _try('triggered\\s*\\('):
		var start_index := index
		if not _try('\\w+'):
			return _error()
		var event_id := expression.substr(start_index, index - start_index)
		if not _try('\\)'):
			return _error()
		var result := EventRequirement_EventTriggered.new()
		result.triggered_event = Event.get_all_events().get(event_id)
		if not result.triggered_event:
			return _error()
		return result
	elif _try('season\\s*\\('):
		var regex := RegEx.create_from_string('^\\s*(-?\\d+)\\s*(?:,\\s*(-?\\d+))?\\)')
		var regex_match := regex.search(expression.substr(index))
		if not regex_match:
			return _error()
		index += regex_match.get_end()
		var result := EventRequirement_Season.new()
		result.min_index = regex_match.get_string(1).to_int()
		result.max_index = regex_match.get_string(2).to_int() if regex_match.get_string(2) else -1
		return result
	elif _try('main_quest\\s*\\('):
		var regex := RegEx.create_from_string('^\\s*(-?\\d+)\\s*(?:,\\s*(-?\\d+))?\\)')
		var regex_match := regex.search(expression.substr(index))
		if not regex_match:
			return _error()
		index += regex_match.get_end()
		var result := EventRequirement_MainQuestProgress.new()
		result.min_progress = regex_match.get_string(1).to_int() as SaveGame.MainQuestProgress
		result.max_progress = (regex_match.get_string(2).to_int() if regex_match.get_string(2) else -1) as SaveGame.MainQuestProgress
		return result
	elif _try('(?:num_)?settlements?\\s*\\('):
		var regex := RegEx.create_from_string('^\\s*(-?\\d+)\\s*(?:,\\s*(-?\\d+))?\\)')
		var regex_match := regex.search(expression.substr(index))
		if not regex_match:
			return _error()
		index += regex_match.get_end()
		var result := EventRequirement_NumSettlements.new()
		result.min_count = regex_match.get_string(1).to_int()
		result.max_count = (regex_match.get_string(2).to_int() if regex_match.get_string(2) else -1)
		return result
	elif _try('aspects?\\s*\\('):
		var regex := RegEx.create_from_string('^\\s*(\\w+)\\s*,\\s*(-?\\d+)\\s*(?:,\\s*(-?\\d+))?\\s*(?:,\\s*(-?\\d+))?\\)')
		var regex_match := regex.search(expression.substr(index))
		if not regex_match:
			return _error()
		index += regex_match.get_end()
		var result := EventRequirement_NumAspects.new()
		var aspect_id := regex_match.get_string(1)
		if aspect_id == 'radiance':  # Convenience
			aspect_id = 'illumination'
		result.aspect_type = AspectType.get_aspect_type_by_id(regex_match.get_string(1))
		if not result.aspect_type:
			return _error('invalid aspect_type id: ' + regex_match.get_string(1))
		result.min_count = regex_match.get_string(2).to_int()
		result.max_count = regex_match.get_string(3).to_int() if regex_match.get_string(3) else -1
		result.extra_per_season = regex_match.get_string(4).to_int() if regex_match.get_string(4) else 0
		return result
	elif _try('bonus\\s*\\('):
		var regex := RegEx.create_from_string('^\\s*(\\w+)\\s*,\\s*(-?\\d+)\\s*(?:,\\s*(-?\\d+))?\\s*(?:,\\s*(-?\\d+))?\\)')
		var regex_match := regex.search(expression.substr(index))
		if not regex_match:
			return _error()
		index += regex_match.get_end()
		var result := EventRequirement_RunBonus.new()
		result.bonus_type = BonusType.get_bonus_type_by_id(regex_match.get_string(1))
		if not result.bonus_type:
			return _error('invalid bonus_type id: ' + regex_match.get_string(1))
		result.min_count = regex_match.get_string(2).to_int()
		result.max_count = regex_match.get_string(3).to_int() if regex_match.get_string(3) else -1
		result.extra_per_season = regex_match.get_string(4).to_int() if regex_match.get_string(4) else 0
		return result
	else:
		return _parse_eventvar_expression()

func _parse_list() -> Array[EventRequirement]:
	var result: Array[EventRequirement]
	var next := _parse()
	if next:
		result.append(next)
	else:
		return _error()
	while _try(','):
		next = _parse()
		if next:
			result.append(next)
		else:
			return _error()
	return result

func _try(regex_str: String) -> bool:
	var regex := RegEx.create_from_string('^\\s*' + regex_str)
	var result := regex.search(expression.substr(index))
	if result:
		index += result.get_end()
		return true
	else:
		return false

func _parse_eventvar_expression() -> EventRequirement_EventState:
	var regex := RegEx.create_from_string('^\\s*(\\$?)(\\w+[:.])?(\\w+)\\s*(=|==|!=|<|>|>=|<=)\\s*(true|false|-?\\d+|\'[^\']*\'|"[^\"]*\")')
	var regex_result := regex.search(expression.substr(index))
	if not regex_result:
		return _error()

	var result := EventRequirement_EventState.new()
	result.scope = (EventRequirement_EventState.Scope.SAVEGAME
					if regex_result.get_string(1) else
					EventRequirement_EventState.Scope.RUN)
	if regex_result.get_string(2):
		result.event_id = regex_result.get_string(2).left(-1)
	else:
		result.event_id = '<self>'
	result.var_id = regex_result.get_string(3)
	match regex_result.get_string(4):
		'=', '==': result.var_op = EventRequirement_EventState.Op.EQ
		'!=': result.var_op = EventRequirement_EventState.Op.NEQ
		'>': result.var_op = EventRequirement_EventState.Op.GT
		'>=': result.var_op = EventRequirement_EventState.Op.GTE
		'<': result.var_op = EventRequirement_EventState.Op.LT
		'<=': result.var_op = EventRequirement_EventState.Op.LTE
	var raw_value := regex_result.get_string(5)
	if raw_value in ['true', 'false']:
		result.var_type = EventsState.Type.BOOL
		result.value = raw_value
	elif raw_value == '0' or raw_value.to_int():
		result.var_type = EventsState.Type.INT
		result.value = raw_value
	else:
		assert((raw_value.begins_with('"') and raw_value.ends_with('"'))
			or (raw_value.begins_with("'") and raw_value.ends_with("'")))
		result.var_type = EventsState.Type.STRING
		result.value = raw_value.substr(1, raw_value.length() - 2)
		if result.var_op not in [EventRequirement_EventState.Op.EQ, EventRequirement_EventState.Op.NEQ]:
			return _error()
	index += regex_result.get_end()
	return result

func _error(msg: String = '') -> Variant:
	push_error('Failed to parse EventRequirement from "%s" (%s)' % [expression.substr(index), msg])
	return null

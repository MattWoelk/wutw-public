@tool
class_name EventRequirement_Season
extends EventRequirement

@export var min_index: int = -1
@export var max_index: int = -1

func is_satisfied(run: Run, _event: Event) -> bool:
	assert(min_index >= 0 or max_index >= 0)
	if min_index >= 0 and run.get_current_season_index() < min_index:
		return false
	if max_index >= 0 and run.get_current_season_index() > max_index:
		return false
	return true

func to_expression() -> String:
	return 'season(%d, %d)' % [min_index, max_index]

func describe(_run: Run, detailed: bool) -> String:
	if detailed:
		if min_index == -1:
			return tr('No later than <term:season> %d') % (max_index + 1)
		elif max_index == -1:
			return tr('No sooner than <term:season> %d') % (min_index + 1)
		else:
			return tr('Between <term:season> %d and <term:season> %d') % [min_index + 1, max_index + 1]
	else:
		if min_index == -1:
			return '<term:season> <=%d' % (max_index + 1)
		elif max_index == -1:
			return '<term:season> %d+' % (min_index + 1)
		else:
			return '<term:season> %d-%d' % [(min_index + 1), (max_index + 1)]

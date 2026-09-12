@tool
class_name EventRequirement_NumAspects
extends EventRequirement

@export var aspect_type: AspectType
@export var min_count: int = -1
@export var max_count: int = -1
@export var extra_per_season: int = 0

func is_satisfied(run: Run, _event: Event) -> bool:
	if not Utils.ensure(min_count >= 0 or max_count >= 0):
		return true  # Don't lock people out if it's out fault.
	var count := 0
	for card_type in run.get_deck_cards():
		if aspect_type in card_type.aspects:
			count += 1
	var bounds := _get_effective_bounds(run)
	if bounds[0] >= 0 and count < bounds[0]:
		return false
	if bounds[1] >= 0 and count > bounds[1]:
		return false
	return true

func to_expression() -> String:
	return 'aspects(%s, %d, %d, %d)' % [aspect_type.aspect_type_id, min_count, max_count, extra_per_season]

func describe(run: Run, detailed: bool) -> String:
	var bounds := _get_effective_bounds(run)
	if detailed:
		if bounds[0] == -1:
			return (tr('No more than %d <term_lower:glyph>(s) with %s <term_lower:aspect> in your <term_lower:card_deck>') %
					[bounds[1], aspect_type.get_term_tag()])
		elif bounds[1] == -1:
			return (tr('At least %d <term_lower:glyph>(s) with %s <term_lower:aspect> in your <term_lower:card_deck>') %
					[bounds[0], aspect_type.get_term_tag()])
		else:
			return (tr('Between %d and %d <term_lower:glyph>(s) with %s <term_lower:aspect> in your <term_lower:card_deck>') %
					[bounds[0], bounds[1], aspect_type.get_term_tag()])
	else:
		if bounds[0] == -1:
			return tr_n(
				'<%d %s Glyph',
				'<%d %s Glyphs',
				bounds[1] + 1
			) % [bounds[1] + 1, aspect_type.get_term_tag()]
		elif bounds[1] == -1:
			return tr_n(
				'%d %s Glyph',
				'%d %s Glyphs',
				bounds[0]
			) % [bounds[0], aspect_type.get_term_tag()]
		else:
			return tr('%d-%d %s Glyphs') % [bounds[0], bounds[1], aspect_type.get_term_tag()]

func _get_effective_bounds(run: Run) -> Array[int]:
	var effective_min_count := min_count
	var effective_max_count := max_count
	if run:  # Not in museum/editor.
		var season_index := run.get_current_season_index() if run else 0
		var season_factor := maxi(0, season_index * 2 - 1)
		if min_count >= 0:
			effective_min_count += extra_per_season * season_factor
			effective_min_count += run.get_var(RunVars.Var.EXTRA_EVENT_ASPECT_REQS)
		if max_count >= 0:
			effective_max_count += extra_per_season * season_factor
	return [effective_min_count, effective_max_count]

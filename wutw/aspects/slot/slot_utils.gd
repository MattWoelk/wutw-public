class_name SlotUtils
extends Object

static func match_slot(slots: Array[AspectSlot], aspect_types: Array[AspectType], force_unambiguous: bool = false) -> AspectSlot:
	var matched: AspectSlot = null
	for slot in slots:
		if slot.is_filled:
			continue

		var recipe := Utils.get_typed_ancestor(slot, Recipe) as Recipe
		if recipe and not recipe.is_available():
			continue

		if slot.can_be_filled_by(aspect_types):
			if matched:
				if force_unambiguous:
					return null
				elif matched.aspect_type == slot.aspect_type and matched.get_parent() == slot.get_parent():
					pass  # Identical slots. Doesn't matter which one we pick.
				elif slot.is_universal and not matched.is_universal:
					pass  # It is safe to always prefer non-universal slots.
				elif matched.is_universal and not slot.is_universal:
					matched = slot  #  It is safe to always prefer non-universal slots.
				else:
					return null  # Ambiguous
			else:
				matched = slot
	return matched

static func get_slot_failure_error_message(aspect_types: Array[AspectType]) -> String:
	var failed_drop_target := Utils.get_hovered_control()
	var recipe: Recipe
	var potential_matches: Array[AspectSlot]
	if failed_drop_target is AspectSlot:
		potential_matches.append(failed_drop_target)
		recipe = Utils.get_typed_ancestor(failed_drop_target, Recipe)
	elif failed_drop_target is Recipe:
		potential_matches.append_array((failed_drop_target as Recipe).get_aspect_slots())
		recipe = failed_drop_target as Recipe
	elif Utils.get_typed_ancestor(failed_drop_target, AspectSlot):
		recipe = Utils.get_typed_ancestor(failed_drop_target, Recipe)
		potential_matches.append(Utils.get_typed_ancestor(failed_drop_target, AspectSlot))
	elif Utils.get_typed_ancestor(failed_drop_target, Recipe):
		recipe = Utils.get_typed_ancestor(failed_drop_target, Recipe) as Recipe
		potential_matches.append_array(recipe.get_aspect_slots())
	elif failed_drop_target is BlanksPracticeProblem:
		potential_matches.append_array((failed_drop_target as BlanksPracticeProblem).get_aspect_slots())
		recipe = failed_drop_target as Recipe
	elif Utils.get_typed_ancestor(failed_drop_target, Spot):
		var spot := Utils.get_typed_ancestor(failed_drop_target, Spot) as Spot
		potential_matches.append_array(spot.get_all_aspect_slots())
	elif Utils.get_typed_ancestor(failed_drop_target, Survey):
		var survey := Utils.get_typed_ancestor(failed_drop_target, Survey) as Survey
		potential_matches.append_array(survey.get_all_aspect_slots())

	if potential_matches:
		if _is_slot_match_ambiguous(potential_matches, aspect_types):
			return Utils.TRANSLATION_DUMMY.tr('This <term_lower:glyph> could fit multiple slots here. Target more specifically.')
		elif recipe is SpotRecipe and (recipe as SpotRecipe).state == SpotRecipe.State.UNAVAILABLE:
			return Utils.TRANSLATION_DUMMY.tr('The parent <term_lower:spot_upgrade> must be activated first.')
		elif (recipe is HarmonizationRecipe and
			  recipe.get_aspect_slots()[0].can_be_filled_by(aspect_types) and
			  (recipe as HarmonizationRecipe).state == HarmonizationRecipe.State.UNAVAILABLE):
			return Utils.TRANSLATION_DUMMY.tr('This <term_lower:task> requires higher <term_lower:bonus>s.')
		else:
			return Utils.TRANSLATION_DUMMY.tr('This <term_lower:glyph> doesn\'t fit here.')
	else:
		return ''

static func _is_slot_match_ambiguous(slots: Array[AspectSlot], aspect_types: Array[AspectType]) -> bool:
	var matched: AspectSlot = null
	for slot in slots:
		if slot.is_filled:
			continue

		var recipe := Utils.get_typed_ancestor(slot, Recipe) as Recipe
		if recipe and not recipe.is_available():
			continue

		if slot.can_be_filled_by(aspect_types):
			if matched and not matched.is_universal:
				if matched.aspect_type == slot.aspect_type and matched.get_parent() == slot.get_parent():
					pass  # Identical slots. Doesn't matter which one we pick.
				elif slot.is_universal and not matched.is_universal:
					pass  # It is safe to always prefer non-universal slots.
				elif matched.is_universal and not slot.is_universal:
					matched = slot  # It is safe to always prefer non-universal slots.
				else:
					return true  # Ambiguous
			else:
				matched = slot
	return false

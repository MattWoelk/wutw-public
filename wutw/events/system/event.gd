@tool
class_name Event
extends Resource

enum Category { COMPANION, MAIN_STORY, LANDMARK, GENERIC, CHAIN, RECORD, SECRET }

static var _group_loader := AsyncLoadedGroup.new('res://events/resourcegroup_events.tres')

const TRIGGERED_STAGE_INDEX_VAR := 'TRIGGERED_STAGE_INDEX'
const TRIGGERED_EVER_VAR := 'EVER_TRIGGERED'

@export var event_id: String
@export var event_name: String
@export var requirement: EventRequirement
@export var steps: Array[EventStep]
@export var categories: Array[Category]
@export var start_dialogue: Dialogue

static var _all_events: Dictionary[String, Event] = {}

static func get_all_events() -> Dictionary[String, Event]:
	if not _all_events:
		for event: Event in _group_loader.get_loaded():
			if Utils.is_dev():
				assert(event.event_id)
				if event.event_id in _all_events:
					push_error('Duplicate event ID "%s":\n- %s\n- %s' %
							[event.event_id, event.resource_path, _all_events[event.event_id].resource_path])
				for step in event.steps:
					if not step.background_credit:
						push_warning('Event missing art credit: ', event.event_id)
			_all_events[event.event_id] = event
	return _all_events

static func get_event_by_id(target_event_id: String) -> Event:
	return get_all_events().get(target_event_id, null)

func get_step_by_id(step_id: String) -> EventStep:
	if not step_id:
		return null
	for step in steps:
		if step.event_step_id == step_id:
			return step
	return null

func is_requirement_satisfied(run: Run) -> bool:
	return not requirement or requirement.is_satisfied(run, self)

func has_triggered(run_data: RunData) -> bool:
	return run_data.events_state.get_int_or_default(event_id, TRIGGERED_STAGE_INDEX_VAR, -1) >= 0

func should_mark_all_choices_seen() -> bool:
	return false

func mark_all_choices_seen() -> void:
	# This could be just 0xFFFFFF, but this is clearer, and the perf is insignificant.
	for step in steps:
		for choice in step.choices:
			if choice.outcome:
				GlobalSaveGame.mark_event_choice_seen(self, get_choice_index(choice))
		if step.exit_choice:
			if step.exit_choice.outcome:
				GlobalSaveGame.mark_event_choice_seen(self, get_choice_index(step.exit_choice))

func get_choice_index(choice: EventChoice) -> int:
	const STRIDE := 5
	for i in steps.size():
		var step := steps[i]
		if choice == step.exit_choice:
			return i * STRIDE
		else:
			var index := step.choices.find(choice)
			if index > -1:
				return i * STRIDE + index + 1
	Utils.ensure(false)
	return -1

func get_num_choosable_choices(run: Run) -> int:
	if not steps:
		return 0
	var total := 0
	for choice in steps[0].choices:
		if not choice.requirement or choice.requirement.is_satisfied(run, self):
			total += 1
	if steps[0].exit_choice:
		var choice := steps[0].exit_choice
		if not choice.requirement or choice.requirement.is_satisfied(run, self):
			total += 1
	return total

func get_markedup_requirements_hint() -> String:
	var aspects: Array[AspectType]
	var bonuses: Array[BonusType]
	var cards: Array[CardType]
	var relics: Array[Relic]
	for step in steps:
		for choice in step.choices:
			if choice.show_condition and not choice.show_condition.is_satisfied(Utils.get_active_run(), self):
				continue
			EventChoice.collect_requirement_details(choice.requirement, aspects, bonuses, cards, relics)
	var pieces: Array[String]
	var get_term_tag := func(a: Term) -> String: return a.get_term_tag()
	if aspects:
		pieces.append(tr(', ').join(aspects.map(get_term_tag)))
	if bonuses:
		pieces.append(tr(', ').join(bonuses.map(get_term_tag)))
	if cards:
		pieces.append(tr(', ').join(cards.map(get_term_tag)))
	if relics:
		pieces.append(tr(', ').join(relics.map(get_term_tag)))
	return tr(', ').join(pieces)

func get_markedup_outcomes_hint() -> String:
	var bonuses: Array[BonusType]
	var cards: Array[CardType]
	var relics: Array[Relic]
	var _shop_types: Array[ShopType]
	var all_known := true
	for step in steps:
		for choice in step.choices:
			all_known = (EventChoice.collect_outcome_details(self, choice, choice.outcome, bonuses, cards, relics, _shop_types)
						 && all_known)
		if step.exit_choice:
			all_known = (EventChoice.collect_outcome_details(self, step.exit_choice, step.exit_choice.outcome, bonuses, cards, relics, _shop_types)
						 && all_known)
	var pieces: Array[String]
	var get_term_tag := func(a: Term) -> String: return a.get_term_tag()
	if bonuses:
		pieces.append(tr(', ').join(bonuses.map(get_term_tag)))
	if cards:
		pieces.append(tr(', ').join(cards.map(get_term_tag)))
	if relics:
		pieces.append(tr(', ').join(relics.map(get_term_tag)))
	if not all_known:
		pieces.append(tr('???'))
	return tr(', ').join(pieces)

func start_loading_texture() -> void:
	for step in steps:
		step.start_loading_texture()

func get_search_text() -> Array[String]:
	var result: Array[String] = [
		tr(event_name),
		get_markedup_requirements_hint(),
		get_markedup_outcomes_hint(),
	]
	if steps:
		result.append(tr(steps[0].markedup_text))
		for choice in steps[0].choices:
			result.append(tr(choice.markedup_text))
	return result

@tool
class_name SurveyRecipe
extends Recipe

signal activated

static var ASPECT_SLOT_SCENE := AsyncLoadedResource.new('res://aspects/slot/aspect_slot.tscn')

@export var max_aspects: int = 4
@export var episode: SurveyEpisode:
	set(value):
		episode = value
		if is_node_ready():
			_recreate()
@export var survey_choice: SurveyChoice:
	set(value):
		survey_choice = value
		if is_node_ready():
			_recreate()
@export var disabled: bool = false:
	set(value):
		if disabled != value:
			disabled = value
			if is_node_ready():
				_update_state_style()

var _requirements_satisfied: bool = false:
	set(value):
		if _requirements_satisfied != value:
			_requirements_satisfied = value
			if is_node_ready():
				_update_state_style()
var _faded_out: bool = false:
	set(value):
		_faded_out = value
		if is_node_ready():
			_update_state_style()
var _active: bool = false:
	set(value):
		_active = value
		if is_node_ready():
			_update_state_style()
var _fadeout_tween: Tween

func _ready() -> void:
	super._ready()
	_recreate()

	var run := Utils.get_active_run()
	if run:  # Null in editor and museum.
		# Setup listeners for requirements. We assume only bonus/inspiration matters.
		# If we ever use other requirements that may change during the survey, we need to listen
		# to related signals here.
		run.signals.bonus_gained.connect(_reevaluate_requirements.unbind(3))
		run.signals.bonus_lost.connect(_reevaluate_requirements.unbind(3))
		run.signals.inspiration_gained.connect(_reevaluate_requirements.unbind(2))
		run.signals.inspiration_lost.connect(_reevaluate_requirements.unbind(2))

	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.ABOVE], [Tooltip.Alignment.CENTERED])

func _enter_tree() -> void:
	if episode:
		var x_pivot := 0.5
		if episode.choices.find(survey_choice) == 0:
			x_pivot = 0.0
		elif episode.choices.find(survey_choice) == episode.choices.size() -1:
			x_pivot = 1.0
		UI.register_zoomable(self, x_pivot, 0.5)

func get_aspect_slots() -> Array[AspectSlot]:
	var result: Array[AspectSlot]
	result.assign(%AspectsList.get_children())
	return result

func set_faded_out(is_faded_out: bool) -> void:
	_faded_out = is_faded_out
	if _faded_out:
		mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	else:
		mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED

func is_available() -> bool:
	return _requirements_satisfied and not disabled

func is_active() -> bool:
	return _active

func update_outcome() -> void:
	var run := Utils.get_active_run()
	if survey_choice.outcome:
		var outcome_description: String
		if Utils.is_in_editor() or GlobalSaveGame.has_seen_survey_choice(episode, episode.choices.find(survey_choice)):
			if survey_choice.outcome_description_override:
				outcome_description = tr(survey_choice.outcome_description_override)
			else:
				outcome_description = survey_choice.outcome.describe(run)
		else:
			outcome_description = tr('???')
		(%OutcomeLabel as MarkedUpLabel).set_markedup_text(outcome_description)
		(%OutcomesPanel as Control).modulate.a = 1
		(%OutcomesPanel as Control).mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
	else:
		(%OutcomesPanel as Control).modulate.a = 0
		(%OutcomesPanel as Control).mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
		if not run and not Utils.is_in_editor():  # Museum
			(%OutcomesPanel as Control).visible = false

func _recreate() -> void:
	if not survey_choice:
		return

	var run := Utils.get_active_run()

	if survey_choice.requirement:
		if survey_choice.requirement_description_override:
			(%RequirementLabel as MarkedUpLabel).set_markedup_text(
				tr('Req: ') + tr(survey_choice.requirement_description_override))
		else:
			(%RequirementLabel as MarkedUpLabel).set_markedup_text(
				tr('Req: ') + survey_choice.requirement.describe(run, false))
		(%RequirementPanel as Control).modulate.a = 1
		(%RequirementPanel as Control).mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
	else:
		(%RequirementPanel as Control).modulate.a = 0
		(%RequirementPanel as Control).mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
		if not run and not Utils.is_in_editor():  # Museum
			(%RequirementPanel as Control).visible = false

	(%NameLabel as Label).text = survey_choice.label

	Utils.clear_node(%AspectsList)
	var required_aspects: Array[AspectType]
	required_aspects.append_array(survey_choice.aspects)
	var num_extra_slots := 0
	if run:
		num_extra_slots += run.get_current_season_index()
		num_extra_slots += run.get_var(RunVars.Var.EXTRA_SURVEY_SLOTS)
	elif Utils.is_in_editor():
		num_extra_slots = max_aspects  # Default to maximum for editor.
		# IMPORTANT: If these don't fit, there's an engine bug that causes an infinite loop
		#            trying to resize siblings to fit.
	else:
		num_extra_slots = 1  # Default for museum.
	for _i in num_extra_slots:
		required_aspects.append_array(survey_choice.aspects_per_season)
	if required_aspects.size() > max_aspects:
		required_aspects.resize(max_aspects)
	required_aspects.sort_custom(AspectType.compare)
	for aspect_type in required_aspects:
		var aspect_slot := ASPECT_SLOT_SCENE.instantiate_loaded_scene() as AspectSlot
		aspect_slot.aspect_type = aspect_type
		aspect_slot.is_universal = aspect_type == null
		aspect_slot.filled.connect(_on_aspect_filled)
		%AspectsList.add_child(aspect_slot)

	update_outcome()

	_faded_out = false
	_reevaluate_requirements()

func _update_state_style() -> void:
	if _active:
		modulate = Color(1.2, 1.2, 1.2, 1)
	elif is_available():
		modulate = Color(0.9, 0.9, 0.9, 1)
	else:
		modulate = Color(0.7, 0.7, 0.7, 1)

	if _fadeout_tween:
		_fadeout_tween.kill()
	_fadeout_tween = create_tween()
	_fadeout_tween.tween_property(self, 'modulate:a', 0.35 if _faded_out else 1.0, FADEOUT_ANIM_DURATION)
	_fadeout_tween.play()

	for aspect_slot: AspectSlot in %AspectsList.get_children():
		aspect_slot.display_as_inaccessible = not is_available()

func _reevaluate_requirements() -> void:
	var run := Utils.get_active_run()
	_requirements_satisfied = (not run
							or not survey_choice.requirement
							or survey_choice.requirement.is_satisfied(run, null))

func _on_aspect_filled() -> void:
	var all_filled := true
	for slot in %AspectsList.get_children():
		if not (slot as AspectSlot).is_filled:
			all_filled = false
			break
	if all_filled:
		_active = true
		activated.emit()

func _make_tooltip_text() -> String:
	if not survey_choice:
		return ''

	var text := ''

	var run := Utils.get_active_run()

	var req_description : String
	if survey_choice.requirement_description_override:
		req_description = tr(survey_choice.requirement_description_override)
	elif survey_choice.requirement:
		req_description = survey_choice.requirement.describe(run, true)
	if req_description:
		text += tr('[b]Requirement:[/b] %s.') % req_description
		text += '\n\n'

	var outcome_text: String
	if GlobalSaveGame.has_seen_survey_choice(episode, episode.choices.find(survey_choice)):
		if survey_choice.outcome:
			if survey_choice.outcome_description_override:
				outcome_text = tr(survey_choice.outcome_description_override)
			else:
				outcome_text = survey_choice.outcome.describe(run)
	elif survey_choice.outcome:
		outcome_text = tr('Unknown')
		outcome_text = '\n\n'
		outcome_text = tr('[i]Activating a choice will reveal its outcome for all future expeditions.[/i]')

	if outcome_text:
		text += tr('[b]Outcome:[/b] ') + outcome_text

	if not text:
		text = tr('This choice ends the encounter.')

	return text.strip_edges()

@tool
class_name EventChoiceScene
extends VBoxContainer

signal selected

@export var event: Event
@export var event_step: EventStep
@export var event_choice: EventChoice:
	set(value):
		event_choice = value
		if is_node_ready():
			_recreate()

func _ready() -> void:
	_recreate()
	GlobalTooltipSystem.attach(%Button as Control, _make_tooltip_text,
			[Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.CENTERED], self)
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.CENTERED])

func _enter_tree() -> void:
	UI.register_zoomable(self, 1 if Utils.get_active_run() else 0, 0.5 if Utils.get_active_run() else 1.0)

func _recreate() -> void:
	if not event_choice:
		return
	assert(event)
	assert(event_step)

	var run := Utils.get_active_run()

	var button_text := tr(event_choice.markedup_text)

	var req_description: String
	if event_choice.markedup_requirement_hint:
		req_description = tr(event_choice.markedup_requirement_hint)
	elif event_choice.requirement:
		req_description = event_choice.requirement.describe(run, false)
	if req_description:
		button_text = '[b][lb]%s[rb][/b] %s' % [req_description, button_text]

	var button_label := %ButtonLabel as MarkedUpLabel
	button_label.set_markedup_text(button_text, MarkedUpLabel.LinkMode.NONE)
	if button_label.get_content_width() > 700:
		button_text = button_text.replace('[rb][/b] ', '[rb][/b]\n')
		button_label.set_markedup_text(button_text, MarkedUpLabel.LinkMode.NONE)

	if run:  # Not editor or museum
		(%Button as Button).disabled = (event_choice.requirement and
				not event_choice.requirement.is_satisfied(run, event))

	var outcome_text := ''
	if event_choice.markedup_outcome_hint:
		outcome_text += tr(event_choice.markedup_outcome_hint)
	elif event_choice.outcome:
		if not Utils.is_in_editor() and not GlobalSaveGame.has_seen_event_choice(event, event.get_choice_index(event_choice)):
			outcome_text = tr('???')
		else:
			outcome_text += event_choice.outcome.describe(run)
			if event_choice.result_event_step_id:
				outcome_text += tr(', event continues...')
	elif event_choice.result_event_step_id:
		outcome_text = tr('Event continues...')

	var outcome_label := %OutcomeLabel as MarkedUpLabel
	if outcome_text:
		outcome_label.set_markedup_text(outcome_text, MarkedUpLabel.LinkMode.NONE)
		(%OutcomePanel as Control).visible = true
	else:
		(%OutcomePanel as Control).visible = false

func _on_button_pressed() -> void:
	selected.emit()

func _make_tooltip_text() -> String:
	if not event_choice:
		return ''

	var text := ''

	var run := Utils.get_active_run()

	var req_description : String
	if event_choice.markedup_requirement_tooltip:
		req_description = tr(event_choice.markedup_requirement_tooltip)
	elif event_choice.markedup_requirement_hint:
		req_description = tr(event_choice.markedup_requirement_hint)
	elif event_choice.requirement:
		req_description = event_choice.requirement.describe(run, true)
	if req_description:
		text += tr('[b]Requirement:[/b] %s.\n\n') % req_description

	var outcome_text := ''
	if event_choice.markedup_outcome_hint:
		outcome_text += tr(event_choice.markedup_outcome_hint)
	elif event_choice.outcome:
		if not Utils.is_in_editor() and not GlobalSaveGame.has_seen_event_choice(event, event.get_choice_index(event_choice)):
			outcome_text = tr('Unknown\n\n[i]Selecting a choice will reveal its outcome for all future expeditions.[/i]')
		else:
			outcome_text += event_choice.outcome.describe(run)

	if outcome_text:
		text += tr('[b]Outcome:[/b] %s') % outcome_text

	if event_choice.result_event_step_id:
		if text:
			text += '\n\n' + tr('[b]This choice leads to another scene.[/b]')
		else:
			text = tr('[b]This choice leads to another scene.[/b]')

	if not text:
		text = tr('This choice ends the event.')

	return text.strip_edges()

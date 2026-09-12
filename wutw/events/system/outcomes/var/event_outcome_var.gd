@tool
class_name EventOutcome_Var
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/event_outcome_widget_message.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

enum Scope { RUN, SAVEGAME }
enum ModType { SET, ADD }

@export var scope: Scope = Scope.RUN
@export var event_id: String = '<self>'
@export var var_id: String
@export var var_type: EventsState.Type = EventsState.Type.INT
@export var mod_type: ModType = ModType.SET
@export var value: String
@export var description: String = '<unset>'
@export var outcome_description: String = ''

func apply(event: Event) -> EventOutcomeWidget:
	var events_state: EventsState
	if scope == Scope.RUN:
		events_state = Utils.get_active_run().get_events_state()
	else:
		events_state = GlobalSaveGame.get_events_state()

	var actual_event_id := event_id
	if event_id == '<self>':
		actual_event_id = event.event_id

	match var_type:
		EventsState.Type.INT:
			var new_value := value.to_int()
			if mod_type == ModType.ADD:
				new_value += events_state.get_int_or_default(actual_event_id, var_id, 0)
			events_state.set_int(actual_event_id, var_id, new_value)
		EventsState.Type.BOOL:
			Utils.ensure(mod_type == ModType.SET)
			Utils.ensure(value in ['true', 'false'])
			events_state.set_bool(actual_event_id, var_id, value == 'true')
		EventsState.Type.STRING:
			Utils.ensure(mod_type == ModType.SET)
			events_state.set_string(actual_event_id, var_id, value)

	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_Message
	widget.text = tr(outcome_description) if outcome_description else tr('Future opportunities have changed.')
	return widget

func describe(_run: Run) -> String:
	if description != '<unset>':
		return tr(description)
	else:
		push_warning('Event choice outcome sets var; should use a custom description.')
		return tr('Something will happen in the future.')

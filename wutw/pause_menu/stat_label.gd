@tool
class_name StatLabel
extends HBoxContainer

enum Display { NUMBER, DELTA, PERCENTAGE, BOOL }

@export var run_var: RunVars.Var:
	set(value):
		run_var = value
		if is_node_ready():
			_recreate()
@export var label: String:
	set(value):
		label = value
		if is_node_ready():
			_recreate()
@export var label_realistic: String:
	set(value):
		label_realistic = value
		if is_node_ready():
			_recreate()
@export var display: Display = Display.NUMBER:
	set(value):
		display = value
		if is_node_ready():
			_recreate()
@export var hide_if_default: bool = false:
	set(value):
		hide_if_default = value
		if is_node_ready():
			_recreate()

func _ready() -> void:
	_recreate()

func _recreate() -> void:
	(%NameLabel as Label).text = tr(label)
	if label_realistic and Utils.is_realistic_era():
		(%NameLabel as Label).text = tr(label_realistic)
	var value := Utils.get_active_run().get_var(run_var) if Utils.get_active_run() else RunVars.DEFAULTS[run_var]
	(%ValueLabel as Label).text = _format_number(value)
	if hide_if_default and Utils.get_active_run():
		visible = value != RunVars.DEFAULTS[run_var]

func _format_number(value: int) -> String:
	match display:
		Display.NUMBER: return str(value)
		Display.DELTA: return '%+d' % value
		Display.PERCENTAGE: return str(value) + '%'
		Display.BOOL: return tr('Yes') if value > 0 else tr('No')
		_: return str(value)

@tool
class_name TooltipSystem
extends Node

signal pre_tooltip_shown(attached_to: Control, tooltip: Tooltip)

var _tooltip_configs: Dictionary[int, TooltipConfig] = {}
var _scanning_queue: Array[TooltipConfig]  # We're checking these for the control being destroyed.
var _cleaned_configs: Dictionary[int, TooltipConfig]  # These have been checked this iteration.

func attach(control: Control, text_src: Callable,
			preferred_directions: Array[Tooltip.RelativeDirection] = [],
			preferred_alignments: Array[Tooltip.Alignment] = [],
			rect_control: Control = null) -> void:
	if Utils.is_in_editor():
		return  # Fake to prevent errors.

	var control_id := control.get_instance_id()
	if control_id in _tooltip_configs:
		push_warning('Ignoring duplicate tooltip.')
		return

	var tooltip_config := TooltipConfig.new()
	tooltip_config.control = control
	tooltip_config.text_src = text_src
	tooltip_config.preferred_directions = preferred_directions
	tooltip_config.preferred_alignments = preferred_alignments
	tooltip_config.rect_control = rect_control

	_tooltip_configs[control_id] = tooltip_config
	_cleaned_configs[control_id] = tooltip_config  # New controls are automatically considered clean.

	control.mouse_entered.connect(_show_tooltip.bind(tooltip_config))
	control.mouse_exited.connect(_hide_tooltip.bind(tooltip_config))

func detach(control: Control) -> void:
	if Utils.is_in_editor():
		return  # Fake to prevent errors.
	var control_id := control.get_instance_id()
	if Utils.ensure(control_id in _tooltip_configs):
		var tooltip_config := _tooltip_configs[control_id]
		if tooltip_config.created_tooltip:
			tooltip_config.created_tooltip.destroy()
		control.mouse_entered.disconnect(_show_tooltip.bind(tooltip_config))
		control.mouse_exited.disconnect(_hide_tooltip.bind(tooltip_config))
		_tooltip_configs.erase(control_id)
		_scanning_queue.erase(tooltip_config)
		_cleaned_configs.erase(control_id)

func has_attached_tooltip(control: Control) -> bool:
	return control.get_instance_id() in _tooltip_configs

func _process(_delta: float) -> void:
	if _tooltip_configs.is_empty():
		return

	if _scanning_queue:
		var tooltip_config := _scanning_queue.pop_back() as TooltipConfig
		if tooltip_config.control:
			# Clean!
			_cleaned_configs[tooltip_config.control.get_instance_id()] = tooltip_config
		elif tooltip_config.created_tooltip:
			tooltip_config.created_tooltip.destroy()

		if not _scanning_queue:
			# Finished scan. Swap the clean ones in and prepare for the next scan.
			_tooltip_configs = _cleaned_configs
			_cleaned_configs = {}
	else:
		# Start new scan.
		_scanning_queue = _tooltip_configs.values()

func _show_tooltip(tooltip_config: TooltipConfig) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN:  # Drag-and-drop in progress.
		return
	if not tooltip_config.created_tooltip:
		tooltip_config.created_tooltip = Tooltip.create(
					tooltip_config.control, tooltip_config.text_src.call() as String,
					tooltip_config.preferred_directions,
					tooltip_config.preferred_alignments,
					tooltip_config.rect_control)
	else:
		tooltip_config.created_tooltip.set_markedup_text(tooltip_config.text_src.call() as String)
	pre_tooltip_shown.emit(tooltip_config.control, tooltip_config.created_tooltip)
	tooltip_config.created_tooltip.show_tooltip()

func _hide_tooltip(tooltip_config: TooltipConfig) -> void:
	if tooltip_config.created_tooltip:
		tooltip_config.created_tooltip.hide_tooltip()

class TooltipConfig extends RefCounted:
	var control: Control
	var text_src: Callable
	var preferred_directions: Array[Tooltip.RelativeDirection]
	var preferred_alignments: Array[Tooltip.Alignment]
	var rect_control: Control = null
	var created_tooltip: Tooltip = null

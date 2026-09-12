@abstract
class_name TutorialBase
extends RefCounted

@warning_ignore('unused_signal')  # Emitted by subclasses
signal ready_to_trigger
signal finished

static var TUTORIAL_TOOLTIP_SCENE := AsyncLoadedResource.new('res://tutorial/tutorial_tooltip.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

enum Type { RUN, HUB }

var _container: Control
var _mouse_blocker: ColorRect
var _tooltip: TutorialTooltip
var _outline_setup: OutlineSetup

@abstract func start_listening() -> void
@abstract func stop_listening() -> void
@abstract func trigger() -> void
@abstract func get_skip_id() -> String
@abstract func get_tutorial_type() -> Type

func get_tutorial_order() -> int:
	return 0  # Relative to tutorials queued at the same time.

func is_skipped() -> bool:
	return GameSettings.SkipTutorials.is_skipped(get_skip_id())

func mark_skipped() -> void:
	if not is_skipped():
		return GameSettings.SkipTutorials.set_skipped(get_skip_id(), true, true)

func remove() -> void:
	if _tooltip:
		_tooltip.hide_tooltip()
	if _container:
		_container.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
		var tween := _get_container().create_tween()
		tween.tween_property(_get_container(), 'modulate:a', 0.0, 0.3)
		tween.play()
		await tween.finished

		assert(_outline_setup)
		_container.get_tree().process_frame.disconnect(_outline_setup.update_sizing)
		_outline_setup = null

		_container.queue_free()
		_container = null

func _outline_controls(controls: Array[Control], separate: bool = false,
						unshaded_override: Array[Control] = [], padding: Vector2 = Vector2(2, 2)) -> void:
	_outline_setup = OutlineSetup.new()
	_outline_setup.controls = controls
	_outline_setup.separate = separate
	_outline_setup.unshaded_override = unshaded_override
	_outline_setup.padding = padding

	_outline_setup.container = _get_container()

	_outline_setup.scrim = ColorRect.new()
	_outline_setup.scrim.color = Color(0, 0, 0, 0.5)
	_outline_setup.scrim.z_index = 1
	_outline_setup.scrim.material = load('res://tutorial/tutorial_scrim_mat.tres').duplicate()
	_get_container().add_child(_outline_setup.scrim)

	var outline_rects: Array[Rect2]
	if separate:
		for control in controls:
			outline_rects.append(Utils.get_screen_rect(control))
	elif controls:
		outline_rects.append(Utils.get_screen_rect(controls[0]))
		for control: Control in controls.slice(1):
			outline_rects[0] = outline_rects[0].merge(Utils.get_screen_rect(control))
	for outline_rect in outline_rects:
		var outline := Panel.new()
		outline.add_theme_stylebox_override('panel', load('res://tutorial/tutorial_outline_stylebox.tres') as StyleBox)
		outline.z_index = 2
		_outline_setup.outline_panels.append(outline)
		_get_container().add_child(outline)

	_outline_setup.update_sizing()

	_get_container().modulate.a = 0
	var tween := _get_container().create_tween()
	tween.tween_property(_get_container(), 'modulate:a', 1, 0.3)
	tween.play()

	_get_container().get_tree().process_frame.connect(_outline_setup.update_sizing)

func _show_tooltip(control: Control, markedup_text: String,
				   tooltip_directions: Array[Tooltip.RelativeDirection] = [Tooltip.RelativeDirection.ABOVE, Tooltip.RelativeDirection.BELOW]) -> void:
	_mouse_blocker = ColorRect.new()
	_mouse_blocker.size = Vector2(1920, 1080)
	_mouse_blocker.z_index = 0
	_mouse_blocker.modulate.a = 0
	_get_container().add_child(_mouse_blocker)

	_tooltip = TutorialTooltip.create(
			control, markedup_text, tooltip_directions, [Tooltip.Alignment.CENTERED],
			null, TUTORIAL_TOOLTIP_SCENE.get_loaded_scene(), false)
	_tooltip.z_index = Utils.get_absolute_z_index(_get_container()) + UI.LAYER_SPACING
	_tooltip.margin = 5
	_tooltip.continued.connect(_on_continued, CONNECT_ONE_SHOT)
	_get_container().add_child(_tooltip)
	_tooltip.show_tooltip()
	if _outline_setup:
		_outline_setup.tooltip_anchor = control
		_outline_setup.tooltip = _tooltip

func _on_continued() -> void:
	remove()
	finished.emit()

func _get_container() -> Control:
	if not _container:
		_container = Control.new()
		_container.name = (get_script() as Script).get_global_name()
		GlobalUI.add_layer_content(_container, UI.Layer.TUTORIAL)
	return _container

class OutlineSetup extends RefCounted:
	var controls: Array[Control]
	var separate: bool
	var unshaded_override: Array[Control]
	var padding: Vector2

	var container: Control
	var scrim: ColorRect
	var outline_panels: Array[Panel]

	var tooltip_anchor: Control
	var tooltip: TutorialTooltip

	func update_sizing() -> void:
		if not tooltip or not tooltip.is_inside_tree():
			return

		if not unshaded_override:
			unshaded_override = controls

		var rect: Rect2

		if unshaded_override:
			rect = Utils.get_screen_rect(unshaded_override[0])
			for control: Control in unshaded_override.slice(1):
				rect = rect.merge(Utils.get_screen_rect(control))
		else:
			rect = Rect2(100, 100, 0, 0)  # Fake empty rect.

		var vp_size := container.get_viewport_rect().size
		scrim.size = vp_size
		(scrim.material as ShaderMaterial).set_shader_parameter('position', rect.position)
		(scrim.material as ShaderMaterial).set_shader_parameter('size', rect.size)

		var outline_rects: Array[Rect2]
		if separate:
			for control in controls:
				outline_rects.append(Utils.get_screen_rect(control))
		elif controls:
			outline_rects.append(Utils.get_screen_rect(controls[0]))
			for control: Control in controls.slice(1):
				outline_rects[0] = outline_rects[0].merge(Utils.get_screen_rect(control))
		if Utils.ensure(outline_panels.size() == outline_rects.size()):
			for i in outline_rects.size():
				var outline := outline_panels[i]
				var outline_rect := outline_rects[i]
				outline.position = outline_rect.position - padding
				outline.size = outline_rect.size + padding * 2

		if tooltip:
			tooltip._position()

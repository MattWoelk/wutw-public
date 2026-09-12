class_name TutorialSystem
extends Node

static var _group_loader := AsyncLoadedGroup.new('res://tutorial/resourcegroup_tutorials.tres')

var _all_tutorials: Array[TutorialBase]
var _listening_tutorials: Array[TutorialBase]
var _current_tutorial: TutorialBase
var _queued_tutorials: Array[TutorialBase]

func _ready() -> void:
	await GlobalStartup.wait_loaded_normal()
	for tutorial_script: GDScript in _group_loader.get_loaded():
		if tutorial_script.can_instantiate():  # Not abstract
			_all_tutorials.append(tutorial_script.new() as TutorialBase)

func hub_started() -> void:
	_start_listening(TutorialBase.Type.HUB)

func hub_ended() -> void:
	_clear_listeners(TutorialBase.Type.HUB)

func run_started() -> void:
	_start_listening(TutorialBase.Type.RUN)

func run_ended() -> void:
	_clear_listeners(TutorialBase.Type.RUN)

func queue_tutorial(tutorial: TutorialBase) -> void:
	if tutorial in _listening_tutorials:
		tutorial.stop_listening()
		tutorial.ready_to_trigger.disconnect(queue_tutorial.bind(tutorial))
		_listening_tutorials.erase(tutorial)
	_queued_tutorials.append(tutorial)
	if not get_tree().process_frame.is_connected(_check_queued_tutorial):
		get_tree().process_frame.connect(_check_queued_tutorial, CONNECT_ONE_SHOT)

func get_current_tutorial() -> TutorialBase:
	return _current_tutorial

func get_tutorial(tutorial_class: Script) -> TutorialBase:
	for tutorial in _all_tutorials:
		if tutorial.get_script() == tutorial_class:
			return tutorial
	return null

func reset_all_tutorials() -> void:
	for key in GameSettings.SkipTutorials.keys():
		GameSettings.SkipTutorials.set_skipped(key, false)
	GlobalGameSettings.save()
	_queued_tutorials.clear()

func _start_listening(type: TutorialBase.Type) -> void:
	for tutorial in _all_tutorials:
		if not tutorial.is_skipped() and tutorial.get_tutorial_type() == type:
			tutorial.ready_to_trigger.connect(queue_tutorial.bind(tutorial))
			tutorial.start_listening()
			_listening_tutorials.append(tutorial)

func _check_queued_tutorial() -> void:
	if _queued_tutorials.is_empty() or _current_tutorial:
		return

	var earliest_tutorial: TutorialBase = null
	for tutorial in _queued_tutorials:
		if not earliest_tutorial or tutorial.get_tutorial_order() < earliest_tutorial.get_tutorial_order():
			earliest_tutorial = tutorial
	_queued_tutorials.erase(earliest_tutorial)
	if earliest_tutorial.is_skipped():
		_check_queued_tutorial()
		return

	earliest_tutorial.finished.connect(_on_tutorial_finished)
	_current_tutorial = earliest_tutorial
	earliest_tutorial.trigger()

func _on_tutorial_finished() -> void:
	_current_tutorial.mark_skipped()
	_current_tutorial = null
	_check_queued_tutorial()

func _clear_listeners(type: TutorialBase.Type) -> void:
	if _current_tutorial:
		if _current_tutorial.finished.is_connected(_on_tutorial_finished):
			_current_tutorial.finished.disconnect(_on_tutorial_finished)
		_current_tutorial.remove()
		_current_tutorial.remove()
		_current_tutorial = null
	_queued_tutorials.clear()

	for tutorial in _listening_tutorials:
		if tutorial.get_tutorial_type() == type:
			tutorial.stop_listening()
			tutorial.ready_to_trigger.disconnect(queue_tutorial.bind(tutorial))
	_listening_tutorials.clear()

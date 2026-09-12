class_name ErrorNotificationsList
extends Node2D

static var ERROR_NOTIFICATION_SCENE := AsyncLoadedResource.new('res://utils/error_notifications_list/error_notification.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

func _ready() -> void:
	Utils.clear_node(%Errors)

func show_error(message: String) -> void:  # Input already translated.
	var list := %Errors as VBoxContainer
	while list.get_child_count() >= 3:
		list.remove_child(list.get_child(0))
	var error := ERROR_NOTIFICATION_SCENE.instantiate_loaded_scene() as ErrorNotification
	error.message = message
	error.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	list.add_child(error)

extends Node2D

@export var dialogue: Dialogue

func _ready() -> void:
	_show_dialogue()

func _show_dialogue() -> void:
	await GlobalUI.show_dialogue(dialogue)
	_show_dialogue()

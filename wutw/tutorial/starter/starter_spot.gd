@tool
class_name StarterSpot
extends UkiyoePanelContainer

@export var recipes: Array[Recipe]

func _ready() -> void:
	super._ready()

func _can_drop_data(pos: Vector2, data: Variant) -> bool:
	assert(data is Card)
	for recipe in recipes:
		if recipe._can_drop_data(pos, data):
			return true
	return false

func _drop_data(pos: Vector2, data: Variant) -> void:
	assert(data is Card)
	for recipe in recipes:
		if recipe._can_drop_data(pos, data):
			recipe._drop_data(pos, data)
			return
	assert(false)

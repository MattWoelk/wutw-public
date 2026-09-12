@tool
class_name AspectCountersPanel
extends UkiyoePanelContainer

@export var card_types: Array[CardType] = []:
	set(value):
		if card_types == value:
			return
		card_types = value
		if is_node_ready():
			_update()
@export var zoomable_pivot: Vector2 = Vector2(0, 1)

func _ready() -> void:
	super._ready()
	_update()

func _enter_tree() -> void:
	UI.register_zoomable(self, zoomable_pivot.x, zoomable_pivot.y)

func _update() -> void:
	var counts: Dictionary[AspectType, int] = {}
	for card_type in card_types:
		for aspect_type in card_type.aspects:
			counts[aspect_type] = counts.get(aspect_type, 0) + 1
	for counter: AspectCounter in %CountersList.get_children():
		counter.count = counts.get(counter.aspect_type, 0)

@tool
class_name DropdownOption
extends UkiyoeButton

@export var markedup_text: String:
	set(value):
		markedup_text = value
		_update()

func _ready() -> void:
	super._ready()
	_update()

func _process(delta: float) -> void:
	super._process(delta)
	(%Label as MarkedUpLabel).anchor_left = ANCHOR_BEGIN
	(%Label as MarkedUpLabel).anchor_right = ANCHOR_END
	(%Label as MarkedUpLabel).anchor_top = ANCHOR_BEGIN
	(%Label as MarkedUpLabel).anchor_bottom = ANCHOR_END
	(%Label as MarkedUpLabel).position.x = 10

func _update() -> void:
	if not is_node_ready():
		return
	text = ''
	(%Label as MarkedUpLabel).set_markedup_text('  ' + markedup_text)

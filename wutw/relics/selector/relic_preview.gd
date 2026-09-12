@tool
class_name RelicPreview
extends UkiyoePanelContainer

@export var relic: Relic:
	set(value):
		relic = value
		if is_node_ready():
			_update()

func _ready() -> void:
	super._ready()
	_update()

func _update() -> void:
	if not relic:
		return
	(%Icon as TextureRect).texture = relic.icon
	(%NameLabel as Label).text = relic.get_relic_name(true)
	(%DescriptionLabel as MarkedUpLabel).set_markedup_text(relic.get_markedup_description())

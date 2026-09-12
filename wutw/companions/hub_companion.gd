class_name HubCompanion
extends HubFacility

@export var companion: Companion

func _ready() -> void:
	tooltip_text = tr('[b]%s Companion[/b]') % tr(companion.companion_name)
	if GlobalSaveGame.has_unlocked_companion(companion):
		visible = true
		if get_node_or_null('%AnimationPlayer'):
			(%AnimationPlayer as AnimationPlayer).play('idle')
			(%AnimationPlayer as AnimationPlayer).seek(randf_range(0, 1.5), true)
		super._ready()
	else:
		visible = false

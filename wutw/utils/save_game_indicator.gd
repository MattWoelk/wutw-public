class_name SaveGameIndicator
extends Node2D

func _ready() -> void:
	if not Utils.is_in_editor():
		modulate.a = 0
		GlobalSaveGame.save_started.connect(_on_started)
		GlobalSaveGame.save_finished.connect(_on_finished)
		GlobalSaveGame.save_failed.connect(_on_failed)
		(%AnimationPlayer as AnimationPlayer).animation_started.connect(_on_anim_started)
		(%AnimationPlayer as AnimationPlayer).animation_finished.connect(_on_anim_finished)

func _on_started() -> void:
	(%AnimationPlayer as AnimationPlayer).play('start')

func _on_finished() -> void:
	(%AnimationPlayer as AnimationPlayer).queue('finish')

func _on_failed() -> void:
	(%AnimationPlayer as AnimationPlayer).queue('failed')

func _on_anim_started(anim_name: String) -> void:
	if anim_name == 'finish':
		GlobalAudioSystem.play(AK.EVENTS.UI_MAP_STAMP)

func _on_anim_finished(anim_name: String) -> void:
	if anim_name == 'start' or anim_name == 'loop':
		(%AnimationPlayer as AnimationPlayer).queue('loop')

class_name HubTower
extends HubFacility

func _ready() -> void:
	super._ready()
	_update()
	GlobalSaveGame.changed.connect(_update)

func _update() -> void:
	(%NewShardTypeLabel as Label).visible = _has_any_new_histories()

func _make_tooltip_text() -> String:
	var result := tr(tooltip_text)
	if _has_any_new_histories():
		result += '\n\n' + tr('[b]New shard history available![/b]')
	return result

func _has_any_new_histories() -> bool:
	for shard_type: ShardType in ShardType.get_all_shard_types().values():
		if GlobalSaveGame.is_shard_type_unlocked(shard_type):
			var progress := GlobalSaveGame.get_shard_type_progress(shard_type)
			if progress.get_num_histories_completed() > progress.get_num_histories_seen():
				return true
	return false

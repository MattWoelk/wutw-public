class_name VersionWatermark
extends Node2D

func _ready() -> void:
	var label := %VersionLabel as Label
	if Utils.is_dev():
		label.text = 'BUILD: editor'
	else:
		var build_metadata := load(BuildMetadata.EXPORT_PATH) as BuildMetadata
		if build_metadata and build_metadata.git_commit_hash:
			label.text = 'BUILD: ' + build_metadata.git_commit_hash
			if build_metadata.git_tag:
				label.text += ' (%s)' % build_metadata.git_tag
	_update_visibility()
	GlobalGameSettings.changed.connect(_update_visibility)

func _update_visibility() -> void:
	(%VersionLabel as Label).visible = GameSettings.Interface.show_version_watermark.value()

class_name PendingTripsList
extends PanelContainer

func _ready() -> void:
	var pieces: Array[String]
	for uid in GlobalSaveGame.get_finished_trip_uids():
		var past_run := GlobalSaveGame.get_past_run(uid)
		var label := past_run.get_shard_display_name()
		if past_run.shard_type:
			label += ' (%s)' % tr(past_run.shard_type.name)
		pieces.append('[img color=#080 width=1em height=1em]res://quests/list/checkmark.png[/img] %s' % label)
	for uid in GlobalSaveGame.get_queued_trip_uids():
		var past_run := GlobalSaveGame.get_past_run(uid)
		var label := past_run.get_shard_display_name()
		if past_run.shard_type:
			label += ' (%s)' % tr(past_run.shard_type.name)
		pieces.append('[img color=#000 width=1em height=1em]res://quests/list/dashmark.png[/img] %s' % label)

	if not pieces:
		visible = false
	else:
		visible = true
		pieces.append(tr('[i]It takes one <term_lower:season> to finish each trip.[/i]'))
		(%MarkedUpLabel as MarkedUpLabel).set_markedup_text('\n'.join(pieces), MarkedUpLabel.LinkMode.LINK)
		_update_font_size()
		GlobalGameSettings.changed.connect(_update_font_size)

func _update_font_size() -> void:
	Utils._scale_font_size(%MarkedUpLabel as MarkedUpLabel, false, 16)

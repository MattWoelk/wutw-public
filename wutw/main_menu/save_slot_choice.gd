class_name SaveSlotChoice
extends Control

signal selected
signal deleted

@export var slot: int = -1:
	set(value):
		slot = value
		if is_node_ready():
			_update()

func _ready() -> void:
	_update()

func _on_button_pressed() -> void:
	selected.emit()

func _update() -> void:
	if slot == -1:
		return
	(%TitleLabel as Label).text = tr('Save Slot %d') % (slot + 1)
	var save := SaveGame.new()
	save.load_game(slot)
	@warning_ignore('integer_division')
	var era := (save.get_main_quest_progress() as int) / 100
	var num_runs := save.get_past_run_ids().size()
	var details := tr('Era %d, %s\nLast saved: %s') % [
		era,
		tr_n('%d shard', '%d shards', num_runs) % num_runs,
		Utils.describe_relative_time(save.get_last_saved_timestamp())
	]
	(%DetailLabel as Label).text = details
	save.init_new_game(500)  # Clear state, importantly destroy quest instances.
	save.queue_free()

func _on_delete_button_pressed() -> void:
	var text := tr('Are you sure you want to delete this savegame?\n\n')
	var confirmation := GlobalUI.show_confirm(tr('Delete Slot?'), text, tr('Delete'), tr('Cancel'))
	confirmation.confirmed.connect(func() -> void:
		SaveGame.delete(slot)
		deleted.emit()
	)

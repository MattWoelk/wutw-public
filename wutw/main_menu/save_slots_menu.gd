class_name SaveSlotsMenu
extends Node

signal selected(slot: int)
signal canceled

static var SLOT_CHOICE_SCENE := AsyncLoadedResource.new('res://main_menu/save_slot_choice.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)

var slots: Array[int]

var _closing := false

func _ready() -> void:
	Utils.clear_node(%List)
	for slot in slots:
		var slot_choice: SaveSlotChoice = SLOT_CHOICE_SCENE.instantiate_loaded_scene()
		slot_choice.slot = slot
		slot_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_choice.selected.connect(_on_slot_selected.bind(slot))
		slot_choice.deleted.connect(_on_slot_deleted.bind(slot_choice))
		%List.add_child(slot_choice)

	(%ScrollPanel as ScrollPanel).animate_unroll()

func close() -> void:
	if not _closing:
		_closing = true
		Utils.set_input_enabled(%ScrollPanel as ScrollPanel, false)
		(%BG as FadedBackground).fade_out()
		await (%ScrollPanel as ScrollPanel).animate_roll()
		queue_free()

func _on_slot_selected(slot: int) -> void:
	selected.emit(slot)
	close()

func _on_slot_deleted(slot_choice: SaveSlotChoice) -> void:
	slot_choice.queue_free()

func _on_cancel_button_pressed() -> void:
	canceled.emit()
	close()

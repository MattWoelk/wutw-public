@abstract
class_name Recipe
extends Control

const FADEOUT_ANIM_DURATION := 0.2

@abstract func get_aspect_slots() -> Array[AspectSlot]
@abstract func set_faded_out(is_faded_out: bool) -> void
@abstract func is_available() -> bool

func _ready() -> void:
	var accepted_aspects: Array[AspectType]
	for slot in get_aspect_slots():
		if slot.is_universal:
			accepted_aspects.assign(AspectType.get_all_types())
			break
		elif slot.aspect_type not in accepted_aspects:
			accepted_aspects.append(slot.aspect_type)
	if not Utils.is_in_editor():
		mouse_entered.connect(_request_slots)
		mouse_exited.connect(_retract_slot_request)
		tree_exiting.connect(_retract_slot_request)
		GlobalContextHighlight.offer_changed.connect(func(offered: ContextHighlight.Context) -> void:
			if offered and offered.aspect_types:
				var any_matched := false
				for slot in get_aspect_slots():
					if not slot.is_filled and slot.can_be_filled_by(offered.aspect_types):
						any_matched = true
						break
				set_faded_out(not any_matched)
			else:
				set_faded_out(false)
		)

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	assert(data is Card)
	return SlotUtils.match_slot(get_aspect_slots(), (data as Card).card_type.aspects) != null

func _drop_data(_pos: Vector2, data: Variant) -> void:
	assert(data is Card)
	var slot := SlotUtils.match_slot(get_aspect_slots(), (data as Card).card_type.aspects)
	assert(slot)
	slot.card_dropped.emit(data as Card)

func _request_slots() -> void:
	var accepted_aspects: Array[AspectType]
	for slot in get_aspect_slots():
		if not slot.is_filled:
			if slot.is_universal:
				accepted_aspects.assign(AspectType.get_all_types())
				break
			else:
				accepted_aspects.append(slot.aspect_type)
	GlobalContextHighlight.request(ContextHighlight.aspects(self, accepted_aspects))

func _retract_slot_request() -> void:
	GlobalContextHighlight.retract_request(self)

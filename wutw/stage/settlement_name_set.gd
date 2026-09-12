class_name SettlementNameSet
extends Resource

@export var options: Array[SettlementNameOption]

var _index_by_spot: Dictionary[SpotType, Array]  # Array[SettlementNameOption]

func get_options_by_spot(spot_type: SpotType) -> Array:  # [SettlementNameOption]; untyped to avoid copy.
	if _index_by_spot.is_empty():
		# Initialize
		for option in options:
			if option.related_spot not in _index_by_spot:
				_index_by_spot[option.related_spot] = []
			_index_by_spot[option.related_spot].append(option)
	return _index_by_spot[spot_type]

class_name HubPortalNetwork
extends HubFacility

func _ready() -> void:
	super._ready()
	_update()
	GlobalSaveGame.changed.connect(_update)

func _update() -> void:
	if GlobalSaveGame.has_trip_results_pending():
		(%TripResultsPendingLabel as Label).visible = true
	else:
		(%TripResultsPendingLabel as Label).visible = false

func _make_tooltip_text() -> String:
	var result := tr(tooltip_text)
	if GlobalSaveGame.has_trip_results_pending():
		result += '\n\n' + tr('[b]Explorer trip report available![/b]')
	return result

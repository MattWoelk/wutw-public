class_name HubMuseum
extends HubFacility

signal exhibit_clicked(index: int, exhibit: MuseumExhibit)

var _exhibits: Array[MuseumExhibit]

func _ready() -> void:
	super._ready()

	if Utils.is_museum_unlocked():
		var exhibit_assignments := GlobalSaveGame.get_displayed_museum_exhibits()

		var available_images := MuseumExhibit.get_available_images()
		available_images.shuffle()

		_exhibits.assign(%Exhibits.get_children())
		for i in _exhibits.size():
			var exhibit := _exhibits[i]
			exhibit.clicked.connect(_on_exhibit_clicked.bind(exhibit))
			if i in exhibit_assignments:
				exhibit.image = exhibit_assignments[i]
			elif available_images:
				exhibit.image = available_images.pop_back()

func _on_exhibit_clicked(exhibit: MuseumExhibit) -> void:
	exhibit_clicked.emit(_exhibits.find(exhibit), exhibit)

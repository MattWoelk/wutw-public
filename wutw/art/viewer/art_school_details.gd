class_name ArtSchoolDetails
extends Control

@export var art_school: ArtSchool:
	set(value):
		art_school = value
		_update()

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_update()

func _update_font_size() -> void:
	Utils._scale_font_size(%MainTextLabel as RichTextLabel, false, 18)

func _update() -> void:
	if not art_school or not is_node_ready():
		return

	(%NameLabel as Label).text = tr(art_school.name)
	var text := tr(art_school.blurb) + tr('\n\nAssociated Artists:[ul]\n')
	for artist in ArtViewer.get_all_artists():
		if art_school in artist.schools:
			text += '[url=artist:%s]%s[/url]\n' % [artist.name, tr(artist.name)]
	text += '[/ul]'
	(%MainTextLabel as MarkedUpLabel).set_markedup_text(text)
	(%LinkButton as Button).visible = not art_school.link.is_empty()

	(%ArtListing as ArtListing).art_pieces = art_school.get_pieces()

func _on_link_button_pressed() -> void:
	OS.shell_open(art_school.link)

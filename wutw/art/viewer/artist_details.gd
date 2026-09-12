@tool
class_name ArtistDetails
extends Control

@export var artist: Artist:
	set(value):
		artist = value
		_update()

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_update()

func _update_font_size() -> void:
	Utils._scale_font_size(%MainTextLabel as RichTextLabel, false, 18)

func _update() -> void:
	if not artist or not is_node_ready():
		return

	(%NameLabel as Label).text = tr(artist.name)
	if artist.custom_date:
		(%NameLabel as Label).text += tr(' (%s)') % tr(artist.custom_date)
	elif artist.birth_year:
		(%NameLabel as Label).text += tr(' (%d - %d)') % [artist.birth_year, artist.death_year]

	var text := tr(artist.blurb)
	if artist.schools:
		text += '\n\n'
		if artist.schools.size() == 1:
			text += '\n\n'
			text += tr('Associated School:')
			text += ' [url=art_school:{artist_name}]{translated_artist_name}[/url]'.format({
				artist_name=artist.schools[0].name,
				translated_artist_name=tr(artist.schools[0].name),
			})
		else:
			text += '\n\n'
			text += tr('Associated Schools:')
			text += '[ul]\n'
			for art_school in artist.schools:
				text += '[url=art_school:{school_name}]{translated_school_name}[/url]\n'.format({
					artist_name=art_school.name,
					translated_artist_name=tr(art_school.name),
				})
			text += '[/ul]'
	(%MainTextLabel as MarkedUpLabel).set_markedup_text(text)

	(%LinkButton as Button).visible = not artist.link.is_empty()
	if artist.portrait:
		(%Portrait as TextureRect).texture = await artist.portrait.get_texture_async()
	else:
		(%Portrait as TextureRect).texture = null
	(%Portrait as TextureRect).visible = (%Portrait as TextureRect).texture != null

	(%ArtListing as ArtListing).art_pieces = artist.get_pieces()

func _on_link_button_pressed() -> void:
	OS.shell_open(artist.link)

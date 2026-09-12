class_name ArtSeriesDetails
extends Control

@export var art_series: ArtSeries:
	set(value):
		art_series = value
		_update()

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_update()

func _update_font_size() -> void:
	Utils._scale_font_size(%MainTextLabel as RichTextLabel, false, 18)

func _update() -> void:
	if not art_series or not is_node_ready():
		return

	(%NameLabel as Label).text = tr(art_series.name)
	if art_series.artist:
		(%ArtistLabel as MarkedUpLabel).set_markedup_text(
			tr('by [url=artist:%s]%s[/url]') % [art_series.artist.name, tr(art_series.artist.name)])
	else:
		(%ArtistLabel as MarkedUpLabel).set_markedup_text(tr('Unknown Artist'))
	(%MainTextLabel as MarkedUpLabel).set_markedup_text(tr(art_series.blurb))
	(%LinkButton as Button).visible = not art_series.link.is_empty()

	(%ArtListing as ArtListing).art_pieces = art_series.get_pieces()

func _on_link_button_pressed() -> void:
	OS.shell_open(art_series.link)

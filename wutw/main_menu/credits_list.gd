class_name CreditsList
extends VBoxContainer

static var TAG_REGEX := RegEx.create_from_string(r'[\[][^\]]*?[\]]')

@export var text_style: LabelSettings

func _ready() -> void:
	var historical_artists: PackedStringArray
	for artist in ArtViewer.get_all_artists():
		historical_artists.append(tr(artist.name))
		if artist.custom_date:
			historical_artists[-1] += ' (%s)' % tr(artist.custom_date)
		elif artist.birth_year:
			historical_artists[-1] += ' (%d - %d)' % [artist.birth_year, artist.death_year]
	(%HistoricalArtCredits as Label).text = '\n'.join(historical_artists)

	if text_style:
		for child in get_children():
			for label in child.get_children():
				if label is Label:
					(label as Label).label_settings = text_style
				elif label is RichTextLabel:
					(label as RichTextLabel).add_theme_color_override('font_outline_color', text_style.outline_color)
					(label as RichTextLabel).add_theme_constant_override('outline_size', text_style.outline_size)
					var text := tr((label as RichTextLabel).text)
					text = TAG_REGEX.sub(text, '', true)
					(label as RichTextLabel).text = text

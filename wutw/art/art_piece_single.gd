class_name ArtPiece_Single
extends ArtPiece

@export var original_image: LazyTextureResource
@export var piece_name: String
@export var series: ArtSeries
@export var artist: Artist
@export var styles: Array[ArtStyle]
@export var actual_start_year: int
@export var actual_end_year: int
@export var date_type: DateType
@export var custom_link: String
@export var edits_description: String

func get_title() -> String:
	return tr(piece_name)

func get_attribution() -> String:
	var text := tr(piece_name) + ' (' + format_date() + ')\n'
	if artist:
		text += tr(artist.name)
	else:
		text += tr('Unknown Artist')
	if series:
		text += tr('\nSeries: ') + tr(series.name)
	return text

func get_original_image() -> Texture2D:
	if original_image:
		return await original_image.get_texture_async()
	else:
		return null

func format_date() -> String:
	match date_type:
		DateType.EXACT:
			if Utils.ensure(actual_start_year):
				Utils.ensure(not actual_end_year or actual_start_year == actual_end_year)
				return '%d' % actual_start_year
			else:
				return tr('Missing')
		DateType.APPROXIMATE:
			if not Utils.ensure(actual_start_year):
				return tr('Missing')
			if actual_end_year:
				if actual_end_year - actual_start_year == 10 and actual_end_year % 10 == 0:
					return '%ds' % actual_start_year
				elif actual_start_year == actual_end_year:
					return tr('ca. %d') % actual_start_year
				else:
					return tr('ca. %d - %d') % [actual_start_year, actual_end_year]
			else:
				return 'ca. %d' % actual_start_year
		DateType.PERIOD_KAMAKURA:
			return tr('Kamakura Period (1185 - 1334)')
		DateType.PERIOD_MUROMACHI:
			return tr('Muromachi Period (1394 - 1573)')
		DateType.PERIOD_EDO:
			return tr('Edo Period (1603 - 1868)')
		DateType.PERIOD_MEIJI:
			return tr('Meiji Era (1868 - 1912)')
		DateType.PERIOD_TAISHO:
			return tr('Taishō Era (1912 - 1926)')
		DateType.UNKNOWN:
			return tr('Unknown')
		_:
			Utils.ensure(false)
			return tr('Missing')

func get_start_year() -> int:
	match date_type:
		DateType.EXACT, DateType.APPROXIMATE:
			Utils.ensure(actual_start_year)
			return actual_start_year
		DateType.PERIOD_KAMAKURA:
			return 1185
		DateType.PERIOD_MUROMACHI:
			return 1394
		DateType.PERIOD_EDO:
			return 1603
		DateType.PERIOD_MEIJI:
			return 1868
		DateType.PERIOD_TAISHO:
			return 1912
		DateType.UNKNOWN:
			return 0
		_:
			Utils.ensure(false)
			return 0

func get_end_year() -> int:
	match date_type:
		DateType.EXACT, DateType.APPROXIMATE:
			Utils.ensure(actual_start_year)
			return actual_end_year if actual_end_year else actual_start_year
		DateType.PERIOD_KAMAKURA:
			return 1334
		DateType.PERIOD_MUROMACHI:
			return 1573
		DateType.PERIOD_EDO:
			return 1868
		DateType.PERIOD_MEIJI:
			return 1912
		DateType.PERIOD_TAISHO:
			return 1926
		DateType.UNKNOWN:
			return 0
		_:
			Utils.ensure(false)
			return 0

func get_sort_index() -> int:
	return 0

func get_link() -> String:
	if custom_link:
		return custom_link
	else:
		return 'https://ukiyo-e.org/search?q=%s,+%s' % [artist.name.uri_encode() if artist else '', piece_name.uri_encode()]

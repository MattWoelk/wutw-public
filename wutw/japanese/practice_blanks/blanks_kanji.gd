class_name BlanksKanji
extends Label

@export var kanji: String:
	set(value):
		kanji = value
		if is_node_ready():
			_update()
var _solved := false

func _ready() -> void:
	_update()
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func mark_solved() -> void:
	_solved = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	if JapaneseUtils.get_kanji_detail(kanji):
		GlobalTooltipSystem.attach(self, _make_tooltip_text,
				[Tooltip.RelativeDirection.BELOW], [Tooltip.Alignment.CENTERED])

func _update() -> void:
	text = kanji

func _make_tooltip_text() -> String:
	var card_type := CardType.get_card_type_by_name_or_symbol(kanji)
	var title := card_type.card_name if card_type else JapaneseUtils.get_kanji_detail(kanji).meanings[0]
	return tr('[center]Kanji: <jp_font_size>{kanji}[/font_size] - <header_font_size>[b]{title}[/b][/font_size][/center]\n\n').format({
		kanji=kanji, title=tr(title).capitalize()
	}) + JapaneseUtils.get_kanji_detail(kanji).get_dictionary_tooltip()

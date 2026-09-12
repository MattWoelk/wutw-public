@tool
class_name KanjiSlot
extends PanelContainer

@export var universal_probability: float = 0.1
@export var kanji: String:
	set(value):
		kanji = value
		if is_node_ready():
			_update()

var _filled := false

func _ready() -> void:
	_update()

func _update() -> void:
	if not kanji:
		return
	assert(kanji.length() == 1)
	assert(not _filled)

	(%Label as Label).text = kanji
	(%Label as Label).modulate.a = 0

	var card_type := CardType.get_card_type_by_name_or_symbol(kanji)
	if not card_type.aspects or randf() < universal_probability:
		(%AspectSlot as AspectSlot).is_universal = true
	else:
		(%AspectSlot as AspectSlot).is_universal = false
		(%AspectSlot as AspectSlot).aspect_type = card_type.aspects[randi_range(0, card_type.aspects.size() - 1)]

func is_filled() -> bool:
	return _filled

func fill() -> void:
	_filled = true
	await (%AspectSlot as AspectSlot).animate_fill()
	var tween := create_tween()
	tween.tween_property(%AspectSlot, 'modulate:a', 0, 1.0)
	tween.parallel().tween_property(%Label, 'modulate:a', 1.0, 1.0)
	tween.set_speed_scale(Utils.anim_speed())
	(%AspectSlot as AspectSlot).visible = false
	mouse_filter = Control.MOUSE_FILTER_PASS
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.BELOW], [Tooltip.Alignment.CENTERED])
	await tween.finished

func get_aspect_slot() -> AspectSlot:
	return %AspectSlot as AspectSlot

func _make_tooltip_text() -> String:
	var title := CardType.get_card_type_by_name_or_symbol(kanji).card_name
	return tr('[center]Kanji: <jp_font_size>{kanji}[/font_size] - <header_font_size>[b]{title}[/b][/font_size][/center]\n\n'.format({
		kanji=kanji, title=tr(title)
	}) + JapaneseUtils.get_kanji_detail(kanji).get_dictionary_tooltip())

@tool
class_name MuseumDetail_HistoricalRecord
extends Control

signal cutscene_started
signal cutscene_finished

@export var historical_record: HistoricalRecord:
	set(value):
		if historical_record == value:
			return
		historical_record = value
		if is_node_ready():
			_recreate()

var _current_page: int = 0

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_recreate()

func _update_font_size() -> void:
	Utils._scale_font_size(%MainText as RichTextLabel, false, 18)

func _recreate() -> void:
	if not historical_record:
		return

	(%TitleLabel as Label).text = tr(historical_record.name)
	if historical_record.pages:
		(%VBox_Pages as Control).visible = true
		(%VBox_Cutscene as Control).visible = false
		_current_page = 0
		_update_page()
	else:
		(%VBox_Pages as Control).visible = false
		(%VBox_Cutscene as Control).visible = true
		(%Illustration as TextureRect).texture = await historical_record.cutscene_cover.get_texture_async()

	if Utils.get_active_run():
		(%Button_Watch as Button).disabled = true
		GlobalTooltipSystem.attach(%Button_Watch as Button, func() -> String:
			return tr('Cutscenes can be rewatched in the <term:hub>.')
		, [Tooltip.RelativeDirection.ABOVE], [Tooltip.Alignment.CENTERED])

func _on_button_prev_pressed() -> void:
	_current_page = clamp(_current_page - 1, 0, historical_record.pages.size() - 1)
	_update_page()

func _on_button_next_pressed() -> void:
	_current_page = clamp(_current_page + 1, 0, historical_record.pages.size() - 1)
	_update_page()

func _update_page() -> void:
	(%MainText as MarkedUpLabel).set_markedup_text(
		tr(historical_record.pages[_current_page]), MarkedUpLabel.LinkMode.LINK)
	(%PageLabel as Label).text = tr('Page %d of %d') % [_current_page + 1, historical_record.pages.size()]
	(%Button_Prev as Button).visible = _current_page > 0
	(%Button_Next as Button).visible = _current_page < historical_record.pages.size() - 1

func _on_button_watch_pressed() -> void:
	var cutscene := (load(historical_record.cutscene_path) as PackedScene).instantiate() as Cutscene_Slideshow
	cutscene.preview_mode = true
	cutscene.finished.connect(func() -> void:
		cutscene_finished.emit()
		cutscene.queue_free()
		GlobalUI.show_loading_transition(UI.TransitionType.FADE_TO_BLACK)
	)
	GlobalUI.add_layer_content(cutscene, UI.Layer.CUTSCENE)
	GlobalUI.show_loading_transition(UI.TransitionType.FADE_TO_BLACK)
	cutscene_started.emit()

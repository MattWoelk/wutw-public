class_name ArtQuiz
extends Control

enum QuestionType { ARTIST, TITLE, STYLE, SERIES, TIME, PLACE }

const SCORE_PER_CORRECT := 0.3
const MAX_DATE_ERROR := 30
const MAX_DIST_ERROR := 30

@export var meisho_style: ArtStyle

var _rng := RandomState.new()
var _all_styles: Array[ArtStyle]
var _all_artists: Array[Artist]
var _all_series: Array[ArtSeries]
var _all_pieces: Array[ArtPiece_Single]

var _remaining_pieces: Array[ArtPiece_Single]
var _art_piece: ArtPiece_Single

func _ready() -> void:
	_all_artists = ArtViewer.get_all_artists()
	_all_styles = ArtViewer.get_all_styles()
	_all_series = ArtViewer.get_all_series()
	for piece in ArtViewer.get_all_pieces():
		if piece is ArtPiece_Single:
			_all_pieces.append(piece)
	_reshuffle_pieces()

	(%IntroBox as Control).visible = true
	(%QuestionBox as Control).visible = false
	(%IntroLabel as MarkedUpLabel).set_markedup_text(tr((%IntroLabel as MarkedUpLabel).text))

	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)

func _update_font_size() -> void:
	Utils._scale_font_size(%IntroLabel as RichTextLabel, false, 18)
	Utils._scale_font_size(%QuestionLabel as RichTextLabel, false, 18)

func _on_start_button_pressed() -> void:
	(%IntroBox as Control).mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	(%StartButton as Button).disabled = true

	var tween := create_tween()
	tween.tween_property(%IntroBox, 'modulate:a', 0.0, 0.7)
	tween.set_speed_scale(Utils.anim_speed())
	tween.play()
	await tween.finished
	(%IntroBox as Control).visible = false

	_setup_next_question()

	await _reveal_question()

func _setup_next_question() -> void:
	(%AnswerLabel as Control).visible = false
	(%NextButton as Control).visible = false

	if not _remaining_pieces:
		_reshuffle_pieces()
	_art_piece = _remaining_pieces.pop_back()

	var type_options: Array[QuestionType]
	type_options.append(QuestionType.TITLE)
	if _art_piece.artist:
		type_options.append(QuestionType.ARTIST)
		type_options.append(QuestionType.ARTIST)
	if _art_piece.styles:
		type_options.append(QuestionType.STYLE)
	if _art_piece.series:
		type_options.append(QuestionType.SERIES)
	if _art_piece.date_type != ArtPiece.DateType.UNKNOWN:
		type_options.append(QuestionType.TIME)
		type_options.append(QuestionType.TIME)
	if _art_piece.province and meisho_style in _art_piece.styles:
		type_options.append(QuestionType.PLACE)
		type_options.append(QuestionType.PLACE)
		type_options.append(QuestionType.PLACE)
		type_options.append(QuestionType.PLACE)

	for child: Control in %QuestionSwitcher.get_children():
		child.visible = false

	var question_type: QuestionType = _rng.pick(type_options)
	match question_type:
		QuestionType.TITLE: _setup_question_title()
		QuestionType.ARTIST: _setup_question_artist()
		QuestionType.STYLE: _setup_question_style()
		QuestionType.SERIES: _setup_question_series()
		QuestionType.TIME: _setup_question_time()
		QuestionType.PLACE: _setup_question_place()

	await _update_image()

func _setup_question_title() -> void:
	(%QuestionLabel as MarkedUpLabel).set_markedup_text(
		tr('What is the [b]title[/b] of this piece?'))

	(%Question_Title as Control).visible = true
	var correct := _art_piece.piece_name
	var weighted_options: Dictionary[String, float]
	for piece in _all_pieces:
		if piece.piece_name != correct:
			var weight := 1.0
			for style in _art_piece.styles:
				if style in piece.styles:
					weight *= 100.0
			weighted_options[piece.piece_name] = weight
	var options: Array[String]
	options.append(correct)
	options.append_array(_rng.pick_weighted_dict(weighted_options, 3))
	_rng.shuffle(options)
	Utils.clear_node(%Question_Title as Control)
	for option in options:
		var button := UkiyoeButton.new()
		button.text = tr(option)
		button.pressed.connect(_finish_question_title.bind(button))
		%Question_Title.add_child(button)

func _finish_question_title(clicked_button: Button) -> void:
	for button: Button in %Question_Title.get_children():
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.disabled = button != clicked_button

	var answer_text: String
	if clicked_button.text == _art_piece.piece_name:
		answer_text = tr('[color=#006000]Correct![/color]')
		_mark_correct()
	else:
		answer_text = tr('[color=#600000]Incorrect.[/color]')
	answer_text += tr('\n\nThis is {art_piece_description}.').format({
		art_piece_description=_describe_current_piece()})
	(%AnswerLabel as MarkedUpLabel).set_markedup_text(answer_text)

	(%AnswerLabel as Control).visible = true
	(%NextButton as Control).visible = true

func _setup_question_artist() -> void:
	(%QuestionLabel as MarkedUpLabel).set_markedup_text(
		tr('Who is the [b]artist[/b] of this piece?'))

	(%Question_Artist as Control).visible = true
	var correct := _art_piece.artist.name
	var options: Array[String]
	options.append(correct)
	for artist: Artist in _rng.pick_n(_all_artists, 4):
		if options.size() < 4 and artist.name != correct:
			options.append(artist.name)
	_rng.shuffle(options)
	Utils.clear_node(%Question_Artist as Control)
	for option in options:
		var button := UkiyoeButton.new()
		button.text = tr(option)
		button.pressed.connect(_finish_question_artist.bind(button))
		%Question_Artist.add_child(button)

func _finish_question_artist(clicked_button: Button) -> void:
	for button: Button in %Question_Artist.get_children():
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.disabled = button != clicked_button

	var answer_text: String
	if clicked_button.text == _art_piece.artist.name:
		answer_text = tr('[color=#006000]Correct![/color]')
		_mark_correct()
	else:
		answer_text = tr('[color=#600000]Incorrect.[/color]')
	answer_text += tr('\n\nThis is {art_piece_description}.').format({
		art_piece_description=_describe_current_piece()})
	(%AnswerLabel as MarkedUpLabel).set_markedup_text(answer_text)

	(%AnswerLabel as Control).visible = true
	(%NextButton as Control).visible = true

func _setup_question_style() -> void:
	(%QuestionLabel as MarkedUpLabel).set_markedup_text(
		tr('What is the [b]style[/b] of this piece?'))

	(%Question_Style as Control).visible = true
	var correct := _art_piece.styles[0].name
	var options: Array[String]
	options.append(correct)
	for style: ArtStyle in _rng.pick_n(_all_styles, 8):
		if options.size() < 4 and style not in _art_piece.styles:
			options.append(style.name)
	_rng.shuffle(options)
	Utils.clear_node(%Question_Style as Control)
	for option in options:
		var button := UkiyoeButton.new()
		button.text = tr(option)
		button.pressed.connect(_finish_question_style.bind(button))
		%Question_Style.add_child(button)

func _finish_question_style(clicked_button: Button) -> void:
	for button: Button in %Question_Style.get_children():
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.disabled = button != clicked_button

	var answer_text: String
	if clicked_button.text == _art_piece.styles[0].name:
		answer_text = tr('[color=#006000]Correct![/color]')
		_mark_correct()
	else:
		answer_text = tr('[color=#600000]Incorrect.[/color]')
	answer_text += tr('\n\nThis is an example of [url=art_style:{name}]{translated_name}[/url]. It is {art_piece_description}.').format({
		name=_art_piece.styles[0].name,
		translated_name=tr(_art_piece.styles[0].name),
		art_piece_description=_describe_current_piece(),
		})
	(%AnswerLabel as MarkedUpLabel).set_markedup_text(answer_text)

	(%AnswerLabel as Control).visible = true
	(%NextButton as Control).visible = true

func _setup_question_series() -> void:
	(%QuestionLabel as MarkedUpLabel).set_markedup_text(
		tr('What [b]series[/b] does this piece belong to?'))

	(%Question_Series as Control).visible = true
	var correct := _art_piece.series.name
	var options: Array[String]
	options.append(correct)
	for series: ArtSeries in _rng.pick_n(_all_series, 4):
		if options.size() < 4 and series.name != correct:
			options.append(series.name)
	_rng.shuffle(options)
	Utils.clear_node(%Question_Series as Control)
	for option in options:
		var button := UkiyoeButton.new()
		button.text = tr(option)
		button.pressed.connect(_finish_question_series.bind(button))
		%Question_Series.add_child(button)

func _finish_question_series(clicked_button: Button) -> void:
	for button: Button in %Question_Series.get_children():
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.disabled = button != clicked_button

	var answer_text: String
	if clicked_button.text == _art_piece.series.name:
		answer_text = tr('[color=#006000]Correct![/color]')
		_mark_correct()
	else:
		answer_text = tr('[color=#600000]Incorrect.[/color]')
	answer_text += tr('\n\nThis is {art_piece_description}. It is part of the series [url="art_series:{series}"]{translated_series}[/url].').format({
		art_piece_description=_describe_current_piece(),
		series=_art_piece.series.name,
		translated_series=tr(_art_piece.series.name),
	})
	(%AnswerLabel as MarkedUpLabel).set_markedup_text(answer_text)

	(%AnswerLabel as Control).visible = true
	(%NextButton as Control).visible = true

func _setup_question_time() -> void:
	(%QuestionLabel as MarkedUpLabel).set_markedup_text(
		tr('[b]When[/b] was this piece published?'))

	(%Question_Date as Control).visible = true
	(%DateSlider as Slider).value = 800
	(%DateConfirmButton as Button).disabled = false

func _on_date_confirm_button_pressed() -> void:
	(%DateConfirmButton as Button).disabled = true
	var guess := roundi((%DateSlider as Slider).value)
	var error: float
	if guess >= _art_piece.get_start_year() and guess <= _art_piece.get_end_year():
		error = 0.0
	else:
		var dist_from_start := absi(_art_piece.get_start_year() - guess)
		var dist_from_end := absi(guess - _art_piece.get_end_year())
		error = mini(dist_from_start, dist_from_end)
	var error_normalized := float(error) / MAX_DATE_ERROR

	var answer_text: String
	if error_normalized <= 0:
		answer_text = tr('[color=#006000]Correct![/color]')
		_mark_correct()
	elif error_normalized < 1.0:
		answer_text = tr('[color=#805000]Close![/color]')
		_mark_correct(error_normalized)
	else:
		answer_text = tr('[color=#600000]Incorrect.[/color]')
	answer_text += tr('\n\nThis is {art_piece_description}. It was published in {date}.').format({
		art_piece_description=_describe_current_piece(),
		date=_art_piece.format_date()
	})
	(%AnswerLabel as MarkedUpLabel).set_markedup_text(answer_text)

	(%AnswerLabel as Control).visible = true
	(%NextButton as Control).visible = true

func _setup_question_place() -> void:
	(%QuestionLabel as MarkedUpLabel).set_markedup_text(
		tr('[b]Where[/b] is the depicted scene?'))

	(%Question_Place as Control).visible = true
	(%Question_Place as Control).mouse_filter = Control.MOUSE_FILTER_STOP
	(%JapanMap as JapanMap).selected_provice = JapanProvinceArea.Province.UNSPECIFIED
	(%JapanMap as JapanMap).clicked.connect(_on_japan_map_clicked, CONNECT_ONE_SHOT)

func _on_japan_map_clicked(map_location: Vector2) -> void:
	(%Question_Place as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

	var japan_map := %JapanMap as JapanMap
	var dist := japan_map.get_distance_to(map_location, _art_piece.province)
	japan_map.selected_provice = _art_piece.province

	var error_normalized := float(dist) / MAX_DIST_ERROR

	var answer_text: String
	if error_normalized <= 0:
		answer_text = tr('[color=#006000]Correct![/color]')
		_mark_correct()
	elif error_normalized < 1.0:
		answer_text = tr('[color=#805000]Close![/color]')
		_mark_correct(error_normalized)
	else:
		answer_text = tr('[color=#600000]Incorrect.[/color]')
	answer_text += tr('\n\nThis is {art_piece_description}. It depicts {province}.').format({
		art_piece_description=_describe_current_piece(),
		province=JapanProvinceArea.new().get_province_label(_art_piece.province).replace('\n', ', ')
	})
	(%AnswerLabel as MarkedUpLabel).set_markedup_text(answer_text)

	(%AnswerLabel as Control).visible = true
	(%NextButton as Control).visible = true

func _mark_correct(correctness: float = 1.0) -> void:
	GlobalAudioSystem.play(AK.EVENTS.UI_GAMEPLAY_NONGOALYIELD_GAIN)
	var score_panel := %InsightsScore as PracticeInsightsScore
	var score_before := floori(score_panel.score)
	score_panel.score += SCORE_PER_CORRECT * correctness
	if score_before != floori(score_panel.score):
		GlobalSaveGame.insights += 1

func _reveal_question() -> void:
	(%QuestionBox as Control).modulate.a = 0.0
	(%QuestionBox as Control).visible = true
	var tween := create_tween()
	tween.tween_property(%QuestionBox, 'modulate:a', 1.0, 0.7)
	tween.set_speed_scale(Utils.anim_speed())
	tween.play()
	await tween.finished

func _reshuffle_pieces() -> void:
	for piece in _all_pieces:
		if piece.original_image:
			_remaining_pieces.append(piece)
	_rng.shuffle(_remaining_pieces)

func _update_image() -> void:
	if not Utils.ensure(_art_piece != null):
		return
	(%PieceImage as TextureRect).texture = await _art_piece.get_original_image()

func _on_next_button_pressed() -> void:
	(%QuestionBox as Control).mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	(%NextButton as Button).disabled = true

	var tween := create_tween()
	tween.tween_property(%QuestionBox, 'modulate:a', 0.0, 0.7)
	tween.set_speed_scale(Utils.anim_speed())
	tween.play()
	await tween.finished

	_setup_next_question()

	(%QuestionBox as Control).mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
	(%NextButton as Button).disabled = false

	await _reveal_question()

func _on_date_slider_value_changed(value: float) -> void:
	(%DateLabel as Label).text = str(roundi(value))

func _describe_current_piece() -> String:
	var result := tr('[url="art_piece:{name}"]{translated_name}[/url]').format({
		name=_art_piece.piece_name.replace('"', "'"),
		translated_name=tr(_art_piece.piece_name),
	})
	if _art_piece.artist:
		result += tr(' by [url=artist:{artist}]{translated_artist}[/url]').format({
			artist=_art_piece.artist.name,
			translated_artist=tr(_art_piece.artist.name),
		})
	return result

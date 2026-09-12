class_name ArtViewer
extends Node2D

signal closed

static var _group_loader := AsyncLoadedGroup.new('res://art/resourcegroup_art.tres', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var ART_VIEWER_SCENE := AsyncLoadedResource.new('res://art/viewer/art_viewer.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

static var _all_pieces: Array[ArtPiece] = []
static var _all_artists: Array[Artist] = []
static var _all_series: Array[ArtSeries] = []
static var _all_schools: Array[ArtSchool] = []
static var _all_styles: Array[ArtStyle] = []
static var _active_viewer: ArtViewer  # Singleton - needed for handling links.

var _initial_resource_to_open: Resource

@onready var _tabs_button_group: ButtonGroup = (%TabButton_Pieces as Button).button_group
@onready var _timeline := %ArtTimeline as ArtTimeline
var _closing := false
var _last_selected: Dictionary[BaseButton, Resource]  # Tab button -> resource (art piece, etc.)
var _history: Array[Resource]  # For back/forward.
var _history_offset: int = 0  # For back/forward.

static func get_all_pieces() -> Array[ArtPiece]:
	_load_resources()
	return _all_pieces

static func get_all_series() -> Array[ArtSeries]:
	_load_resources()
	return _all_series

static func get_all_artists() -> Array[Artist]:
	_load_resources()
	return _all_artists

static func get_all_schools() -> Array[ArtSchool]:
	_load_resources()
	return _all_schools

static func get_all_styles() -> Array[ArtStyle]:
	_load_resources()
	return _all_styles

static func open_link(query: String) -> Resource:
	var candidates: Array
	var get_title: Callable
	var pieces := query.split(':', true, 1)
	match pieces[0]:
		'art_piece':
			candidates = _all_pieces
			get_title = func(piece: ArtPiece) -> String: return piece.get_title()
		'artist':
			candidates = _all_artists
			get_title = func(artist: Artist) -> String: return artist.name
		'art_series':
			candidates = _all_series
			get_title = func(series: ArtSeries) -> String: return series.name
		'art_school':
			candidates = _all_schools
			get_title = func(school: ArtSchool) -> String: return school.name
		'art_style':
			candidates = _all_styles
			get_title = func(style: ArtStyle) -> String: return style.name

	var query_terms := Utils.parse_search_query(pieces[1])
	var best_score := -1.0
	var best_candidate: Resource
	for candidate: Resource in candidates:
		var score := _score_query(query_terms, get_title.call(candidate) as String)
		if score > best_score:
			best_score = score
			best_candidate = candidate
		elif score >= 0.9:
			push_warning('Multiple matches for art query: ', query)
	if best_candidate:
		if best_score <= 0.5:
			push_warning('Weak match for art query: ', query)
		open_art_resource(best_candidate)
		return best_candidate
	else:
		push_warning('No matches for art query: ', query)
		return null

static func open_art_resource(resource: Resource) -> void:
	if _active_viewer:
		if resource:
			_active_viewer._select_query_result(resource)
	else:
		var viewer := ART_VIEWER_SCENE.instantiate_loaded_scene() as ArtViewer
		viewer._initial_resource_to_open = resource
		await GlobalUI.get_tree().process_frame  # Spread load across frames.
		GlobalUI.add_layer_content(viewer, UI.Layer.MODAL)

static func get_active_instance() -> ArtViewer:
	return _active_viewer

func _ready() -> void:
	_load_resources()

	(%BackButton as Button).visible = false
	(%ForwardButton as Button).visible = false

	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	(%IntroTextLabel as MarkedUpLabel).set_markedup_text(
		tr((%IntroTextLabel as MarkedUpLabel).text))  # Parse

	_tabs_button_group.pressed.connect(_on_tab_button_pressed)

	# HACK: Spread load between frames.
	get_tree().process_frame.connect(func() -> void:
		if _initial_resource_to_open:
			_select_query_result(_initial_resource_to_open)
			_initial_resource_to_open = null
		else:
			(%TabButton_Intro as Button).button_pressed = true  # Doesn't emit pressed.
			_on_tab_button_pressed(null)
	, CONNECT_ONE_SHOT)

	await (%ScrollPanel as ScrollPanel).animate_unroll()

	# If we got here, we must've clicked a credits icon.
	await GlobalStartup.wait_loaded_normal()
	GlobalTutorialSystem.get_tutorial(Tutorial_ArtCredits).mark_skipped()
	var viewer_tutorial := (GlobalTutorialSystem.get_tutorial(Tutorial_ArtViewer_Run)
							if Utils.get_active_run() else GlobalTutorialSystem.get_tutorial(Tutorial_ArtViewer_Hub))
	if not viewer_tutorial.is_skipped():
		viewer_tutorial.ready_to_trigger.emit()

func _enter_tree() -> void:
	Utils.ensure(not _active_viewer)
	_active_viewer = self

func _exit_tree() -> void:
	Utils.ensure(_active_viewer != null)
	_active_viewer = null

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_XBUTTON1 and mouse_event.pressed:
			_on_back_button_pressed()
		elif mouse_event.button_index == MOUSE_BUTTON_XBUTTON2 and mouse_event.pressed:
			_on_forward_button_pressed()

func _handle_esc() -> bool:
	if (%ArtPieceDetails as ArtPieceDetails).is_in_fullscreen_preview():
		(%ArtPieceDetails as ArtPieceDetails).hide_fullscreen()
	else:
		_close()
	return true

func _update_font_size() -> void:
	Utils._scale_font_size(%IntroTextLabel as RichTextLabel, false, 16)

func _on_close_button_pressed() -> void:
	_close()

func _close() -> void:
	if not _closing:
		_closing = true
		if (%ArtPieceDetails as ArtPieceDetails).is_in_fullscreen_preview():
			(%ArtPieceDetails as ArtPieceDetails).hide_fullscreen()
		(%ArtPieceDetails as ArtPieceDetails).preview_enabled = false
		Utils.set_input_enabled(%ScrollPanel as ScrollPanel, false)
		(%BG as FadedBackground).fade_out()
		await (%ScrollPanel as ScrollPanel).animate_roll()
		closed.emit()
		queue_free()

func _on_tab_button_pressed(_button: BaseButton) -> void:
	var pressed_button := _tabs_button_group.get_pressed_button()
	var tab: Control
	if pressed_button == %TabButton_Intro:
		Utils.clear_node(%EntriesList)
		tab = %IntroTab
		_timeline.start_year = 0
		_timeline.end_year = 0
	elif pressed_button == %TabButton_Pieces:
		_fill_list(pressed_button, _all_pieces, _on_piece_selected,
				   func(piece: ArtPiece) -> String: return piece.get_title())
		tab = %ArtPieceDetails
	elif pressed_button == %TabButton_Series:
		_fill_list(pressed_button, _all_series, _on_series_selected, func(series: ArtSeries) -> String:
			return '[%d] %s' % [series.get_pieces().size(), tr(series.name)]
		)
		tab = %ArtSeriesDetails
	elif pressed_button == %TabButton_Artists:
		_fill_list(pressed_button, _all_artists, _on_artist_selected, func(artist: Artist) -> String:
			return '[%d] %s' % [artist.get_pieces().size(), tr(artist.name)]
		)
		tab = %ArtistDetails
	elif pressed_button == %TabButton_Schools:
		_fill_list(pressed_button, _all_schools, _on_school_selected, func(school: ArtSchool) -> String:
			return '[%d] %s' % [school.get_pieces().size(), tr(school.name)]
		)
		tab = %ArtSchoolDetails
	elif pressed_button == %TabButton_Styles:
		_fill_list(pressed_button, _all_styles, _on_style_selected, func(style: ArtStyle) -> String:
			return '[%d] %s' % [style.get_pieces().size(), tr(style.name)]
		)
		tab = %ArtStyleDetails
	elif pressed_button == %TabButton_Quiz:
		Utils.clear_node(%EntriesList)
		tab = %ArtQuiz
		_timeline.start_year = 0
		_timeline.end_year = 0
		_add_to_history(null)  # HACK
	else:
		assert(false)

	(%Panel_EntriesList as Control).visible = tab != %ArtQuiz

	for child: Control in %DetailsScroller.get_children():
		child.visible = child == tab
	(%DetailsScroller as ScrollContainer).scroll_vertical = 0

func _fill_list(tab_button: BaseButton, entries: Array, on_select: Callable, get_title: Callable) -> void:
	(%EntriesList as VBoxContainer).process_mode = Node.PROCESS_MODE_DISABLED
	Utils.clear_node(%EntriesList)
	var group := ButtonGroup.new()
	var to_select := _last_selected.get(tab_button) as Resource
	var button_to_select: Button
	for entry: Resource in entries:
		if not to_select:
			to_select = entry
		var button := UkiyoeButton.new()
		button.text = get_title.call(entry)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.pressed.connect(on_select.bind(entry))
		button.button_group = group
		button.button_pressed = to_select == entry
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS_FORCE
		button.set_meta('entry', entry)
		%EntriesList.add_child(button)
		if to_select == entry:
			button_to_select = button
	(%EntriesList as VBoxContainer).process_mode = Node.PROCESS_MODE_INHERIT
	on_select.call(to_select)
	_apply_search()
	await get_tree().process_frame
	if button_to_select:
		(%EntriesScroller as ScrollContainer).ensure_control_visible(button_to_select)

func _on_piece_selected(piece: ArtPiece) -> void:
	(%ArtPieceDetails as ArtPieceDetails).art_piece = piece
	_last_selected[%TabButton_Pieces as Button] = piece
	_timeline.start_year = piece.get_start_year()
	_timeline.end_year = piece.get_end_year()
	_add_to_history(piece)
	(%DetailsScroller as ScrollContainer).scroll_vertical = 0

func _on_series_selected(series: ArtSeries) -> void:
	(%ArtSeriesDetails as ArtSeriesDetails).art_series = series
	_last_selected[%TabButton_Series as Button] = series
	_timeline.start_year = series.start_year
	_timeline.end_year = series.end_year
	_add_to_history(series)
	(%DetailsScroller as ScrollContainer).scroll_vertical = 0

func _on_artist_selected(artist: Artist) -> void:
	(%ArtistDetails as ArtistDetails).artist = artist
	_last_selected[%TabButton_Artists as Button] = artist
	_timeline.start_year = artist.birth_year
	_timeline.end_year = artist.death_year
	_add_to_history(artist)
	(%DetailsScroller as ScrollContainer).scroll_vertical = 0

func _on_school_selected(school: ArtSchool) -> void:
	(%ArtSchoolDetails as ArtSchoolDetails).art_school = school
	_last_selected[%TabButton_Schools as Button] = school
	_timeline.start_year = school.start_year
	_timeline.end_year = school.end_year
	_add_to_history(school)
	(%DetailsScroller as ScrollContainer).scroll_vertical = 0

func _on_style_selected(style: ArtStyle) -> void:
	(%ArtStyleDetails as ArtStyleDetails).art_style = style
	_last_selected[%TabButton_Styles as Button] = style
	_timeline.start_year = style.start_year
	_timeline.end_year = style.end_year
	_add_to_history(style)
	(%DetailsScroller as ScrollContainer).scroll_vertical = 0

func _add_to_history(resource: Resource) -> void:
	if _history and _history.back() == resource:
		return
	while _history_offset > 0:
		_history.pop_back()
		_history_offset -= 1
	_history.append(resource)
	(%BackButton as Button).visible = _history.size() > _history_offset + 1
	(%ForwardButton as Button).visible = false

func _select_query_result(result: Resource) -> void:
	var button: BaseButton
	if result is ArtPiece:
		button = %TabButton_Pieces
	elif result is Artist:
		button = %TabButton_Artists
	elif result is ArtSeries:
		button = %TabButton_Series
	elif result is ArtSchool:
		button = %TabButton_Schools
	elif result is ArtStyle:
		button = %TabButton_Styles
	elif not result:
		button = %TabButton_Quiz
	else:
		assert(false)
	_last_selected[button] = result
	button.button_pressed = true
	_on_tab_button_pressed(null)

static func _score_query(query_terms: Array[String], haystack: String) -> float:
	haystack = haystack.replace('ō', 'o').replace('ū', 'u')
	var matched := 0.0
	var total := 0.0
	for query_term in query_terms:
		total += query_term.length()
		var pos := haystack.findn(query_term)
		if pos == -1:
			continue
		if pos > 0:
			var ascii := haystack.unicode_at(pos - 1)
			if (ascii >= 65 and ascii <= 90) or (ascii >= 97 and ascii <= 122) or (ascii >= 48 and ascii <= 57):  # ASCII letter/number
				continue
		if pos + query_term.length() < haystack.length():
			var ascii := haystack.unicode_at(pos + query_term.length())
			if (ascii >= 65 and ascii <= 90) or (ascii >= 97 and ascii <= 122) or (ascii >= 48 and ascii <= 57):  # ASCII letter/number
				continue
		matched += query_term.length()
	var unmatched := total - matched
	return matched / haystack.length() - unmatched / haystack.length()

static func _load_resources() -> void:
	if _all_pieces:
		return
	for resource in _group_loader.get_loaded():
		if resource is ArtPiece:
			if resource is ArtPiece_Placeholder or resource is ArtPiece_None:
				continue
			_all_pieces.append(resource)
		elif resource is Artist:
			_all_artists.append(resource)
		elif resource is ArtSeries:
			_all_series.append(resource)
		elif resource is ArtSchool:
			_all_schools.append(resource)
		elif resource is ArtStyle:
			_all_styles.append(resource)
		else:
			Utils.ensure(false)
	# Sort
	_all_pieces.sort_custom(func(a: ArtPiece, b: ArtPiece) -> bool:
		if a.get_sort_index() != b.get_sort_index():
			return a.get_sort_index() < b.get_sort_index()
		elif a.get_start_year() != b.get_start_year():
			return a.get_start_year() < b.get_start_year()
		else:
			return a.get_title() < b.get_title()
	)
	_all_artists.sort_custom(func(a: Artist, b: Artist) -> bool:
		if a.birth_year and not b.birth_year:
			return false
		if not a.birth_year and b.birth_year:
			return true
		else:
			return a.birth_year < b.birth_year
	)
	_all_series.sort_custom(func(a: ArtSeries, b: ArtSeries) -> bool:
		return a.start_year < b.start_year
	)
	_all_schools.sort_custom(func(a: ArtSchool, b: ArtSchool) -> bool:
		return a.start_year < b.start_year
	)
	_all_styles.sort_custom(func(a: ArtStyle, b: ArtStyle) -> bool:
		return a.start_year < b.start_year
	)

func _on_back_button_pressed() -> void:
	if _history.size() > _history_offset + 1:
		var history_copy := _history.duplicate()
		var cur_history_offset := _history_offset + 1
		_select_query_result(_history[-1 - cur_history_offset])
		_history = history_copy
		_history_offset = cur_history_offset
		(%BackButton as Button).visible = _history.size() > _history_offset + 1
		(%ForwardButton as Button).visible = true

func _on_forward_button_pressed() -> void:
	if _history_offset > 0:
		var history_copy := _history.duplicate()
		var cur_history_offset := _history_offset - 1
		_select_query_result(_history[-1 - cur_history_offset])
		_history = history_copy
		_history_offset = cur_history_offset
		(%BackButton as Button).visible = true
		(%ForwardButton as Button).visible = _history_offset > 0

func _on_back_button_mouse_entered() -> void:
	(%BackButton as Button).modulate = Color(0.424, 0.0, 0.0)

func _on_back_button_mouse_exited() -> void:
	(%BackButton as Button).modulate = Color(0.129, 0.059, 0.004)

func _on_forward_button_mouse_entered() -> void:
	(%ForwardButton as Button).modulate = Color(0.424, 0.0, 0.0)

func _on_forward_button_mouse_exited() -> void:
	(%ForwardButton as Button).modulate = Color(0.129, 0.059, 0.004)

func _on_search_input_text_changed(_new_text: String) -> void:
	_apply_search()

func _apply_search() -> void:
	for button: Button in %EntriesList.get_children():
		var exhibit := button.get_meta('entry') as Resource
		button.visible = Utils.matches_query(_extract_text(exhibit), (%SearchInput as LineEdit).text)

func _extract_text(exhibit: Resource) -> Array[String]:
	var result: Array[String]
	if exhibit is ArtPiece:
		var piece := exhibit as ArtPiece
		result.append(piece.get_attribution())
		result.append(tr(piece.blurb))
	elif exhibit is Artist:
		var artist := exhibit as Artist
		result.append(tr(artist.name))
		result.append(tr(artist.blurb))
		for school in artist.schools:
			result.append(tr(school.name))
	elif exhibit is ArtSeries:
		var series := exhibit as ArtSeries
		result.append(tr(series.name))
		result.append(tr(series.blurb))
		if series.artist:
			result.append(tr(series.artist.name))
	elif exhibit is ArtSchool:
		var school := exhibit as ArtSchool
		result.append(tr(school.name))
		result.append(tr(school.blurb))
		for artist in ArtViewer.get_all_artists():
			if school in artist.schools:
				result.append(tr(artist.name))
	elif exhibit is ArtStyle:
		var style := exhibit as ArtStyle
		result.append(tr(style.name))
		result.append(tr(style.blurb))
	else:
		Utils.ensure(false)
	for i in result.size():
		result[i] = result[i].replace('ō', 'o').replace('ū', 'u')
	return result

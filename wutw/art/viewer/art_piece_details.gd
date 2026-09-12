@tool
class_name ArtPieceDetails
extends Control

const MINIMUM_MAGNIFICATION := 1.25

@export var art_piece: ArtPiece:
	set(value):
		art_piece = value
		preview_enabled = false
		_update()
@export var preview_enabled: bool = true:
	set(value):
		preview_enabled = value
		if is_node_ready():
			(%ZoomButton as Control).modulate.a = 1.0 if preview_enabled else 0.4

var _update_index := 0
var _initial_zoom_pressed := false

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_update()
	(%ZoomPreview as Sprite2D).z_index = Utils.get_absolute_z_index(self)

func _update_font_size() -> void:
	Utils._scale_font_size(%MainTextLabel as RichTextLabel, false, 18)

func _process(_delta: float) -> void:
	if Utils.is_in_editor():
		return

	var preview := %ZoomPreview as Sprite2D
	if not preview_enabled:
		preview.visible = false
		return

	preview.global_position = get_global_mouse_position()
	var image: TextureRect
	if (%HorizontalImage as Control).visible:
		image = %HorizontalImage
	elif (%VerticalImage as Control).visible:
		image = %VerticalImage
	if image:
		var offset := preview.global_position - image.global_position
		var image_size := image.get_global_rect().size
		if offset.y < 0:
			if _initial_zoom_pressed:
				offset.y = 0
		else:
			_initial_zoom_pressed = false
		if offset.x < 0 or offset.y < 0 or offset.x > image_size.x or offset.y > image_size.y:
			preview.visible = false
		else:
			var margin := (preview.region_rect.size / 2) / image.texture.get_size()
			var center := (offset / image_size - margin) * image.texture.get_size()
			preview.region_rect.position.x = clamp(
				center.x, 0, image.texture.get_size().x - preview.region_rect.size.x)
			preview.region_rect.position.y = clamp(
				center.y, 0, image.texture.get_size().y - preview.region_rect.size.y)
			preview.visible = true

			# Enforce minimum scale.
			var scale2d := image.texture.get_size() / image_size
			var max_scale := maxf(scale2d.x, scale2d.y)
			preview.scale = Vector2.ONE * minf(MINIMUM_MAGNIFICATION, max_scale)
	else:
		preview.visible = false

func is_in_fullscreen_preview() -> bool:
	return (%FullscreenPreview as Node2D).visible

func _update() -> void:
	if not art_piece or not is_node_ready():
		return

	var current_update_index := _update_index
	_update_index += 1
	(%NameLabel as Label).text = art_piece.get_title()
	(%LinkButton as Button).visible = false

	var displayed_image: Texture2D
	var text := tr(art_piece.blurb) + '\n\n'
	if art_piece is ArtPiece_Original:
		var original := art_piece as ArtPiece_Original
		if original.artist:
			(%ArtistLabel as MarkedUpLabel).set_markedup_text(
				tr('by [url="artist:%s"]%s[/url], 2026') % [original.artist.name, tr(original.artist.name)])
		else:
			(%ArtistLabel as MarkedUpLabel).set_markedup_text('(Original)')
		text = tr('This piece was created specifically for Worlds Upon The Wind')
		if original.based_on:
			text += tr(', based on [url="art_piece:%s"]%s[/url]') % [
				original.based_on.get_title(), original.based_on.get_title()]
		text += tr('.') + '\n\n' + tr(art_piece.blurb)
		displayed_image = await original.get_original_image()
	elif art_piece is ArtPiece_Composed:
		var composed := art_piece as ArtPiece_Composed
		displayed_image = await composed.get_original_image()
		(%ArtistLabel as MarkedUpLabel).set_markedup_text(tr('(Composite)'))
		var composition_text := ''
		if composed.used_series:
			composition_text += tr('This piece is recomposition of elements from [url=art_series:%s]%s[/url].') % [
				composed.used_series.name, tr(composed.used_series.name)]
		elif composed.additional:
			composition_text += tr('This piece is composed from the following pieces:[ul]\n')
			for subpiece: ArtPiece in [composed.main] + composed.additional:
				composition_text += '[url="art_piece:%s"]%s[/url]\n' % [
				subpiece.get_title(), subpiece.get_title()]
			composition_text += '[/ul]'
		else:
			composition_text += tr('This piece is recomposition of elements from [url=art_piece:%s]%s[/url].') % [
				composed.main.get_title(), composed.main.get_title()]
		text = composition_text + '\n\n' + text
		if composed.edits_description:
			text += '\n\n'
			text += tr(composed.edits_description)
	elif art_piece is ArtPiece_Single:
		var single := art_piece as ArtPiece_Single
		displayed_image = await single.get_original_image()
		if single.artist:
			(%ArtistLabel as MarkedUpLabel).set_markedup_text(
				tr('by [url="artist:%s"]%s[/url], %s') % [
					single.artist.name, tr(single.artist.name), single.format_date()])
		else:
			(%ArtistLabel as MarkedUpLabel).set_markedup_text(
				tr('Unknown Artist, %s') % single.format_date())
		(%LinkButton as Button).visible = true
		if not displayed_image:
			text += tr('[b]This image is still under copyright and was used as inspiration or repainted from scratch for the game. Use the link icon above view the original.[/b]\n\n')
		if single.edits_description:
			text += tr('[b]This piece was edited for ingame use:[/b] ')
			text += tr(single.edits_description)
			text += '\n\n'
		if single.series:
			text += tr('This piece is part of the [url="art_series:%s"]%s[/url] series.') % [
				single.series.name, tr(single.series.name)]
			text += '\n\n'
		if single.styles:
			if single.styles.size() == 1:
				text += tr('Related style: [url="art_style:%s"]%s[/url].') % [
					single.styles[0].name, tr(single.styles[0].name)]
			else:
				text += tr('Related styles:[ul]\n')
				for style in single.styles:
					text += '[url="art_style:%s"]%s[/url]\n' % [style.name, tr(style.name)]
				text += '[/ul]'
	else:
		(%ArtistLabel as MarkedUpLabel).set_markedup_text('')

	if current_update_index < _update_index - 1:
		return  # Two calls in quick succession - last should win.

	(%MainTextLabel as MarkedUpLabel).set_markedup_text(text.strip_edges())

	(%HorizontalImage as TextureRect).texture = null
	(%VerticalImage as TextureRect).texture = null
	(%FullscreenImage as TextureRect).texture = displayed_image
	if displayed_image:
		if displayed_image.get_size().x > displayed_image.get_size().y:
			var horizontal := (%HorizontalImage as TextureRect)
			horizontal.texture = displayed_image
			var max_width := minf(displayed_image.get_size().x, 1200)
			var max_height := minf(displayed_image.get_size().y, 715)
			var x_scale := max_width / displayed_image.get_size().x
			var y_scale := max_height / displayed_image.get_size().y
			var desired_scale := minf(x_scale, y_scale)
			horizontal.custom_minimum_size.x = displayed_image.get_size().x * desired_scale
			horizontal.custom_minimum_size.y = displayed_image.get_size().y * desired_scale
		else:
			(%VerticalImage as TextureRect).texture = displayed_image
		(%ZoomPreview as Sprite2D).texture = displayed_image
	(%HorizontalImage as TextureRect).visible = (%HorizontalImage as TextureRect).texture != null
	(%VerticalImage as TextureRect).visible = (%VerticalImage as TextureRect).texture != null

	if art_piece.province == JapanProvinceArea.Province.UNSPECIFIED:
		(%MapOffset as Control).visible = false
	else:
		(%MapOffset as Control).visible = true
		(%JapanMap as JapanMap).selected_provice = art_piece.province

func _on_link_button_pressed() -> void:
	OS.shell_open((art_piece as ArtPiece_Single).get_link())

func _on_zoom_button_pressed() -> void:
	preview_enabled = not preview_enabled
	_initial_zoom_pressed = true

func _on_fullscreen_button_pressed() -> void:
	if is_in_fullscreen_preview():
		hide_fullscreen()
	else:
		show_fullscreen()

func show_fullscreen() -> void:
	(%FullscreenPreview as Node2D).visible = true
	(%FullscreenPreview as Node2D).modulate.a = 0
	var tween := create_tween()
	tween.tween_property(%FullscreenPreview, 'modulate:a', 1.0, Utils.anim_duration(1.0))
	tween.tween_callback(func() -> void: (%FullscreenImage as Control).mouse_filter = Control.MOUSE_FILTER_STOP)
	tween.play()

func hide_fullscreen() -> void:
	var tween := create_tween()
	tween.tween_callback(func() -> void: (%FullscreenImage as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE)
	tween.tween_property(%FullscreenPreview, 'modulate:a', 0.0, Utils.anim_duration(1.0))
	tween.tween_callback(func() -> void: (%FullscreenPreview as Node2D).visible = false)
	tween.play()

func _on_fullscreen_image_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		hide_fullscreen()

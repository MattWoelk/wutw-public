class_name ArtStyleDetails
extends Control

@export var art_style: ArtStyle:
	set(value):
		art_style = value
		_update()

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_update()

func _update_font_size() -> void:
	Utils._scale_font_size(%MainTextLabel as RichTextLabel, false, 18)

func _update() -> void:
	if not art_style or not is_node_ready():
		return

	(%NameLabel as Label).text = tr(art_style.name)
	(%MainTextLabel as MarkedUpLabel).set_markedup_text(tr(art_style.blurb))
	(%LinkButton as Button).visible = not art_style.link.is_empty()

	(%ArtListing as ArtListing).art_pieces = art_style.get_pieces()

func _on_link_button_pressed() -> void:
	OS.shell_open(art_style.link)

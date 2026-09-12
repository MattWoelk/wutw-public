@tool
class_name MuseumDetail_Companion
extends Control

@export var companion: Companion:
	set(value):
		if companion == value:
			return
		companion = value
		if is_node_ready():
			_recreate()

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_recreate()

func _update_font_size() -> void:
	Utils._scale_font_size(%MainText as RichTextLabel, false, 18)

func _recreate() -> void:
	if not companion:
		return

	if Utils.is_in_editor() or GlobalSaveGame.has_unlocked_companion(companion):
		(%TitleLabel as Label).text = tr(companion.companion_name)
		(%Illustration as TextureRect).visible = true
		(%Illustration as TextureRect).texture = companion.image
		var description := (tr('%s\n\n<header_font_size>[b]Ability[/b][/font_size]\n%s') %
							[tr(companion.description), tr(companion.ability_description)])
		(%MainText as MarkedUpLabel).set_markedup_text(description, MarkedUpLabel.LinkMode.LINK)
	else:
		(%TitleLabel as Label).text = tr('???')
		(%Illustration as TextureRect).visible = false
		(%MainText as MarkedUpLabel).set_markedup_text(
			tr('This <term_lower:companion> can be befriended by finishing its event chain.'),
			MarkedUpLabel.LinkMode.LINK)

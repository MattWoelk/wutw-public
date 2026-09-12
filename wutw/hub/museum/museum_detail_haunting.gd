@tool
class_name MuseumDetail_Haunting
extends Control

@export var default_scaling: RunScaling
@export var haunting_type: HauntingType:
	set(value):
		if haunting_type == value:
			return
		haunting_type = value
		if is_node_ready():
			_recreate()

var _show_haunting: bool = false

func _ready() -> void:
	_show_haunting = not Utils.is_realistic_era()
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_recreate()

func _update_font_size() -> void:
	Utils._scale_font_size(%MainText as RichTextLabel, false, 18)

func _recreate() -> void:
	if not haunting_type:
		return

	if Utils.is_in_editor() or GlobalSaveGame.has_seen_haunting(haunting_type):
		(%Illustration as TextureRect).visible = true
		(%TypeSwapButton as Button).visible = Utils.is_realistic_era()
		var description := tr(haunting_type.description_long)
		if _show_haunting:
			(%TitleLabel as Label).text = tr('Haunting: ') + haunting_type.get_localized_name()
			(%Illustration as TextureRect).texture = haunting_type.image_small
			(%CreditsIcon as CreditsIcon).art_piece = haunting_type.image_credit
		else:
			(%TitleLabel as Label).text = tr('Challenge: ') + tr(haunting_type.name_realistic)
			description = (tr(haunting_type.description_realistic) +
						   tr('\n\nIn ages past, this was attributed to %s.\n\n') % haunting_type.name +
						   tr('“%s”') % description)
			(%Illustration as TextureRect).texture = haunting_type.image_small_realistic
			(%CreditsIcon as CreditsIcon).art_piece = haunting_type.image_realistic_credit

		description += '\n\n[b]%s[/b]' % haunting_type.get_mechanics_description(HauntingTrigger.Mode.UNIVERSAL)
		if haunting_type.effect.scales():
			description += tr('\nThe effect increases during later <term_lower:season>s.')

		description += '\n\n'
		description += tr('Pacification') if _show_haunting else tr('Mitigaton')
		description += tr(' Cost:  ')
		for aspect_type in haunting_type.base_aspect_types:
			description += '[img width=1.5em height=1.5em]%s[/img]' % aspect_type.get_used_icon().resource_path
		if Utils.ensure(haunting_type.extra_aspect_type and haunting_type.scaling_bonus_type):
			description += (tr(' (+ [img width=1.5em height=1.5em]%s[/img] per %d %s)') % [
				haunting_type.extra_aspect_type.get_used_icon().resource_path,
				default_scaling.haunting_bonus_per_slot,
				haunting_type.scaling_bonus_type.get_term_tag()
			])

		if haunting_type.spot_type:
			description += tr('\n\n* Can only affect <spot:%s> <term_lower:spot>s.') % haunting_type.spot_type.spot_type_id
		else:
			description += tr('\n\n* Can affect any <term_lower:spot>.')

		description += tr('\n\nFor each <term_lower:spot>, %s chance is %d%% + 1%% per %d total yields.') % [
			tr('Haunting') if _show_haunting else tr('Challenge'),
			roundi(default_scaling.haunting_base_probability * 100),
			default_scaling.haunting_bonus_per_extra_chance
		]

		(%MainText as MarkedUpLabel).set_markedup_text(description, MarkedUpLabel.LinkMode.LINK)
	else:
		(%Illustration as TextureRect).visible = false
		(%TypeSwapButton as Button).visible = false
		(%TitleLabel as Label).text = tr('???')
		(%CreditsIcon as CreditsIcon).art_piece = haunting_type.image_credit  # To avoid warning.
		var description: String
		if haunting_type.spot_type:
			description = tr('This <term_lower:haunting> can only affect <spot:%s> <term_lower:spot>s.') % haunting_type.spot_type.spot_type_id
		else:
			description = tr('This <term_lower:haunting> can affect any <term_lower:spot>.')

		(%MainText as MarkedUpLabel).set_markedup_text(description, MarkedUpLabel.LinkMode.LINK)

func _on_type_swap_button_toggled(toggled_on: bool) -> void:
	(%TypeSwapButton as Button).text = tr('View Challenge Version') if toggled_on else tr('View Haunting Version')
	_show_haunting = (%TypeSwapButton as Button).button_pressed
	_recreate()

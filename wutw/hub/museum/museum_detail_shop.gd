@tool
class_name MuseumDetail_Shop
extends Control

@export var shop_type: ShopType:
	set(value):
		if shop_type == value:
			return
		shop_type = value
		if is_node_ready():
			_recreate()

@export var accord_monument_shop_type: ShopType
@export var trade_shop_type: ShopType
@export var trade_shop_skill: Skill

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_recreate()

func _update_font_size() -> void:
	Utils._scale_font_size(%MainText as RichTextLabel, false, 18)

func _recreate() -> void:
	if not shop_type:
		return

	if Utils.is_in_editor() or GlobalSaveGame.has_seen_shop(shop_type):
		(%TitleLabel as Label).text = tr(shop_type.title)
		(%Illustration as TextureRect).visible = true
		(%Illustration as TextureRect).texture = shop_type.background_texture
		(%CreditsIcon as CreditsIcon).art_piece = shop_type.background_credit

		var description := tr(shop_type.tooltip)
		var event := _get_event()
		if event:  # For all but the trade shop.
			var spot_upgrade := event.default_spot_upgrade
			var spot := SpotType.get_spot_type_by_upgrade(spot_upgrade)
			description += tr('\n\nAvailable in <spot:%s> - <spot_upgrade:%s>.') % [
				spot.spot_type_id, spot_upgrade.spot_upgrade_id]
		(%MainText as MarkedUpLabel).set_markedup_text(description, MarkedUpLabel.LinkMode.LINK)
	else:
		(%TitleLabel as Label).text = tr('???')
		(%Illustration as TextureRect).visible = false
		(%CreditsIcon as CreditsIcon).art_piece = shop_type.background_credit  # To avoid warning.

		var description: String
		if shop_type == accord_monument_shop_type:
			# Special case
			description = tr('This <term_lower:shop> is part of the main story.')
		else:
			var skill: Skill
			if shop_type == trade_shop_type:
				# Another Special case.
				description = tr('This <term_lower:shop> is available in the <term:capital>.')
				skill = trade_shop_skill
			else:
				var event := _get_event()
				description += tr('This <term_lower:shop> is unlocked by the event: <event:%s>.') % event.event_id
				skill = _get_skill(event.requirement)
				Utils.ensure(skill != null)
			if Utils.ensure(skill != null) and not GlobalSaveGame.has_unlocked_skill(skill):
				description += tr('\n\nRequires the %s <term_lower:skill>.') % skill.get_term_tag()

		(%MainText as MarkedUpLabel).set_markedup_text(description, MarkedUpLabel.LinkMode.LINK)

func _get_event() -> Event_Stage:
	for event: Event in Event.get_all_events().values():
		if event is Event_Stage:
			var stage_event := event as Event_Stage
			if stage_event.get_associated_landmark() == shop_type:
				return stage_event
	Utils.ensure(shop_type == trade_shop_type)
	return null

func _get_skill(requirement: EventRequirement) -> Skill:
	if requirement is EventRequirement_HasSkill:
		return (requirement as EventRequirement_HasSkill).skill
	elif requirement is EventRequirement_All:
		for subreq in (requirement as EventRequirement_All).all_requirements:
			var skill := _get_skill(subreq)
			if skill:
				return skill
	return null

class_name EventChoice
extends Resource

@export var markedup_text: String

@export_group('Requirements')
@export var requirement: EventRequirement
@export var markedup_requirement_hint: String
@export var markedup_requirement_tooltip: String
@export var include_as_event_requirement: bool = false
@export var show_condition: EventRequirement

@export_group('Outcome')
@export var outcome: EventOutcome
@export var markedup_outcome_hint: String

@export_group('Next Step')
@export_multiline var markedup_result_text: String  # Inserts a quick reaction step before proceeding.
@export var result_event_step_id: String

static func collect_requirement_details(req: EventRequirement, aspects: Array[AspectType], bonuses: Array[BonusType], cards: Array[CardType], relics: Array[Relic]) -> void:
	if req is EventRequirement_All:
		for subreq in (req as EventRequirement_All).all_requirements:
			collect_requirement_details(subreq, aspects, bonuses, cards, relics)
	elif req is EventRequirement_Any:
		for subreq in (req as EventRequirement_Any).any_requirements:
			collect_requirement_details(subreq, aspects, bonuses, cards, relics)
	elif req is EventRequirement_HasCard:
		var card_type := (req as EventRequirement_HasCard).card_type
		if card_type not in cards:
			cards.append(card_type)
	elif req is EventRequirement_RunBonus:
		var bonus_type := (req as EventRequirement_RunBonus).bonus_type
		if bonus_type not in bonuses:
			bonuses.append(bonus_type)
	elif req is EventRequirement_NumAspects:
		var aspect_type := (req as EventRequirement_NumAspects).aspect_type
		if aspect_type not in aspects:
			aspects.append(aspect_type)
	elif req is EventRequirement_HasRelic:
		var relic := (req as EventRequirement_HasRelic).relic
		if relic not in relics:
			relics.append(relic)

static func collect_outcome_details(event: Event, choice: EventChoice, oc: EventOutcome, bonuses: Array[BonusType], cards: Array[CardType], relics: Array[Relic], shop_types: Array[ShopType], include_undiscovered: bool = false) -> bool:
	if not include_undiscovered and not Utils.is_in_editor():
		if choice.outcome and not GlobalSaveGame.has_seen_event_choice(event, event.get_choice_index(choice)):
			return false

	if oc is EventOutcome_All:
		for suboutcome in (oc as EventOutcome_All).suboutcomes:
			collect_outcome_details(event, choice, suboutcome, bonuses, cards, relics, shop_types, include_undiscovered)
	elif oc is EventOutcome_Random:
		for suboutcome: EventOutcome in (oc as EventOutcome_Random).suboutcomes.keys():
			collect_outcome_details(event, choice, suboutcome, bonuses, cards, relics, shop_types, include_undiscovered)
	elif oc is EventOutcome_AddCard:
		var card_type := (oc as EventOutcome_AddCard).card_type
		if card_type not in cards:
			cards.append(card_type)
	elif oc is EventOutcome_Bonus:
		var bonus_type := (oc as EventOutcome_Bonus).bonus_type
		var amount := (oc as EventOutcome_Bonus).amount
		if amount > 0 and bonus_type not in bonuses:
			bonuses.append(bonus_type)
	elif oc is EventOutcome_AddRelic:
		var relic := (oc as EventOutcome_AddRelic).relic
		if relic not in relics:
			relics.append(relic)
	elif oc is EventOutcome_UnlockShop:
		var shop_type := (oc as EventOutcome_UnlockShop).shop_type
		if shop_type not in shop_types:
			shop_types.append(shop_type)
	return true

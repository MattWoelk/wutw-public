@tool
class_name EventOutcome_ChooseCard
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/choose_card/event_outcome_widget_choose_card.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var specific_card_types: Array[CardType]
@export var card_tier_bonus: int = 0
@export var aspect: AspectType = null
@export var card_tag: CardType.Tag = CardType.Tag.NO_TAG

func apply(_event: Event) -> EventOutcomeWidget:
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_ChooseCard
	widget.specific_card_types = specific_card_types
	widget.card_tier_bonus = card_tier_bonus
	widget.aspect = aspect
	widget.card_tag = card_tag
	return widget

func describe(_run: Run) -> String:
	if specific_card_types:
		var card_tags: Array[String]
		for card_type in specific_card_types:
			card_tags.append(card_type.get_term_tag())
		return tr('Choose a <term_lower:glyph>s from: ') + tr(', ').join(card_tags)
	else:
		var tag_label: String
		match card_tag:
			CardType.Tag.THEME_PLANT: tag_label = 'a plant'
			CardType.Tag.THEME_ANIMAL: tag_label = 'an animal'
			CardType.Tag.THEME_MINERAL: tag_label = 'a mineral'
			CardType.Tag.THEME_NUMBER: tag_label = 'a number'
			CardType.Tag.THEME_PEOPLE: tag_label = 'a person'
			CardType.Tag.THEME_EMOTIONS: tag_label = 'an emotion'
			CardType.Tag.THEME_BODY: tag_label = 'a body'
			CardType.Tag.THEME_ACTION: tag_label = 'an action'
			CardType.Tag.THEME_TIME: tag_label = 'a time'
			CardType.Tag.THEME_TOOL: tag_label = 'a tool'
			CardType.Tag.THEME_ART: tag_label = 'an art'
			CardType.Tag.THEME_KNOWLEDGE: tag_label = 'a scholarship'
			CardType.Tag.THEME_COMMERCE: tag_label = 'a commerce'
			CardType.Tag.THEME_LABOR: tag_label = 'a labor'
			CardType.Tag.THEME_PLACE: tag_label = 'a place'
			CardType.Tag.THEME_SPIRITUAL: tag_label = 'a spiritual'
			CardType.Tag.THEME_FOOD: tag_label = 'a food'
			CardType.Tag.THEME_ELEMENT: tag_label = 'an element'
			CardType.Tag.THEME_COLOR: tag_label = 'a color'
			CardType.Tag.THEME_SOCIAL: tag_label = 'a social'
			CardType.Tag.THEME_WEATHER: tag_label = 'a weather'
			CardType.Tag.THEME_LANDSCAPE: tag_label = 'a landscape'
			# WARNING: Should be kept in sync with cards tag list, but not crucial.
		var text := tr('Choose %s <term_lower:glyph>') % tag_label
		if aspect:
			text += tr(' with %s') % aspect.get_term_tag()
		return text

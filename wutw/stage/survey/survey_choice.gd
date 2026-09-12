class_name SurveyChoice
extends Resource

@export var label: String

@export_group('Requirements')
@export var requirement: EventRequirement
@export var requirement_description_override: String
@export var aspects: Array[AspectType]
@export var aspects_per_season: Array[AspectType]

@export_group('Outcome')
@export var outcome: EventOutcome
@export var outcome_description_override: String
@export_multiline var outcome_text: String

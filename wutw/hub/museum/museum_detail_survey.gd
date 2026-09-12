@tool
class_name MuseumDetail_Survey
extends Control

static var SURVEY_RECIPE_SCENE := AsyncLoadedResource.new('res://stage/survey/survey_recipe.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)

@export var episode: SurveyEpisode:
	set(value):
		if episode == value:
			return
		episode = value
		if is_node_ready():
			_recreate()

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_recreate()

func _update_font_size() -> void:
	Utils._scale_font_size(%MainText as RichTextLabel, false, 18)

func _recreate() -> void:
	if not episode:
		return

	if Utils.is_in_editor() or GlobalSaveGame.has_seen_survey(episode):
		(%DetailsContainer as Control).visible = true

		(%TitleLabel as Label).text = tr(episode.title)
		(%Illustration as TextureRect).visible = true
		(%Illustration as TextureRect).texture = episode.background_image.get_texture_sync()
		(%CreditsIcon as CreditsIcon).art_piece = episode.background_credit

		(%MainText as MarkedUpLabel).set_markedup_text(tr(episode.text), MarkedUpLabel.LinkMode.LINK)

		Utils.clear_node(%ChoicesList)
		for choice in episode.choices:
			var choice_scene := SURVEY_RECIPE_SCENE.instantiate_loaded_scene() as SurveyRecipe
			choice_scene.episode = episode
			choice_scene.survey_choice = choice
			choice_scene.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			choice_scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
			%ChoicesList.add_child(choice_scene)
	else:
		(%DetailsContainer as Control).visible = false
		(%TitleLabel as Label).text = tr('???')
		(%Illustration as TextureRect).visible = false
		(%CreditsIcon as CreditsIcon).art_piece = episode.background_credit  # To avoid warning.

	var location_names := episode.get_location_names()
	if location_names:
		var location_discription: String
		if location_names.size() == 1:
			location_discription = tr('This <term_lower:encounter> can only occur near the %s.') % location_names[0]
		else:
			location_discription = tr('This <term_lower:encounter> can occur near:') + '[ul]\n'
			for location_name in location_names:
				location_discription += location_name
				location_discription += '\n'
			location_discription += '[/ul]'
		(%HintText as MarkedUpLabel).set_markedup_text(location_discription, MarkedUpLabel.LinkMode.LINK)
	else:
		(%HintText as MarkedUpLabel).set_markedup_text(
			tr('This <term_lower:encounter> can occur anywhere.'), MarkedUpLabel.LinkMode.LINK)

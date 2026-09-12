@tool
class_name PastRunSurvey
extends UkiyoePanelContainer

static var DISCOVERY_SURVEY_SCENE := AsyncLoadedResource.new('res://run/run_end/discovery_survey_episode.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

var episodes: Array[SurveyEpisode]

func _ready() -> void:
	super._ready()

	Utils.clear_node(%EpisodesList)
	for episode in episodes:
		var discovery := DISCOVERY_SURVEY_SCENE.instantiate_loaded_scene() as Discovery_SurveyEpisode
		discovery.episode = episode
		%EpisodesList.add_child(discovery)

class_name SurveyEpisode
extends Resource

static var _group_loader := AsyncLoadedGroup.new('res://stage/survey/episodes/resourcegroup_survey_episodes.tres')

const SPOT_SAMPLES := 100
const NONSPOT_SAMPLES := 10
const UNIVERSAL_EPISODE_WEIGHT := 0.25
const UNRECENCY_BIAS := Vector2(0.0, 0.5)

@export var episode_id: String
@export var title: String
@export var biome_types: Array[MapBiomes.Biome]
@export var spot_types: Array[SpotType]
@export var requirement: EventRequirement
@export_multiline var text: String
## Ideal size: 2026x1128
@export var background_image: LazyTextureResource
@export var background_credit: ArtPiece
@export var choices: Array[SurveyChoice]

static var _all_episodes: Dictionary[String, SurveyEpisode] = {}

static func get_all_episodes() -> Dictionary[String, SurveyEpisode]:
	if not _all_episodes:
		for episode: SurveyEpisode in _group_loader.get_loaded():
			if Utils.is_dev():
				assert(episode.episode_id)
				if episode.episode_id in _all_episodes:
					push_error('Duplicate survey episode ID "%s":\n- %s\n- %s' %
							[episode.episode_id, episode.resource_path, _all_episodes[episode.episode_id].resource_path])
				if not episode.background_credit:
					push_warning('Survey episode missing art credit: ', episode.episode_id)
			_all_episodes[episode.episode_id] = episode
	return _all_episodes

static func get_episode_by_id(target_episode_id: String) -> SurveyEpisode:
	return get_all_episodes().get(target_episode_id, null)

static func choose_episodes(run: Run, map_location: Vector2) -> Dictionary[SurveyEpisode, float]:
	var result: Dictionary[SurveyEpisode, float]

	var radius := run.scaling.survey_scan_radius

	var biome_counts := run.get_map().get_biome_counts_in_radius(map_location, radius)
	var total_biomes := 0
	for biome in biome_counts:
		total_biomes += biome_counts[biome]

	var spot_type_counts: Dictionary[SpotType, int]
	var total_spot_types := 0
	for spot_type in run.get_map().get_spot_types_at_position(map_location, radius, SPOT_SAMPLES):
		spot_type_counts[spot_type] = spot_type_counts.get(spot_type, 0) + 1
		total_spot_types += 1

	var used_episodes := run.get_run_data().used_episodes
	for episode: SurveyEpisode in get_all_episodes().values():
		if episode.requirement and not episode.requirement.is_satisfied(run, null):
			continue
		var weight := 0.0
		if not episode.biome_types and not episode.spot_types:
			weight = UNIVERSAL_EPISODE_WEIGHT
		else:
			for biome in episode.biome_types:
				if biome in biome_counts:
					weight += biome_counts[biome] / float(total_biomes)
			for spot_type in episode.spot_types:
				if spot_type in spot_type_counts:
					weight += spot_type_counts[spot_type] / float(total_spot_types)
			if weight <= 0:
				continue
		if episode in used_episodes:
			weight = 0.0  # Must be after biome/spot checks, as that may `continue` the loop.
		else:
			var recent_index := GlobalSaveGame.get_recent_survey_episodes().find(episode)
			if recent_index != -1:
				var index_from_end := GlobalSaveGame.get_recent_survey_episodes().size() - recent_index
				weight *= remap(index_from_end, SaveGame.MAX_RECENT_SURVEY_EPISODES, 1, UNRECENCY_BIAS.x, UNRECENCY_BIAS.y)
		result[episode] = weight

	return result

func get_location_names() -> Array[String]:
	var location_names: Dictionary[String, bool]
	for biome in biome_types:
		var biome_name := Map.get_biome_name(biome)
		if biome_name == tr('Sky'):
			biome_name = tr('Shard Edge')
		location_names[biome_name] = true
	for spot_type in spot_types:
		location_names[tr(spot_type.name)] = true
	var result: Array[String]
	result.assign(location_names.keys())
	return result

@tool
class_name HubCharacter
extends HubFacility

static var NAMES_LIST := AsyncLoadedResource.new('res://characters/character_names_list.tres')
static var SPEECH_BUBBLE_SCENE := AsyncLoadedResource.new('res://dialogue/bubble/speech_bubble.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)

const PREFERRED_JOB_CHANCE := 0.75
const REFUGEE_CHANCE := 0.25

enum Origin { HUB, REFUGEE, PAST_SHARD, AUTO_ASSIGNED }

var character: HubCharacterSpec
@export var is_flipped: bool = false:
	set(value):
		if is_flipped != value:
			is_flipped = value
			(%Area2D as Area2D).scale.x *= -1
			# This leaves the tooltip anchor imperfect, but flipping the whole tree messes it up completely.
var first_name: String
var origin: Origin = Origin.AUTO_ASSIGNED
var home_town: SettlementState
var home_shard: PastRun
var job: Job
var offered_quest: Quest_Settler

var _speech_bubble: SpeechBubble
var _chosen_bark: Bark

func _ready() -> void:
	var anim_player := get_node_or_null('%AnimationPlayer')
	if anim_player:
		if Utils.ensure(anim_player is AnimationPlayer):
			(anim_player as AnimationPlayer).play('idle')

	if not Utils.is_in_editor():
		assert(character)
		_initialize_metadata()
		_update_tooltip()
		GlobalGameSettings.changed.connect(_update_tooltip)

		var quest_notifier := %QuestLabel as Control
		if offered_quest:
			var tooltip_anchor := %TooltipAnchor as Control
			quest_notifier.position.x = tooltip_anchor.position.x + tooltip_anchor.size.x / 2 - quest_notifier.size.x * quest_notifier.scale.x / 2
			quest_notifier.position.y = tooltip_anchor.position.y - quest_notifier.size.y * quest_notifier.scale.y
			quest_notifier.visible = true
			quest_notifier.set_instance_shader_parameter('is_completed', GlobalSaveGame.has_completed_settler_quest(offered_quest))
		else:
			quest_notifier.visible = false

		var hub := Utils.get_active_hub()
		hub.menu_opened.connect(func(_node: Node) -> void:
			if _speech_bubble:
				_speech_bubble.hide_tooltip()
		)

	# After tooltip text is set up.
	super._ready()

func _exit_tree() -> void:
	if _speech_bubble:
		_speech_bubble.queue_free()
		_speech_bubble = null

func get_character_sprite() -> Texture2D:
	return (%Sprite2D as Sprite2D).texture

func mark_quest_accepted() -> void:
	offered_quest = null
	(%QuestLabel as Control).visible = false

func say(text: String, alignment: Tooltip.Alignment = Tooltip.Alignment.CENTERED, flipped: bool = false, interactive: bool = true) -> void:
	# Input already translated.
	if not _speech_bubble:
		_speech_bubble = SpeechBubble.create(
				%TooltipAnchor as Control, '',
				[Tooltip.RelativeDirection.ABOVE],
				[alignment],
				null, SPEECH_BUBBLE_SCENE.get_loaded_scene()) as SpeechBubble
		_speech_bubble.z_index = Utils.get_absolute_z_index(self) + UI.LAYER_SPACING
		_speech_bubble.margin = 5
		_speech_bubble.hub_character = self

	if _speech_bubble.get_state() == SpeechBubble.State.HIDDEN or text != _speech_bubble.get_markedup_text():
		_speech_bubble._preferred_alignments = [alignment]
		_speech_bubble.is_flipped = flipped
		_speech_bubble.hide_text = text.is_empty()
		_speech_bubble.interactive = interactive

		await _speech_bubble.show_line(text)
	else:
		if _speech_bubble.get_state() == SpeechBubble.State.REVEALING_TEXT:
			_speech_bubble.fast_forward()
		else:
			_speech_bubble.hide_tooltip()

func bark() -> void:
	if not _chosen_bark:
		_chosen_bark = Bark.choose_bark(self)
	await say(tr(_chosen_bark.text))

func get_speech_bubble() -> SpeechBubble:
	return _speech_bubble

func _initialize_metadata() -> void:
	if character.main_character:
		return  # No customization.

	var rng := GlobalSaveGame.get_hub_random()

	# Name
	if not first_name:  # Not predefined.
		var names_list := NAMES_LIST.get_loaded() as CharacterNamesList
		if character.gender == HubCharacterSpec.Gender.MALE:
			if rng.rand_bool():
				first_name = rng.pick(names_list.male_names)
			else:
				first_name = rng.pick(names_list.universal_names)
		elif character.gender == HubCharacterSpec.Gender.FEMALE:
			if rng.rand_bool():
				first_name = rng.pick(names_list.female_names)
			else:
				first_name = rng.pick(names_list.universal_names)
		else:
			first_name = rng.pick(names_list.universal_names)

	# Job
	if not job:  # Not predefined.
		var main_quest_state := GlobalSaveGame.get_main_quest_progress()
		var jobs_pool: Array[Job]
		if character.preferred_jobs and rng.rand_float() < PREFERRED_JOB_CHANCE:
			jobs_pool = character.preferred_jobs
			job = rng.pick(jobs_pool)
			while job and (main_quest_state < job.min_main_quest_state or main_quest_state > job.max_main_quest_state):
				if jobs_pool.size() <= 1:
					job = null
					break
				jobs_pool = jobs_pool.duplicate()
				jobs_pool.erase(job)
				job = rng.pick(jobs_pool)

		if not job:
			jobs_pool = character.allowed_jobs
			job = rng.pick(jobs_pool)
			while job and (main_quest_state < job.min_main_quest_state or main_quest_state > job.max_main_quest_state):
				if jobs_pool.size() <= 1:
					job = null
					break
				jobs_pool = jobs_pool.duplicate()
				jobs_pool.erase(job)
				job = rng.pick(jobs_pool)

	if not Utils.ensure(job != null):
		job = Job.new()

	# Origin
	if origin == Origin.AUTO_ASSIGNED:  # Not predefined.
		if job.can_be_hub_native and rng.rand_bool():
			origin = Origin.HUB
		else:
			if character.must_be_refugee or not GlobalSaveGame.get_past_run_ids() or rng.rand_float() <= REFUGEE_CHANCE:
				origin = Origin.REFUGEE
			else:
				origin = Origin.PAST_SHARD
				_initialize_hometown()

	# Quest
	if not offered_quest:  # Not predefined.
		if Utils.is_settler_questing_unlocked() and origin == Origin.REFUGEE:
			_initialize_quest()

func _initialize_hometown() -> void:
	if Utils.is_in_editor():
		return
	var rng := GlobalSaveGame.get_hub_random()
	var past_run_ids := GlobalSaveGame.get_past_run_ids()
	rng.shuffle(past_run_ids)
	for past_run_id in past_run_ids:
		var past_run := GlobalSaveGame.get_past_run(past_run_id)
		var settlements := past_run.run_data.settlement_states.duplicate() as Array[SettlementState]
		rng.shuffle(settlements)
		for settlement_state in settlements:
			if not job.origin_spot_upgrades:
				home_town = settlement_state
				home_shard = past_run
				return

			for spot_upgrades in settlement_state.activated_upgrades:
				for upgrade: SpotUpgrade in spot_upgrades:
					if upgrade in job.origin_spot_upgrades:
						home_town = settlement_state
						home_shard = past_run
						return
	# Nothing matched. I guess it's a refugee.
	origin = Origin.REFUGEE

func _initialize_quest() -> void:
	var hub := Utils.get_active_hub()
	var priority_options: Array[Quest_Settler]
	var options: Array[Quest_Settler]
	for quest: Quest in Quest.get_all_quests().values():
		var quest_settler := quest as Quest_Settler
		if not quest_settler:
			continue
		if GlobalSaveGame.get_main_quest_progress() < quest_settler.min_main_quest:
			continue
		if quest_settler.restrict_to_jobs and job not in quest_settler.restrict_to_jobs:
			continue
		if quest_settler.exclude_jobs and job in quest_settler.exclude_jobs:
			continue
		if quest_settler.restrict_to_ages and character.age not in quest_settler.restrict_to_ages:
			continue
		if GlobalSaveGame.get_quest_instance(quest_settler):
			# Can happen if reloaded after save.
			# This technically allows you to keep reloading to take on more quests, but that's Ok.
			continue
		if hub.is_settler_quest_claimed(quest_settler):
			continue
		if GlobalSaveGame.has_completed_settler_quest(quest_settler):
			options.append(quest_settler)
		else:
			priority_options.append(quest_settler)

	if priority_options:
		options = priority_options

	if options:
		offered_quest = GlobalSaveGame.get_hub_random().pick(options)
		hub.claim_settler_quest(offered_quest)

func _update_tooltip() -> void:
	if character.main_character:
		tooltip_text = tr('[center][b]%s[/b]\nHaven Resident[/center]') % tr(character.get_character().character_name)
	else:
		var job_name: String
		if Utils.ensure(job != null):
			job_name = tr(job.job_name)
			if character.gender == HubCharacterSpec.Gender.FEMALE and job.female_job_name_override:
				job_name = tr(job.female_job_name_override)
		var origin_text: String
		match origin:
			Origin.HUB: origin_text = tr('Haven Resident')
			Origin.REFUGEE: origin_text = tr('Settler') if Utils.is_realistic_era() else tr('Refugee')
			Origin.PAST_SHARD: origin_text = tr('Visiting from %s, %s') % [home_town.settlement_name.get_native_display_name(), home_shard.get_native_shard_display_name()]
		tooltip_text = tr('[center][b]%s, %s[/b]\n%s[/center]') % [tr(first_name), tr(job_name), origin_text]

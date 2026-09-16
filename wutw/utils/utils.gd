class_name Utils
extends Object

const DEFAULT_ANIM_SPEED_SCALE: float = 1.5

static var NUMBER_COMMAS_REGEX := RegEx.create_from_string('(?<=\\d)(?=(\\d{3})+(?!\\d))')
static var QUERY_WORD_REGEX := RegEx.create_from_string(r'(\p{L}|\d|\')+')
static var TRANSLATION_DUMMY := RefCounted.new()

static var _active_run: Run
static var _active_hub: Hub

static func clear_node(node: Node, leave_first: int = 0) -> void:
	while node.get_child_count() > leave_first:
		var child := node.get_child(leave_first)
		node.remove_child(child)  # Need to remove it now for the check to reflect the new state.
		child.queue_free()

static func set_active_run(run: Run) -> void:
	Utils.ensure(not _active_run or not run)
	_active_run = run

static func get_active_run() -> Run:
	return _active_run

static func set_active_hub(hub: Hub) -> void:
	Utils.ensure(not _active_hub or not hub)
	_active_hub = hub

static func get_active_hub() -> Hub:
	return _active_hub

static func is_early_finishing_unlocked() -> bool:
	if is_in_editor():
		return true
	else:
		return GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P110_COMPLETED_TUTORIAL

static func is_convergence_unlocked() -> bool:
	if is_in_editor():
		return true
	else:
		return GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P117_COMPLETED_SURVEY

static func are_shard_types_unlocked() -> bool:
	if is_in_editor():
		return true
	else:
		return GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P115_GATHERED_RELICS

static func is_museum_unlocked() -> bool:
	if is_in_editor():
		return true
	else:
		return GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P200_STARTED_MAGIC

static func are_surveys_unlocked() -> bool:
	if is_in_editor():
		return true
	else:
		return GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P115_GATHERED_RELICS

static func are_hauntings_unlocked() -> bool:
	if is_in_editor():
		return true
	else:
		return GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P210_FOUND_PLACES_OF_POWER

static func are_animal_companions_unlocked() -> bool:
	if is_in_editor():
		return true
	else:
		return GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P320_ESTABLISHED_MONASTERY

static func is_portal_network_unlocked() -> bool:
	if is_in_editor():
		return true
	else:
		return GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P115_GATHERED_RELICS

static func is_explorer_unlocked() -> bool:
	if is_in_editor():
		return true
	else:
		return GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P115_GATHERED_RELICS

static func is_explorer_trips_unlocked() -> bool:
	if is_in_editor():
		return true
	else:
		return GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P400_STARTED_DEPRESSION

static func is_realistic_era() -> bool:
	if is_in_editor():
		return false
	else:
		return GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P400_STARTED_DEPRESSION

static func is_settler_questing_unlocked() -> bool:
	if is_in_editor():
		return false
	else:
		return GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P420_SENT_OFF_KID

static func is_debate_in_progress() -> bool:
	if is_in_editor():
		return false
	else:
		return (GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P430_STARTED_DEBATE
			and GlobalSaveGame.get_main_quest_progress() < SaveGame.MainQuestProgress.P440_FINISHED_DEBATE)

static func is_in_editor() -> bool:
	return Engine.is_editor_hint()

static func is_dev() -> bool:
	return OS.has_feature('editor')

static func is_packaged() -> bool:
	return not Engine.is_editor_hint() and not OS.has_feature('editor')

static func is_demo() -> bool:
	return OS.has_feature('demo')

static func is_steam_deck() -> bool:
	return is_packaged() and Steam.isRunningOnSteamHardware()

static func is_mac_os() -> bool:
	return OS.has_feature('macos')

static func set_input_enabled(control: Control, enabled: bool) -> void:
	if enabled:
		control.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED
	else:
		control.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED

static func get_typed_ancestor(node: Node, type: Variant) -> Node:
	if not node:
		return null
	assert(type is not String)
	var parent := node.get_parent()
	while parent and not is_instance_of(parent, type):
		parent = parent.get_parent()
	return parent

static func get_all_hub_facilities_within(node: Node) -> Array[HubFacility]:
	var results: Array[HubFacility] = []
	_get_group_nodes_within(node, 'HubFacilities', results)
	return results

static func choose_card_rewards(run: Run, card_tier_weights: Array[float],
								num_cards: int, apply_bonus: bool,
								is_acceptable: Callable = func(_card_type: CardType) -> bool: return true,
								not_already_in_deck: bool = true,
								fallback_to_higher_tier: bool = true) -> Array[CardType]:
	var covered_cards := run.get_deck_cards().duplicate() if not_already_in_deck else []
	var card_tier_bonus := float(run.get_var(RunVars.Var.CARD_TIER_BONUS_PERCENT)) / 100.0
	var result: Array[CardType] = []
	var randomizer := run.get_card_reward_random()

	var is_allowed := func(card_type: CardType) -> bool:
		if not is_acceptable.call(card_type):
			return false
		if card_type in covered_cards:
			return false
		if CardType.Tag.NOT_RANDOMLY_SELECTED in card_type.tags:
			return false
		# HACK: Hide Pacify cards until hauntings are unlocked.
		if not are_hauntings_unlocked():
			var has_pacify := false
			for ability in card_type.abilities:
				if ability is CardAbility_Pacify:
					has_pacify = true
			if has_pacify:
				return false
		return true

	for i in range(num_cards):
		# Pick a tier, shifting probabilities, on average +1 level per 100% of tier bonus.
		# Note: Do the extra RNG roll even if card_tier_bonus == 0, to maintain determinism.
		var base_tier := randomizer.pick_weighted_array(card_tier_weights)[0] as float
		if apply_bonus:
			base_tier += card_tier_bonus
			var leftover_tier := base_tier - floorf(base_tier)
			base_tier = floorf(base_tier) + randomizer.pick_weighted_array([1.0 - leftover_tier, leftover_tier])[0]
		var tier := mini(CardType.Rarity.LEGENDARY, roundi(base_tier))  # Can never get negative cards.

		var card_types: Array[CardType] = []
		# Keep going to lower tiers if can't find any in this tier.
		while card_types.is_empty() and tier >= 0:
			for card_type in CardType.get_all_card_types_by_tier(tier):
				if not is_allowed.call(card_type):
					continue
				card_types.append(card_type)
			tier -= 1
		# Fallback if not found.
		if not card_types and fallback_to_higher_tier:
			tier = 1
			while card_types.is_empty() and tier <= CardType.Rarity.LEGENDARY:
				for card_type in CardType.get_all_card_types_by_tier(tier):
					if not is_allowed.call(card_type):
						continue
					card_types.append(card_type)
				tier += 1
		# Pick one of the valid cards.
		if card_types:
			var selected_card_type := randomizer.pick(card_types) as CardType
			covered_cards.append(selected_card_type)
			result.append(selected_card_type)
	return result

static func anim_duration(base_duration: float = 1.0) -> float:
	return base_duration / DEFAULT_ANIM_SPEED_SCALE / GameSettings.Interface.animation_speed.value()

static func anim_speed(base_speed: float = 1.0) -> float:
	return base_speed * DEFAULT_ANIM_SPEED_SCALE * GameSettings.Interface.animation_speed.value()

static func matches_query(haystack: Array[String], query: String) -> bool:
	if not query:
		return true
	for term in parse_search_query(query):
		var matched_any := false
		for hay in haystack:
			if hay.findn(term) != -1:
				matched_any = true
				break
		if not matched_any:
			return false
	return true

static func parse_search_query(query_text: String) -> Array[String]:
	var result: Array[String]
	for m in QUERY_WORD_REGEX.search_all(query_text.to_lower().replace('ō', 'o').replace('ū', 'u')):
		result.append(m.get_string(0))
	return result

static func get_screen_rect(control: Control) -> Rect2:
	var local_rect: Rect2 = control.get_global_rect().abs()

	var vp := control.get_viewport()
	if vp is not SubViewport:
		return local_rect

	# In ths control's viewport's space.
	var corners: Array[Vector2] = [
		local_rect.position,
		local_rect.position + Vector2(local_rect.size.x, 0),
		local_rect.position + local_rect.size,
		local_rect.position + Vector2(0, local_rect.size.y)
	]

	# Final transform including any Camera2D and SubViewport chains.
	var to_screen := vp.get_final_transform() * vp.get_canvas_transform()

	# Make a rect out of transformed points.
	var result : Rect2 = Rect2(to_screen * corners[0], Vector2.ZERO)
	for p: Vector2 in corners.slice(1):
		result = result.expand(to_screen * p)

	return result

static func get_absolute_z_index(target: Node) -> int:
	var node := target
	var z_index := 0
	while node and (node is Node2D or node is Control):
		@warning_ignore('unsafe_property_access')
		z_index += node.z_index
		@warning_ignore('unsafe_property_access')
		if not node.z_as_relative:
			break
		node = node.get_parent();
	return z_index

static func format_conjunction(pieces: Array[String], is_alternation: bool = false) -> String:
	if pieces.is_empty():
		return ''
	elif pieces.size() == 1:
		return pieces[0]
	elif pieces.size() == 2:
		var pattern: String
		if is_alternation:
			pattern = TRANSLATION_DUMMY.tr('{a} or {b}', 'LIST_TWO_OR')
		else:
			pattern = TRANSLATION_DUMMY.tr('{a} and {b}', 'LIST_TWO_AND')
		return TRANSLATION_DUMMY.tr(pattern).format({a=pieces[0], b=pieces[1]})
	else:
		var result := pieces[0]
		var sep_pattern := TRANSLATION_DUMMY.tr('{a}, {b}', 'LIST_SEPARATOR')
		for i in range(1, pieces.size() - 1):
			result = sep_pattern.format({a=result, b=pieces[i]})

		var end_pattern: String
		if is_alternation:
			end_pattern = TRANSLATION_DUMMY.tr('{a}, or {b}', 'LIST_END_OR')
		else:
			end_pattern = TRANSLATION_DUMMY.tr('{a}, and {b}', 'LIST_END_AND')
		return end_pattern.format({a=result, b=pieces[-1]})

static func format_number(number: int) -> String:
	return NUMBER_COMMAS_REGEX.sub(str(number), TRANSLATION_DUMMY.tr(',', 'NUMBER_SEPARATOR'), true)

static func is_running_in_single_scene_mode() -> bool:
	if (Engine.get_main_loop() as SceneTree).current_scene.name == 'Main':  # HACK
		return false
	return true

static func take_screenshot(context_node: Node, output_filename: String = '') -> void:
	var viewport_texture := context_node.get_viewport().get_texture()
	var image := viewport_texture.get_image()
	if not output_filename:
		var timestamp := Time.get_datetime_string_from_system().replace(':', '-').replace(' ', '_')
		output_filename = 'user://screenshot_%s.png' % timestamp
	image.save_png(output_filename)

static func describe_relative_time(unix_timestamp: int) -> String:
	if unix_timestamp <= 0:
		return TRANSLATION_DUMMY.tr('unknown', 'TIME_SINCE_TIMESTAMP')

	var current_time := Time.get_unix_time_from_system()
	var delta := current_time - unix_timestamp

	const MINUTE := 60
	const HOUR := 3600
	const DAY := 86400
	const MIN_LIMIT := 5
	const MAX_LIMIT := DAY * 30

	if delta <= MIN_LIMIT:
		return TRANSLATION_DUMMY.tr('just now', 'TIME_SINCE_TIMESTAMP')
	elif delta > MAX_LIMIT:
		var date := Time.get_date_dict_from_unix_time(unix_timestamp)
		return '%d-%02d-%02d' % [date.year, date.month, date.day]
	elif delta < MINUTE:
		return TRANSLATION_DUMMY.tr('%d seconds ago', 'TIME_SINCE_TIMESTAMP') % delta
	elif delta < HOUR:
		var mins := floori(delta / MINUTE)
		return TRANSLATION_DUMMY.tr_n(
			'%d minute ago',
			'%d minutes ago', mins, 'TIME_SINCE_TIMESTAMP') % mins
	elif delta < DAY:
		var hours := floori(delta / HOUR)
		return TRANSLATION_DUMMY.tr_n(
			'%d hour ago',
			'%d hours ago', hours, 'TIME_SINCE_TIMESTAMP') % hours
	else:
		var days := floori(delta / DAY)
		return TRANSLATION_DUMMY.tr_n(
			'%d day ago',
			'%d days ago', days, 'TIME_SINCE_TIMESTAMP') % days

static func is_compatibility_renderer() -> bool:
	return RenderingServer.get_current_rendering_method() == 'gl_compatibility'

static func generate_guid() -> String:
	return str(Time.get_ticks_msec()) + '-' + Crypto.new().generate_random_bytes(8).hex_encode()

static func ensure(condition: bool, message: String = '') -> bool:
	if not condition:
		if is_packaged():
			push_warning('Assertion failed' + ((': ' + message) if message else ''))
			print_stack()
		else:
			assert(false, message)
	return condition

static func get_hovered_control() -> Control:
	var vp := (Engine.get_main_loop() as SceneTree).root
	var hovered_control: Control = vp.gui_get_hovered_control()
	while hovered_control is SubViewportContainer:
		var sub_vp: SubViewport = null
		for child in hovered_control.get_children():
			if child is SubViewport:
				sub_vp = child
				break

		if sub_vp:
			var sub_hovered := sub_vp.gui_get_hovered_control()
			if sub_hovered:
				hovered_control = sub_hovered
			else:
				break
		else:
			break

	return hovered_control

static func _get_group_nodes_within(node: Node, group_name: String, output: Array) -> void:
	if node.is_inside_tree():  # In case we aren't in the tree.
		for child in node.get_tree().get_nodes_in_group(group_name):
			if node.is_ancestor_of(child):
				output.append(child)

static func _scale_font_size(label: RichTextLabel, is_tooltip: bool, default_size: int) -> void:
	var font_size := default_size
	if is_tooltip:
		font_size = roundi(font_size * GameSettings.Interface.tooltip_font_scale.value())
	else:
		font_size = roundi(font_size * GameSettings.Interface.paragraph_font_scale.value())
	label.add_theme_font_size_override('normal_font_size', font_size)
	label.add_theme_font_size_override('bold_font_size', font_size)
	label.add_theme_font_size_override('italics_font_size', font_size)
	label.add_theme_font_size_override('bold_italics_font_size', font_size)
	label.add_theme_font_size_override('mono_font_size', font_size)

## Predicate returns true if waiting should continue. The function return whether the timeout was hit.
static func wait_with_timeout(predicate: Callable, timeout: float) -> bool:
	var end_time := Time.get_ticks_usec() + timeout * 1_000_000.0
	while true:
		var result: Variant = predicate.call()
		assert(result is bool)
		if not result:
			return false
		if Time.get_ticks_usec() >= end_time:
			return true
		await (Engine.get_main_loop() as SceneTree).process_frame
	Utils.ensure(false)
	return false

static func coro_all(coros: Array[Callable]) -> Array:
	var helper := CoroutineHelper.new(coros, true)
	var result := await helper.start()
	helper.free.call_deferred()
	return result

static func coro_any(coros: Array[Callable]) -> Array:
	var helper := CoroutineHelper.new(coros, false)
	var result := await helper.start()
	helper.free.call_deferred()
	return result

class CoroutineHelper extends Object:
	signal finished

	var tasks: Array[Callable]
	var wait_for_all: bool

	var _tasks_completed := 0
	var _finished := false
	var _results: Array

	func _init(in_tasks: Array[Callable], in_wait_for_all: bool = true) -> void:
		tasks = in_tasks
		wait_for_all = in_wait_for_all
		_results.resize(tasks.size())

	func start() -> Array:
		for f in tasks:
			_start_task(f)
		await finished
		return _results.duplicate()  # To protect against races if not waiting for all.

	func _start_task(f: Callable) -> void:
		var wrapper := func() -> void:
			_results[tasks.find(f)] = await f.call()
			if _finished:
				return
			_tasks_completed += 1
			if not wait_for_all or _tasks_completed == tasks.size():
				_finished = true
				finished.emit()
		wrapper.call()

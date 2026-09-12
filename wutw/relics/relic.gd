@tool
class_name Relic
extends Term

enum State { PASSIVE, ACTIVE, EXPIRED }  # WARNING: Int values stored in savegames.
enum Rarity { COMMON, UNCOMMON, RARE, ACT_REWARD }

const RARITY_WEIGHTS: Dictionary[Relic.Rarity, float] = {
	Relic.Rarity.COMMON: 1.0,
	Relic.Rarity.UNCOMMON: 0.4,
	Relic.Rarity.RARE: 0.2,
	Relic.Rarity.ACT_REWARD: 1.0,  # Shouldn't ever appear in the same pool as other types.
}

static var RELICS_RESOURCEGROUP := AsyncLoadedResource.new('res://relics/resourcegroup_relics.tres')

signal state_changed
@warning_ignore('unused_signal')  # Used by subclasses.
signal counter_changed
@warning_ignore('unused_signal')  # Used by subclasses.
signal triggered

@export var relic_id: String
@export var default_name: String
@export_multiline var default_description: String
@export var flavor_text: String
@export var icon: Texture2D
@export var rarity: Rarity
@export var var_modifiers: Dictionary[RunVars.Var, int]
@export var must_be_unique: bool
@export var default_starting_state: State = State.PASSIVE

static var _all_relics: Array[Relic] = []
static var _relics_lookup: Dictionary[String, Relic] = {}

var _run: Run
var _state: State = State.PASSIVE:
	set(value):
		if value != _state:
			_state = value
			state_changed.emit()
var _modifier_key: String

static func get_all_relics() -> Array[Relic]:
	if not _all_relics:
		var group := RELICS_RESOURCEGROUP.get_loaded() as ResourceGroup
		for relic: Relic in group.load_all():
			if relic.relic_id:  # Not a base class.
				assert(relic.relic_id not in _relics_lookup)
				_all_relics.append(relic)
				_relics_lookup[relic.relic_id] = relic
	return _all_relics

static func get_relic_by_id(target_relic_id: String) -> Relic:
	get_all_relics()  # Ensure initialized.
	return _relics_lookup.get(target_relic_id, null)

static func get_fallback_relic() -> Relic:
	return load('res://relics/common/crystal_twig/relic_crystal_twig.tres') as Relic

func _init() -> void:
	term_categories.append(load('res://glossary/categories/termcategory_relic.tres'))

func get_relic_name(decorated: bool = false) -> String:
	if decorated:
		var name := tr(default_name)
		if rarity == Rarity.UNCOMMON:
			name += tr(' (Uncommon)')
		elif rarity == Rarity.RARE:
			name += tr(' (Rare)')
		return name
	else:
		return tr(default_name)

func get_description() -> String:
	return tr(default_description)

func get_state() -> State:
	return _state

func save_data() -> Dictionary:
	return {'state': _state, 'modifier_key': _modifier_key}

func load_data(encoded_data: Dictionary) -> void:  # Dictionary[String, int]
	_state = encoded_data.get('state') as State
	_modifier_key = encoded_data.get('modifier_key')

func get_current_counter() -> int:
	return 0

func get_max_counter() -> int:
	return 0

func get_term_id() -> String:
	return 'relic.' + relic_id

func get_term_name(long: bool) -> String:
	var img := '[img width=1.5em height=1.5em]%s[/img] ' % icon.resource_path
	return img + get_relic_name(long)

func get_markedup_description() -> String:
	return '<related_term:relic>' + get_description() + '\n\n' + tr('[i]“%s”[/i]') % tr(flavor_text)

func get_term_priority() -> int:
	return 10  # Very specific, so probably important.

func on_added(run: Run, apply_modifiers: bool) -> void:
	_run = run
	_state = default_starting_state
	if not _modifier_key:
		_modifier_key = '%x' % get_instance_id()
	if apply_modifiers:
		for type in var_modifiers:
			run.get_vars().add_modifier(type, var_modifiers[type], _get_modifier_tag(str(type)))
			# Special case: increasing max inspiration also heals inspiration.
			if type == RunVars.Var.MAX_INSPIRATION and var_modifiers[type] > 0:
				run.modify_inspiration(var_modifiers[type], Run.InspirationChangeReason.RELIC)

func on_removed() -> void:
	for type in var_modifiers:
		_run.get_vars().remove_modifier(_get_modifier_tag(str(type)))

func _get_modifier_tag(suffix: String = 'default') -> String:
	return 'relic-%s-%s' % [_modifier_key, suffix]  # instance_id, so copies stack

func _brief_wait() -> void:
	await _run.get_tree().create_timer(Utils.anim_duration(0.5)).timeout

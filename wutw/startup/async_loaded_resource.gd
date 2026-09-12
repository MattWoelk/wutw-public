class_name AsyncLoadedResource
extends RefCounted

# WARNING: These are created during static loading, so they shouldn't reference any high-level scripts.

enum LoadPhase { INITIAL, STARTUP, NORMAL, LIKELY, SPECULATIVE, UNLIKELY }

const WARN_IF_UNREADY := false

static var _pending_loads: Array[AsyncLoadedResource]  # Used by StaticResourceLoadAnalyzer (editor only)

var _path: String
var _phase: LoadPhase
var _result: Resource

func _init(path: String, _skip_if_demo: bool = false, phase: LoadPhase = LoadPhase.NORMAL) -> void:
	_path = path
	_phase = phase
	# skip_if_demo no longer used
	if OS.has_feature('editor'):
		_pending_loads.append(self)

func get_loaded() -> Resource:
	if not _result:
		if WARN_IF_UNREADY and not is_ready() and not Engine.is_editor_hint():
			push_warning('Requesting resource before ready: ', _path)
		_result = load(_path)
	return _result

func is_ready() -> bool:
	return ResourceLoader.has_cached(_path)

## Convenience methods.

func get_loaded_scene() -> PackedScene:
	return get_loaded() as PackedScene

func instantiate_loaded_scene() -> Node:
	return (get_loaded() as PackedScene).instantiate()

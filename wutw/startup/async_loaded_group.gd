class_name AsyncLoadedGroup
extends RefCounted

# WARNING: These are created during static loading, so they must not reference any high-level scripts.


static var _pending_loads: Array[AsyncLoadedGroup]

var _path: String
var _phase: AsyncLoadedResource.LoadPhase
var _group_result: ResourceGroup = null
var _results: Array[Resource] = []

func _init(path: String, _skip_if_demo: bool = false, phase: AsyncLoadedResource.LoadPhase = AsyncLoadedResource.LoadPhase.NORMAL) -> void:
	_path = path
	_phase = phase
	# skip_if_demo no longer used
	if OS.has_feature('editor'):
		_pending_loads.append(self)

func fetch_loaded(output: Array) -> void:
	if AsyncLoadedResource.WARN_IF_UNREADY and not is_ready() and not Engine.is_editor_hint():
		push_warning('Requesting resource group before ready: ', _path)
	if not _results:
		if not _group_result:
			_group_result = load(_path)  # Guaranteed cached.
		for entry in _group_result.paths:
			_results.append(load(entry))
	output.assign(_results)

func get_loaded() -> Array[Resource]:
	var output: Array[Resource]
	fetch_loaded(output)
	return output

func is_ready() -> bool:
	if _results:
		return true
	assert(not _group_result)
	if not ResourceLoader.has_cached(_path):
		return false
	_group_result = load(_path)  # Guaranteed cached.
	for entry in _group_result.paths:
		if not ResourceLoader.has_cached(entry):
			return false
	return true

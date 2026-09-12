class_name StaticResourceLoadAnalyzer
extends Resource

# All strings are resource paths.
var _roots: Array[String]
var _dependencies: Dictionary[String, Array]  # Array[String]
var _earliest_phase: Dictionary[String, AsyncLoadedResource.LoadPhase]

func run() -> ResourceLoadPlan:
	# Load all scripts.
	_load_all_scripts()

	# For all root resources/groups, record the earlier phase that needs them.
	for async_resource in AsyncLoadedResource._pending_loads:
		_roots.append(async_resource._path)
		_earliest_phase[async_resource._path] = mini(
			async_resource._phase, _earliest_phase.get(
				async_resource._path, AsyncLoadedResource.LoadPhase.UNLIKELY) as int) as AsyncLoadedResource.LoadPhase
	for async_group in AsyncLoadedGroup._pending_loads:
		_roots.append(async_group._path)
		_earliest_phase[async_group._path] = mini(
			async_group._phase, _earliest_phase.get(
				async_group._path, AsyncLoadedResource.LoadPhase.UNLIKELY) as int) as AsyncLoadedResource.LoadPhase

	# Recursively, for each resource, construct a dependencies list.
	for root in _roots:
		_fill_dependencies(root)

	# Recursively, for each resource, propagate the earlist phase to its dependencies.
	for root in _roots:
		_propagate_phase(root, _earliest_phase[root])

	# Force all scripts to the earliest phase. In practice, most of these will already be loaded.
	for path in _earliest_phase:
		if path.ends_with('.gd'):
			_earliest_phase[path] = AsyncLoadedResource.LoadPhase.INITIAL

	# Order the loads into batches, grouped by phase (essentiall a DAG).
	var result := ResourceLoadPlan.new()
	var assigned: Dictionary[String, bool]
	for phase_int in range(AsyncLoadedResource.LoadPhase.UNLIKELY as int + 1):
		var phase := phase_int as AsyncLoadedResource.LoadPhase
		var phase_resource_list := LoadPhaseResourceList.new()
		var phase_resources := _get_all_resources_by_phase(phase)
		while phase_resources:
			var leaves: Dictionary[String, bool]
			for path in phase_resources:
				assert(path not in leaves)
				var is_leaf := true
				for dependency: String in _dependencies[path]:
					if dependency not in assigned:
						is_leaf = false
						break
				if is_leaf:
					leaves[path] = true
			assert(leaves)
			var batch := ResourceLoadBatch.new()
			for leaf in leaves:
				batch.paths.append(leaf)
				assigned[leaf] = true
				phase_resources.erase(leaf)
			phase_resource_list.batches.append(batch)
		result.phases.append(phase_resource_list)

	return result

func _fill_dependencies(root: String) -> void:
	if root in _dependencies:
		return

	assert(root)
	var f := FileAccess.open(root,FileAccess.READ)
	assert(f)
	f.close()

	_dependencies[root] = []
	for dependency in ResourceLoader.get_dependencies(root):
		var dependency_path := dependency.split('::')[-1]
		assert(dependency_path.begins_with('res://'))
		_dependencies[root].append(dependency_path)
	if root.ends_with('resourcegroup.tres'):
		for dependency_path in (load(root) as ResourceGroup).paths:
			assert(dependency_path.begins_with('res://'))
			_dependencies[root].append(dependency_path)
	for dependency_path: String in _dependencies[root]:
		_fill_dependencies(dependency_path)

func _propagate_phase(root: String, phase: AsyncLoadedResource.LoadPhase) -> void:
	if root in _earliest_phase:
		_earliest_phase[root] = mini(phase, _earliest_phase[root]) as AsyncLoadedResource.LoadPhase
	else:
		_earliest_phase[root] = phase

	for dependency: String in _dependencies[root]:
		_propagate_phase(dependency, phase)

func _get_all_resources_by_phase(phase: AsyncLoadedResource.LoadPhase) -> Array[String]:
	var result: Array[String]
	for path in _earliest_phase:
		if _earliest_phase[path] == phase:
			result.append(path)
	return result

func _load_all_scripts(path: String = 'res://') -> void:
	for dir in DirAccess.get_directories_at(path):
		if not dir.begins_with('_'):
			_load_all_scripts(path + '/' + dir)
	for file in DirAccess.get_files_at(path):
		if file.ends_with('.gd'):
			load(path + '/' + file)

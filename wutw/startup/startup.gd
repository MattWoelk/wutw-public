class_name Startup
extends Node

signal _load_finished_initial
signal _load_finished_startup
signal _load_finished_normal
signal _load_finished_likely
signal _load_finished_speculative
signal _load_finished_unlikely

const PLAN_PATH := 'res://_generated/resource_load_plan.tres'
const MAX_THREADS := -1

var _finished: Dictionary[AsyncLoadedResource.LoadPhase, bool]
var _resource_cache: Dictionary[String, Resource]

func _ready() -> void:
	# Equivalent to Utils.is_running_in_single_scene_mode(), but must avoid high level references.
	if (Engine.get_main_loop() as SceneTree).current_scene.name != 'Main':  # HACK
		for i: int in AsyncLoadedResource.LoadPhase.values():
			_finished[i] = true
		_load_finished_initial.emit()
		_load_finished_startup.emit()
		_load_finished_normal.emit()
		_load_finished_likely.emit()
		_load_finished_speculative.emit()
		_load_finished_unlikely.emit()
		return

	print('STARTUP AT: %.3fs' % (Time.get_ticks_msec() / 1000.0))

	await get_tree().process_frame  # Wait for all scripts to load naturally.

	var plan: ResourceLoadPlan
	if OS.has_feature('editor'):
		var start_time := Time.get_ticks_msec()
		var analyzer := StaticResourceLoadAnalyzer.new()
		plan = analyzer.run()
		print('DEPENDENCY ANALYSIS TOOK: %.3fs' % ((Time.get_ticks_msec() - start_time) / 1000.0))
		ResourceSaver.save(plan, PLAN_PATH)
	else:
		plan = load(PLAN_PATH)

	print('STARTED LOADING AT: %.3fs' % (Time.get_ticks_msec() / 1000.0))
	await _load_phase(plan, AsyncLoadedResource.LoadPhase.INITIAL)
	_load_finished_initial.emit()
	await _load_phase(plan, AsyncLoadedResource.LoadPhase.STARTUP)
	_load_finished_startup.emit()
	await _load_phase(plan, AsyncLoadedResource.LoadPhase.NORMAL)
	_load_finished_normal.emit()
	await _load_phase(plan, AsyncLoadedResource.LoadPhase.LIKELY)
	_load_finished_likely.emit()
	await _load_phase(plan, AsyncLoadedResource.LoadPhase.SPECULATIVE)
	_load_finished_speculative.emit()
	await _load_phase(plan, AsyncLoadedResource.LoadPhase.UNLIKELY)
	_load_finished_unlikely.emit()

func wait_loaded_initial() -> void:
	if _finished.get(AsyncLoadedResource.LoadPhase.INITIAL, false):
		return
	else:
		await _load_finished_initial

func wait_loaded_startup() -> void:
	if _finished.get(AsyncLoadedResource.LoadPhase.STARTUP, false):
		return
	else:
		await _load_finished_startup

func wait_loaded_normal() -> void:
	if _finished.get(AsyncLoadedResource.LoadPhase.NORMAL, false):
		return
	else:
		await _load_finished_normal

func wait_loaded_likely() -> void:
	if _finished.get(AsyncLoadedResource.LoadPhase.NORMAL, false):
		return
	else:
		await _load_finished_likely

func wait_loaded_speculative() -> void:
	if _finished.get(AsyncLoadedResource.LoadPhase.SPECULATIVE, false):
		return
	else:
		await _load_finished_speculative

func wait_loaded_unlikely() -> void:
	if _finished.get(AsyncLoadedResource.LoadPhase.UNLIKELY, false):
		return
	else:
		await _load_finished_unlikely

func is_phase_finished(phase: AsyncLoadedResource.LoadPhase) -> bool:
	return _finished.get(phase, false)

func _load_phase(plan: ResourceLoadPlan, phase: AsyncLoadedResource.LoadPhase) -> void:
	var phase_resource_list := plan.phases[phase]
	var task_id := WorkerThreadPool.add_task(_load_phase_task.bind(phase, phase_resource_list), true)
	while not WorkerThreadPool.is_task_completed(task_id):
		await get_tree().process_frame
	WorkerThreadPool.wait_for_task_completion(task_id)
	_finished[phase] = true

func _load_phase_task(phase: AsyncLoadedResource.LoadPhase, phase_resource_list: LoadPhaseResourceList) -> void:
	var start_time := Time.get_ticks_msec()

	var batches := phase_resource_list.batches
	if OS.has_feature('editor'):
		# To speed up during development, merge all batches.
		batches = [ResourceLoadBatch.new()]
		for batch in phase_resource_list.batches:
			batches[0].paths.append_array(batch.paths)

	for batch in batches:
		var batch_start_time := Time.get_ticks_msec()
		var paths: Array[String]
		for path in batch.paths:
			if ResourceLoader.has_cached(path):
				_resource_cache[path] = load(path)  # ~free
				print_verbose('  Skipping %s.' % path)
			else:
				_resource_cache[path] = null
				paths.append(path)
		if paths.is_empty():
			print_verbose('  Skipping loaded batch.')
			continue
		elif paths.size() == 1:
			_resource_cache[paths[0]] = load(paths[0])
			print_verbose('  Inlined load finished in %.3fs.' % [
				((Time.get_ticks_msec() - batch_start_time) / 1000.0)])
		else:
			var group_id := WorkerThreadPool.add_group_task(
					_load_resource.bind(paths), paths.size(), MAX_THREADS, false)
			WorkerThreadPool.wait_for_group_task_completion(group_id)
			print_verbose('  Batch of %d finished in %.3fs.' % [paths.size(),
				((Time.get_ticks_msec() - batch_start_time) / 1000.0)])

	print('DONE LOADING %s: %.3fs' % [
		AsyncLoadedResource.LoadPhase.keys()[phase],
		((Time.get_ticks_msec() - start_time) / 1000.0)])

func _load_resource(index: int, batch: Array[String]) -> void:
	var path := batch[index]
	_resource_cache[path] = load(path)

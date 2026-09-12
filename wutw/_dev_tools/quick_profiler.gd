class_name QuickProfiler
extends RefCounted

var enabled : bool = true

var _active: Dictionary[String, int] = {}
var _data: Dictionary[String, Dictionary] = {}

func reset() -> void:
	_active.clear()
	_data.clear()

func begin(label: String) -> void:
	if not enabled:
		return
	_active[label] = Time.get_ticks_usec()

func end(label: String) -> void:
	if not enabled:
		return
	if not _active.has(label):
		push_warning('Profiler: end(%s) called without begin(%s)' % [label, label])
		return
	var now := Time.get_ticks_usec()
	var duration := now - _active[label]
	_active.erase(label)

	if not _data.has(label):
		_data[label] = { total = 0, count = 0 }
	_data[label]['total'] += duration
	_data[label]['count'] += 1

func report(title: String = 'Profiler Report') -> void:
	if not enabled:
		return
	print('=== %s ===' % title)
	for label: String in _data.keys():
		var total := _data[label]['total'] as int
		var count := _data[label]['count'] as int
		@warning_ignore('integer_division')
		var avg := total / count
		print('%s: %dms total (%d calls, avg %dms)' % [label, total / 1000.0, count, avg / 1000.0])
	print('===')

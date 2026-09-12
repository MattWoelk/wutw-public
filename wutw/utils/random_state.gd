class_name RandomState
extends RefCounted

# Only used when loading savegames that contain serialized versions.
var _is_legacy: bool = false
var _legacy_rng: RandomNumberGenerator

# V2 Random state (Xoshiro128++).
var _s0: int
var _s1: int
var _s2: int
var _s3: int

func _init(custom_seed: int = 0, use_legacy: bool = false) -> void:
	_legacy_rng = RandomNumberGenerator.new()
	_is_legacy = use_legacy
	reseed(custom_seed)

func is_legacy() -> bool:
	return _is_legacy

func reseed(custom_seed: int = 0) -> void:
	if _is_legacy:
		if custom_seed:
			_legacy_rng.seed = hash(custom_seed)
		else:
			_legacy_rng.randomize()
	else:
		_v2_seed(custom_seed)

func snapshot(advance: bool = false) -> RandomState:
	var new_random := RandomState.new()
	new_random._is_legacy = _is_legacy
	new_random._legacy_rng.state = _legacy_rng.state
	new_random._s0 = _s0
	new_random._s1 = _s1
	new_random._s2 = _s2
	new_random._s3 = _s3
	if advance:
		new_random.rand_float()
	return new_random

func rand_int(min_val: int, max_val: int) -> int:
	if _is_legacy:
		return _legacy_rng.randi_range(min_val, max_val)
	else:
		return _v2_rand_int(min_val, max_val)

func rand_float(min_val: float = 0, max_val: float = 1) -> float:
	if _is_legacy:
		return _legacy_rng.randf_range(min_val, max_val)
	else:
		return _v2_rand_float(min_val, max_val)

func rand_bool() -> bool:
	if _is_legacy:
		return _legacy_rng.randf() < 0.5
	else:
		return _v2_rand_float() < 0.5

func pick(array: Array) -> Variant:
	if array.is_empty():
		return null
	else:
		return array[rand_int(0, array.size() - 1)]

func pick_n(array: Array, n: int, allow_repeats: bool = false) -> Array:
	if n == 0:
		return []
	elif n == 1:
		return [] if array.is_empty() else [pick(array)]
	else:
		var pool := array if allow_repeats else array.duplicate()  # Expensive, but prob insignificant.
		var result := []
		for i in range(n):
			if pool.is_empty():
				break
			var index := rand_int(0, pool.size() - 1)
			result.append(pool[index])
			if not allow_repeats:
				pool.remove_at(index)
		return result

func pick_weighted_array(weights: Array[float], n: int = 1, allow_repeats: bool = false) -> Array:  # Array[int]
	# More efficient to not use the dict version, but then we'd have to duplicate the edge cases.
	var weights_dict: Dictionary[int, float] = {}
	for i in range(weights.size()):
		weights_dict[i] = weights[i]
	return pick_weighted_dict(weights_dict, n, allow_repeats)

func pick_weighted_dict(weights: Dictionary, n: int = 1, allow_repeats: bool = false) -> Array:
	if weights.is_empty() or n == 0:
		return []
	var keys := []
	var weight_values: Array[float] = []
	for key: Variant in weights:
		keys.append(key)
		weight_values.append(max(weights[key], 1e-10))  # Unlike rand_weighted(), 0 means minimum, not never.
	var result := []
	for i: int in min(n, weight_values.size()):
		var index: int
		if _is_legacy:
			index = _legacy_rng.rand_weighted(weight_values)
		else:
			index = _v2_rand_weighted(weight_values)
		result.append(keys[index])
		if not allow_repeats:
			keys.remove_at(index)
			weight_values.remove_at(index)
	return result

func shuffle(array: Array) -> void:
	# Identical to Array.shuffle(), but with an explicit seed.
	var n := array.size()
	if n < 2:
		return
	for i in range(n - 1, 1, -1):
		var j := rand_int(0, i)
		var tmp: Variant = array[j]
		array[j] = array[i]
		array[i] = tmp

func encode() -> String:
	if _is_legacy:
		# Must preserve 64-bit precision even when encoded in JSON.
		return str(_legacy_rng.state)
	else:
		return 'v2:' + _v2_encode()

func decode(encoded: String) -> void:
	if encoded.begins_with('v2:'):
		_is_legacy = false
		_v2_decode(encoded.trim_prefix('v2:'))
	else:
		_is_legacy = true
		_legacy_rng.state = encoded.to_int()

# V2: Xoshiro128++ (& 0xFFFFFFFF everywhere to force 32-bit)

func _v2_seed(custom_seed: int) -> void:
	var seed_val: int
	if custom_seed:
		seed_val = hash(custom_seed) & 0xFFFFFFFF
	else:
		seed_val = randi() & 0xFFFFFFFF

	# SplitMix32 to ensure the starting state has good entropy.
	var current_state: int = seed_val
	var s_list: Array[int] = []

	for i in range(4):
		current_state = (current_state + 0x9E3779B9) & 0xFFFFFFFF
		var z: int = current_state
		z = (z ^ (z >> 16)) * 0x85EBCA6B
		z &= 0xFFFFFFFF
		z = (z ^ (z >> 13)) * 0xC2B2AE35
		z &= 0xFFFFFFFF
		s_list.append((z ^ (z >> 16)) & 0xFFFFFFFF)

	_s0 = s_list[0]
	_s1 = s_list[1]
	_s2 = s_list[2]
	_s3 = s_list[3]

func _v2_rotl(x: int, k: int) -> int:
	return ((x << k) & 0xFFFFFFFF) | (x >> (32 - k))

func _v2_next() -> int:
	var result: int = (_v2_rotl((_s0 + _s3) & 0xFFFFFFFF, 7) + _s0) & 0xFFFFFFFF
	var t: int = (_s1 << 9) & 0xFFFFFFFF

	_s2 ^= _s0
	_s3 ^= _s1
	_s1 ^= _s2
	_s0 ^= _s3

	_s2 ^= t
	_s3 = _v2_rotl(_s3, 11)

	return result

func _v2_rand_int(min_val: int, max_val: int) -> int:
	if min_val > max_val:
		var temp: int = min_val
		min_val = max_val
		max_val = temp

	var range_len: int = max_val - min_val + 1
	if range_len <= 1:
		return min_val
	return min_val + (_v2_next() % range_len)

func _v2_rand_float(min_val: float = 0.0, max_val: float = 1.0) -> float:
	var f: float = _v2_next() / 4294967295.0
	return min_val + (f * (max_val - min_val))

func _v2_rand_weighted(weights: Array[float]) -> int:
	var total_weight: float = 0.0
	for w in weights:
		total_weight += w

	var r: float = _v2_rand_float(0.0, total_weight)
	for i in range(weights.size()):
		r -= weights[i]
		if r <= 0.0:
			return i
	return weights.size() - 1

func _v2_encode() -> String:
	return '%d,%d,%d,%d' % [_s0, _s1, _s2, _s3]

func _v2_decode(data: String) -> void:
	var parts := data.split(',')
	if Utils.ensure(parts.size() == 4):
		_s0 = parts[0].to_int()
		_s1 = parts[1].to_int()
		_s2 = parts[2].to_int()
		_s3 = parts[3].to_int()

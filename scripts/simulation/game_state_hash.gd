class_name MoonGoonsGameStateHash
extends RefCounted
## Creates a stable SHA-256 digest from canonical authoritative state.
## Feed only deterministic simulation data, never camera, VFX, audio, or UI state.

static func hash_snapshot(snapshot: Dictionary) -> String:
	var canonical := canonicalize(snapshot)
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(canonical.to_utf8_buffer())
	return context.finish().hex_encode()

static func canonicalize(value: Variant) -> String:
	if value is Dictionary:
		var dictionary_value: Dictionary = value as Dictionary
		var keys: Array[String] = []
		for key: Variant in dictionary_value.keys():
			keys.append(String(key))
		keys.sort()
		var parts: Array[String] = []
		for key: String in keys:
			parts.append("%s:%s" % [JSON.stringify(key), canonicalize(dictionary_value[key])])
		return "{%s}" % ",".join(parts)
	if value is Array:
		var parts: Array[String] = []
		for entry: Variant in value as Array:
			parts.append(canonicalize(entry))
		return "[%s]" % ",".join(parts)
	return JSON.stringify(value)

static func make_authoritative_snapshot(
	turn_id: int,
	simulation_tick: int,
	resources_by_player: Dictionary,
	units: Array[Dictionary],
	buildings: Array[Dictionary],
	objectives: Dictionary,
	random_seed_state: int
) -> Dictionary:
	return {
		"turn_id": turn_id,
		"simulation_tick": simulation_tick,
		"resources_by_player": resources_by_player,
		"units": units,
		"buildings": buildings,
		"objectives": objectives,
		"random_seed_state": random_seed_state
	}

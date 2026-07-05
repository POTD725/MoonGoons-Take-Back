class_name MoonGoonsSaveSystem
extends RefCounted
## Local profile and mission-snapshot storage with checksums and backup recovery.
## This system provides integrity verification, not cryptographic secrecy.

const SAVE_DIRECTORY := "user://saves"
const PROFILE_FILE := "profile_save.json"
const SLOT_PREFIX := "slot_"
const SLOT_SUFFIX := ".mgcs"
const SNAPSHOT_MAGIC := PackedByteArray([77, 71, 67, 83]) # MGCS
const SNAPSHOT_FORMAT_VERSION := 1
const CHECKSUM_SIZE_BYTES := 32

var errors: Array[String] = []

func ensure_save_directory() -> bool:
	var absolute_path := ProjectSettings.globalize_path(SAVE_DIRECTORY)
	var result := DirAccess.make_dir_recursive_absolute(absolute_path)
	if result != OK:
		errors.append("Could not create save directory: %s" % absolute_path)
		return false
	return true

func save_profile(profile: Dictionary) -> bool:
	errors.clear()
	if not ensure_save_directory():
		return false
	var normalized := profile.duplicate(true)
	normalized["save_version"] = String(normalized.get("save_version", "1.0.0"))
	normalized["last_updated_epoch"] = int(Time.get_unix_time_from_system())
	var payload_text := JSON.stringify(normalized)
	var envelope := {
		"format": "MoonGoonsProfileEnvelope",
		"payload": normalized,
		"checksum_sha256": _hash_text(payload_text)
	}
	return _write_text_with_backup(_profile_path(), JSON.stringify(envelope, "  "))

func load_profile(default_profile: Dictionary = {}) -> Dictionary:
	errors.clear()
	var result := _load_profile_from_path(_profile_path())
	if bool(result.get("ok", false)):
		return result.get("profile", {}) as Dictionary
	var backup_result := _load_profile_from_path(_profile_path() + ".bak")
	if bool(backup_result.get("ok", false)):
		errors.append("Primary profile failed integrity validation. Recovered backup profile.")
		return backup_result.get("profile", {}) as Dictionary
	if not default_profile.is_empty():
		return default_profile.duplicate(true)
	return {}

func save_snapshot(slot_index: int, engine_build_id: int, simulation_tick: int, snapshot: Dictionary) -> bool:
	errors.clear()
	if slot_index < 0 or slot_index > 9:
		errors.append("Save slot must be between 0 and 9.")
		return false
	if not ensure_save_directory():
		return false
	var raw_payload := JSON.stringify(snapshot).to_utf8_buffer()
	var compressed_payload := Compression.compress(raw_payload, Compression.MODE_DEFLATE)
	var compression_enabled := not compressed_payload.is_empty()
	var stored_payload := compressed_payload if compression_enabled else raw_payload
	var path := _slot_path(slot_index)
	_backup_existing_file(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		errors.append("Could not open snapshot for writing: %s" % path)
		return false
	file.store_buffer(SNAPSHOT_MAGIC)
	file.store_32(SNAPSHOT_FORMAT_VERSION)
	file.store_32(engine_build_id)
	file.store_64(simulation_tick)
	file.store_8(1 if compression_enabled else 0)
	file.store_32(raw_payload.size())
	file.store_32(stored_payload.size())
	file.store_buffer(stored_payload)
	file.store_buffer(_hash_bytes(raw_payload))
	file.close()
	return true

func load_snapshot(slot_index: int, expected_engine_build_id: int = -1) -> Dictionary:
	errors.clear()
	if slot_index < 0 or slot_index > 9:
		return {"ok": false, "error": "Save slot must be between 0 and 9."}
	var result := _load_snapshot_from_path(_slot_path(slot_index), expected_engine_build_id)
	if bool(result.get("ok", false)):
		return result
	var backup_result := _load_snapshot_from_path(_slot_path(slot_index) + ".bak", expected_engine_build_id)
	if bool(backup_result.get("ok", false)):
		errors.append("Primary mission snapshot failed. Recovered backup snapshot.")
		return backup_result
	return result

func delete_snapshot(slot_index: int) -> bool:
	var path := _slot_path(slot_index)
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK

func _load_profile_from_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "Profile file not found."}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {"ok": false, "error": "Profile envelope is not valid JSON."}
	var envelope: Dictionary = parsed as Dictionary
	var profile: Variant = envelope.get("payload")
	if not (profile is Dictionary):
		return {"ok": false, "error": "Profile payload is missing."}
	var checksum := String(envelope.get("checksum_sha256", ""))
	var expected_checksum := _hash_text(JSON.stringify(profile))
	if checksum.is_empty() or checksum != expected_checksum:
		return {"ok": false, "error": "Profile checksum verification failed."}
	return {"ok": true, "profile": (profile as Dictionary).duplicate(true)}

func _load_snapshot_from_path(path: String, expected_engine_build_id: int) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "Snapshot file not found."}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not open snapshot."}
	if file.get_length() < 4 + 4 + 4 + 8 + 1 + 4 + 4 + CHECKSUM_SIZE_BYTES:
		return {"ok": false, "error": "Snapshot is too small to be valid."}
	var magic := file.get_buffer(4)
	if magic != SNAPSHOT_MAGIC:
		return {"ok": false, "error": "Snapshot magic header is invalid."}
	var format_version := file.get_32()
	if format_version != SNAPSHOT_FORMAT_VERSION:
		return {"ok": false, "error": "Unsupported snapshot format version."}
	var build_id := file.get_32()
	if expected_engine_build_id >= 0 and build_id != expected_engine_build_id:
		return {"ok": false, "error": "Snapshot build does not match this game build."}
	var simulation_tick := file.get_64()
	var compression_enabled := file.get_8() == 1
	var raw_size := file.get_32()
	var stored_size := file.get_32()
	if raw_size <= 0 or stored_size <= 0 or stored_size > file.get_length():
		return {"ok": false, "error": "Snapshot payload sizes are invalid."}
	var stored_payload := file.get_buffer(stored_size)
	var expected_checksum := file.get_buffer(CHECKSUM_SIZE_BYTES)
	var raw_payload := Compression.decompress(stored_payload, raw_size, Compression.MODE_DEFLATE) if compression_enabled else stored_payload
	if raw_payload.size() != raw_size:
		return {"ok": false, "error": "Snapshot decompression failed."}
	if _hash_bytes(raw_payload) != expected_checksum:
		return {"ok": false, "error": "Snapshot checksum verification failed."}
	var parsed: Variant = JSON.parse_string(raw_payload.get_string_from_utf8())
	if not (parsed is Dictionary):
		return {"ok": false, "error": "Snapshot payload is not a JSON object."}
	return {
		"ok": true,
		"engine_build_id": build_id,
		"simulation_tick": simulation_tick,
		"snapshot": (parsed as Dictionary).duplicate(true)
	}

func _backup_existing_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var original := FileAccess.get_file_as_bytes(path)
	var backup := FileAccess.open(path + ".bak", FileAccess.WRITE)
	if backup != null:
		backup.store_buffer(original)
		backup.close()

func _write_text_with_backup(path: String, content: String) -> bool:
	_backup_existing_file(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		errors.append("Could not write file: %s" % path)
		return false
	file.store_string(content)
	file.close()
	return true

func _profile_path() -> String:
	return "%s/%s" % [SAVE_DIRECTORY, PROFILE_FILE]

func _slot_path(slot_index: int) -> String:
	return "%s/%s%d%s" % [SAVE_DIRECTORY, SLOT_PREFIX, slot_index, SLOT_SUFFIX]

func _hash_text(value: String) -> String:
	return _hash_bytes(value.to_utf8_buffer()).hex_encode()

func _hash_bytes(value: PackedByteArray) -> PackedByteArray:
	var hashing_context := HashingContext.new()
	hashing_context.start(HashingContext.HASH_SHA256)
	hashing_context.update(value)
	return hashing_context.finish()

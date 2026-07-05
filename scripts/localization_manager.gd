class_name MoonGoonsLocalizationManager
extends RefCounted
## Lightweight JSON localization lookup. UI reads keys; it does not hardcode player-facing strings.

var current_language := "en"
var fallback_language := "en"
var _catalog: Dictionary = {}
var errors: Array[String] = []

func load_catalog(path: String = "res://data/localization.json") -> bool:
	errors.clear()
	_catalog.clear()
	if not FileAccess.file_exists(path):
		errors.append("Missing localization catalog: %s" % path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Could not open localization catalog: %s" % path)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		errors.append("Localization catalog must be a JSON object.")
		return false
	_catalog = parsed as Dictionary
	var meta: Dictionary = _catalog.get("meta", {})
	fallback_language = String(meta.get("default_language", "en"))
	if not has_language(current_language):
		current_language = fallback_language
	return true

func set_language(language_id: String) -> bool:
	if not has_language(language_id):
		return false
	current_language = language_id
	return true

func has_language(language_id: String) -> bool:
	var languages: Dictionary = _catalog.get("languages", {})
	return languages.has(language_id)

func tr_key(key_path: String, substitutions: Dictionary = {}) -> String:
	var translated := _lookup(current_language, key_path)
	if translated.is_empty() and current_language != fallback_language:
		translated = _lookup(fallback_language, key_path)
	if translated.is_empty():
		return "[%s]" % key_path
	for token: Variant in substitutions:
		translated = translated.replace("{%s}" % String(token), String(substitutions[token]))
	return translated

func _lookup(language_id: String, key_path: String) -> String:
	var languages: Dictionary = _catalog.get("languages", {})
	var node: Variant = languages.get(language_id, {})
	for part: String in key_path.split(".", false):
		if not (node is Dictionary):
			return ""
		node = (node as Dictionary).get(part)
	return String(node) if node is String else ""

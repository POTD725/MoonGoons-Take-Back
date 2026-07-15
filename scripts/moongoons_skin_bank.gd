extends Node
## Loads the established MoonGoons PNG package when present.
## Scenes keep their procedural art as a safety net, but production exports
## sync these files before Godot imports the project.

const ROOT: String = "res://assets/skins/moongoons/"
const SKINS: Dictionary = {
	"command_nexus": ROOT + "command_nexus.png",
	"tactical_armory": ROOT + "tactical_armory.png",
	"machine_shop": ROOT + "machine_shop.png",
	"builder_drone": ROOT + "builder_drone.png",
	"patrol_deputy": ROOT + "patrol_deputy.png",
	"shield_deputy": ROOT + "shield_deputy.png",
	"sentry_turret": ROOT + "sentry_turret.png",
	"pulse_cannon": ROOT + "pulse_cannon.png",
	"ore_deposit": ROOT + "ore_deposit.png",
	"evidence_cache": ROOT + "evidence_cache.png",
	"cargo_crate": ROOT + "cargo_crate.png",
	"wrecked_shuttle": ROOT + "wrecked_shuttle.png",
	"cargo_wall": ROOT + "cargo_wall.png",
	"crater": ROOT + "crater.png"
}

var _cache: Dictionary = {}
var _missing: Array[String] = []

func _ready() -> void:
	validate_assets()

func get_texture(skin_name: String) -> Texture2D:
	if _cache.has(skin_name):
		return _cache[skin_name] as Texture2D
	if not SKINS.has(skin_name):
		return null
	var path: String = String(SKINS[skin_name])
	if not ResourceLoader.exists(path):
		if not _missing.has(skin_name):
			_missing.append(skin_name)
		return null
	var texture: Texture2D = load(path) as Texture2D
	if texture != null:
		_cache[skin_name] = texture
		_missing.erase(skin_name)
	return texture

func validate_assets() -> void:
	_cache.clear()
	_missing.clear()
	for skin_value: Variant in SKINS.keys():
		var skin_name: String = String(skin_value)
		var texture: Texture2D = get_texture(skin_name)
		if texture == null and not _missing.has(skin_name):
			_missing.append(skin_name)

func assets_ready() -> bool:
	return _missing.is_empty()

func ready_count() -> int:
	return SKINS.size() - _missing.size()

func status_text() -> String:
	return "MOONGOONS SKINS %d/%d" % [ready_count(), SKINS.size()]

func missing_assets() -> Array[String]:
	return _missing.duplicate()

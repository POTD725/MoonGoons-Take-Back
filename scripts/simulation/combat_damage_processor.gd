class_name MoonGoonsCombatDamageProcessor
extends RefCounted
## Deterministic damage resolution, armor modifiers, arrests, and combat events.

signal entity_damaged(attacker_id: String, target_id: String, damage_fp: int, remaining_hp_fp: int)
signal entity_destroyed(attacker_id: String, target_id: String)
signal unit_arrested(attacker_id: String, target_id: String, evidence_awarded: int)

const DAMAGE_MATRIX: Dictionary = {
	"kinetic": {"light_infantry": 1000, "heavy_infantry": 750, "heavy_mechanical": 500},
	"energy": {"light_infantry": 750, "heavy_infantry": 1250, "heavy_mechanical": 1000},
	"bio_acid": {"light_infantry": 1250, "heavy_infantry": 500, "heavy_mechanical": 1500}
}
const PEACEKEEPER_ARREST_CHANCE_PERCENT := 15
const ARREST_EVIDENCE_REWARD := 25

class CombatEntity:
	var entity_id: String
	var owner_player_id: int
	var faction_id: String
	var armor_class: String
	var max_hp_fp: int
	var current_hp_fp: int
	var is_organic := true
	var is_alive := true
	var is_arrested := false
	var status_flags: Dictionary = {}

	func _init(
		initial_entity_id: String,
		initial_owner_player_id: int,
		initial_faction_id: String,
		initial_armor_class: String,
		initial_max_hp_fp: int,
		initial_is_organic: bool = true
	) -> void:
		entity_id = initial_entity_id
		owner_player_id = initial_owner_player_id
		faction_id = initial_faction_id
		armor_class = initial_armor_class
		max_hp_fp = initial_max_hp_fp
		current_hp_fp = initial_max_hp_fp
		is_organic = initial_is_organic

	func serialize_state() -> Dictionary:
		return {
			"entity_id": entity_id,
			"owner_player_id": owner_player_id,
			"faction_id": faction_id,
			"armor_class": armor_class,
			"max_hp_fp": max_hp_fp,
			"current_hp_fp": current_hp_fp,
			"is_organic": is_organic,
			"is_alive": is_alive,
			"is_arrested": is_arrested,
			"status_flags": status_flags.duplicate(true)
		}

var _resource_bank: MoonGoonsResourceBank
var _entities_by_id: Dictionary = {}

func _init(resource_bank: MoonGoonsResourceBank) -> void:
	_resource_bank = resource_bank

func register_entity(entity: CombatEntity) -> bool:
	if entity.entity_id.is_empty() or _entities_by_id.has(entity.entity_id):
		return false
	_entities_by_id[entity.entity_id] = entity
	return true

func get_entity(entity_id: String) -> CombatEntity:
	var entity: Variant = _entities_by_id.get(entity_id)
	if entity is CombatEntity:
		return entity as CombatEntity
	return null

func get_entity_snapshot(entity_id: String) -> Dictionary:
	var entity := get_entity(entity_id)
	return entity.serialize_state() if entity != null else {}

func get_all_entity_snapshots() -> Array[Dictionary]:
	var entity_ids: Array[String] = []
	for raw_id: Variant in _entities_by_id.keys():
		entity_ids.append(String(raw_id))
	entity_ids.sort()
	var result: Array[Dictionary] = []
	for entity_id: String in entity_ids:
		result.append(get_entity_snapshot(entity_id))
	return result

func apply_weapon_impact(
	attacker_id: String,
	attacker_faction_id: String,
	attacker_player_id: int,
	target_id: String,
	damage_type: String,
	raw_damage_fp: int,
	random_source: MoonGoonsGameRand = null,
	force_detain: bool = false
) -> Dictionary:
	var target := get_entity(target_id)
	if target == null or not target.is_alive or target.is_arrested:
		return {"ok": false, "reason": "invalid_target"}
	var modifier_fp := _damage_modifier_fp(damage_type, target.armor_class)
	var final_damage_fp := MoonGoonsFixedMath.multiply(raw_damage_fp, modifier_fp)
	target.current_hp_fp = maxi(0, target.current_hp_fp - final_damage_fp)
	entity_damaged.emit(attacker_id, target_id, final_damage_fp, target.current_hp_fp)
	if target.current_hp_fp > 0:
		return {"ok": true, "damage_fp": final_damage_fp, "result": "damaged"}
	if _should_arrest(attacker_faction_id, target, random_source, force_detain):
		_arrest_target(attacker_id, attacker_player_id, target)
		return {"ok": true, "damage_fp": final_damage_fp, "result": "arrested"}
	target.is_alive = false
	entity_destroyed.emit(attacker_id, target_id)
	return {"ok": true, "damage_fp": final_damage_fp, "result": "destroyed"}

func detain_target(attacker_id: String, attacker_player_id: int, target_id: String) -> bool:
	var target := get_entity(target_id)
	if target == null or not target.is_alive or not target.is_organic or target.is_arrested:
		return false
	if target.current_hp_fp > MoonGoonsFixedMath.from_float(0.25 * MoonGoonsFixedMath.to_float(target.max_hp_fp)):
		return false
	_arrest_target(attacker_id, attacker_player_id, target)
	return true

func apply_status(entity_id: String, status_id: String, duration_ticks: int, payload: Dictionary = {}) -> bool:
	var entity := get_entity(entity_id)
	if entity == null or not entity.is_alive:
		return false
	entity.status_flags[status_id] = {
		"remaining_ticks": maxi(0, duration_ticks),
		"payload": payload.duplicate(true)
	}
	return true

func process_status_tick() -> void:
	for entity_snapshot: Dictionary in get_all_entity_snapshots():
		var entity := get_entity(String(entity_snapshot.get("entity_id", "")))
		if entity == null:
			continue
		var expired: Array[String] = []
		for status_id: Variant in entity.status_flags:
			var state: Dictionary = entity.status_flags[status_id]
			var remaining := int(state.get("remaining_ticks", 0)) - 1
			if remaining <= 0:
				expired.append(String(status_id))
			else:
				state["remaining_ticks"] = remaining
				entity.status_flags[status_id] = state
		for status_id: String in expired:
			entity.status_flags.erase(status_id)

func restore_state(snapshots: Array[Dictionary]) -> void:
	_entities_by_id.clear()
	for snapshot: Dictionary in snapshots:
		var entity_id := String(snapshot.get("entity_id", ""))
		if entity_id.is_empty():
			continue
		var entity := CombatEntity.new(
			entity_id,
			int(snapshot.get("owner_player_id", -1)),
			String(snapshot.get("faction_id", "")),
			String(snapshot.get("armor_class", "light_infantry")),
			int(snapshot.get("max_hp_fp", 0)),
			bool(snapshot.get("is_organic", true))
		)
		entity.current_hp_fp = int(snapshot.get("current_hp_fp", entity.max_hp_fp))
		entity.is_alive = bool(snapshot.get("is_alive", true))
		entity.is_arrested = bool(snapshot.get("is_arrested", false))
		entity.status_flags = (snapshot.get("status_flags", {}) as Dictionary).duplicate(true)
		_entities_by_id[entity_id] = entity

func _damage_modifier_fp(damage_type: String, armor_class: String) -> int:
	var normalized_armor := _normalize_armor_class(armor_class)
	var row: Dictionary = DAMAGE_MATRIX.get(damage_type, DAMAGE_MATRIX["kinetic"])
	return int(row.get(normalized_armor, MoonGoonsFixedMath.SCALE))

func _normalize_armor_class(armor_class: String) -> String:
	match armor_class:
		"heavy_infantry", "hero_officer":
			return "heavy_infantry"
		"mechanical_vehicle", "heavy_mechanical", "light_vehicle":
			return "heavy_mechanical"
		_:
			return "light_infantry"

func _should_arrest(
	attacker_faction_id: String,
	target: CombatEntity,
	random_source: MoonGoonsGameRand,
	force_detain: bool
) -> bool:
	if attacker_faction_id != "lunar_peacekeepers" or not target.is_organic:
		return false
	if force_detain:
		return true
	return random_source != null and random_source.next_range(0, 100) < PEACEKEEPER_ARREST_CHANCE_PERCENT

func _arrest_target(attacker_id: String, attacker_player_id: int, target: CombatEntity) -> void:
	target.current_hp_fp = maxi(1, target.current_hp_fp)
	target.is_arrested = true
	target.status_flags["arrested"] = {"remaining_ticks": -1, "payload": {"non_hostile": true}}
	_resource_bank.award_evidence_tokens(attacker_player_id, ARREST_EVIDENCE_REWARD)
	unit_arrested.emit(attacker_id, target.entity_id, ARREST_EVIDENCE_REWARD)

extends "res://scripts/alliance_research_state.gd"
## Stable public API for UI, tests, and Godot 4.3 compatibility.

func branch_catalog() -> Array[String]:
	return BRANCHES.duplicate()

func active_job(branch: String) -> Dictionary:
	if not active_jobs.has(branch):
		return {}
	var job: Dictionary = active_jobs[branch] as Dictionary
	return job.duplicate(true)

func construction_time_multiplier() -> float:
	var reduction: float = float(level("modular_foundry") - 1) * 0.0025
	reduction += float(level("rapid_assembly") - 1) * 0.0015
	reduction += float(level("autonomous_builders") - 1) * 0.0011
	return clampf(1.0 - reduction, 0.50, 1.0)

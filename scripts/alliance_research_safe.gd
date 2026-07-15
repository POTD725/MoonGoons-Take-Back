extends "res://scripts/alliance_research_state.gd"
## Stable public API for UI, tests, and Godot 4.3 compatibility.

func branch_catalog() -> Array[String]:
	return BRANCHES.duplicate()

func active_job(branch: String) -> Dictionary:
	if not active_jobs.has(branch):
		return {}
	var job: Dictionary = active_jobs[branch] as Dictionary
	return job.duplicate(true)

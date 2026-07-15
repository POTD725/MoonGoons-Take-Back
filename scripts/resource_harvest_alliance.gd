extends "res://scripts/resource_harvest_state.gd"
## Alliance Orbital Logistics improves all asteroid, moon, and wreck yields.

func projected_yield(site: Dictionary) -> int:
	var base_yield: int = super.projected_yield(site)
	var boosted: int = int(round(float(base_yield) * AllianceResearch.harvest_yield_multiplier()))
	return mini(int(site.get("reserve", boosted)), maxi(1, boosted))

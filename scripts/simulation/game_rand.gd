class_name MoonGoonsGameRand
extends RefCounted
## Small deterministic Park-Miller random generator for authoritative match state.
## Do not use this for cosmetic-only particles or audio variation.

const MODULUS: int = 2147483647
const MULTIPLIER: int = 48271

var state: int

func _init(seed: int = 1) -> void:
	state = seed % MODULUS
	if state <= 0:
		state += MODULUS - 1

func next_int() -> int:
	state = (state * MULTIPLIER) % MODULUS
	return state

func next_range(minimum_inclusive: int, maximum_exclusive: int) -> int:
	if maximum_exclusive <= minimum_inclusive:
		return minimum_inclusive
	return minimum_inclusive + next_int() % (maximum_exclusive - minimum_inclusive)

func next_unit_fraction_fp() -> int:
	return MoonGoonsFixedMath.divide_round(next_int() * MoonGoonsFixedMath.SCALE, MODULUS - 1)

func serialize_state() -> int:
	return state

func restore_state(serialized_state: int) -> void:
	state = serialized_state % MODULUS
	if state <= 0:
		state += MODULUS - 1

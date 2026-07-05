class_name MoonGoonsFixedMath
extends RefCounted
## Integer fixed-point helpers for future authoritative lockstep simulation.
## One world unit is stored as 1,000 integer subunits.

const SCALE: int = 1000
const TICKS_PER_SECOND: int = 30

static func from_float(value: float) -> int:
	return roundi(value * SCALE)

static func to_float(value_fp: int) -> float:
	return float(value_fp) / float(SCALE)

static func multiply(a_fp: int, b_fp: int) -> int:
	return divide_round(a_fp * b_fp, SCALE)

static func divide(a_fp: int, b_fp: int) -> int:
	if b_fp == 0:
		push_error("MoonGoonsFixedMath.divide received a zero denominator.")
		return 0
	return divide_round(a_fp * SCALE, b_fp)

static func divide_round(numerator: int, denominator: int) -> int:
	if denominator == 0:
		push_error("MoonGoonsFixedMath.divide_round received a zero denominator.")
		return 0
	var absolute_numerator := absi(numerator)
	var absolute_denominator := absi(denominator)
	var rounded := (absolute_numerator + absolute_denominator / 2) / absolute_denominator
	return -rounded if (numerator < 0) != (denominator < 0) else rounded

static func movement_step(speed_fp: int) -> int:
	return divide_round(speed_fp, TICKS_PER_SECOND)

static func integer_sqrt(value: int) -> int:
	if value <= 0:
		return 0
	var x := value
	var y := (x + 1) / 2
	while y < x:
		x = y
		y = (x + value / x) / 2
	return x

class_name MoonGoonsFixedVector2
extends RefCounted
## Ground-plane vector stored entirely in fixed-point integer subunits.
## The second axis is named Z to mirror future RTS world-space conventions.

var x: int
var z: int

func _init(initial_x: int = 0, initial_z: int = 0) -> void:
	x = initial_x
	z = initial_z

func copy() -> MoonGoonsFixedVector2:
	return MoonGoonsFixedVector2.new(x, z)

func magnitude() -> int:
	return MoonGoonsFixedMath.integer_sqrt(x * x + z * z)

func normalized() -> MoonGoonsFixedVector2:
	var length_fp := magnitude()
	if length_fp == 0:
		return MoonGoonsFixedVector2.new()
	return MoonGoonsFixedVector2.new(
		MoonGoonsFixedMath.divide(x, length_fp),
		MoonGoonsFixedMath.divide(z, length_fp)
	)

func equals(other: MoonGoonsFixedVector2) -> bool:
	return x == other.x and z == other.z

func to_display_vector2() -> Vector2:
	return Vector2(MoonGoonsFixedMath.to_float(x), MoonGoonsFixedMath.to_float(z))

static func subtract(a: MoonGoonsFixedVector2, b: MoonGoonsFixedVector2) -> MoonGoonsFixedVector2:
	return MoonGoonsFixedVector2.new(a.x - b.x, a.z - b.z)

class_name LaserTrip
extends Node3D
## A red laser tripwire between two points. Crossing it (player on layer 2) trips the alarm.

signal tripped

var armed := true
var _beam: MeshInstance3D
var _mat: StandardMaterial3D

func setup(from: Vector3, to: Vector3) -> void:
	var mid := (from + to) * 0.5
	var dist := maxf(0.4, from.distance_to(to))

	_beam = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.04, 0.04, dist)
	_beam.mesh = box
	_mat = WorldKit.mat(Color(1.0, 0.15, 0.12), 0.2, 0.0, 5.0)
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam.material_override = _mat
	add_child(_beam)
	_beam.global_position = mid
	if from.distance_to(to) > 0.01:
		_beam.look_at(to, Vector3.UP)

	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = WorldKit.L_PLAYER
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.25, 0.5, dist)
	col.shape = shape
	area.add_child(col)
	add_child(area)
	area.global_position = mid
	if from.distance_to(to) > 0.01:
		area.look_at(to, Vector3.UP)
	area.body_entered.connect(_on_body_entered)

	var pulse := _beam.create_tween().set_loops()
	pulse.tween_property(_mat, "emission_energy_multiplier", 2.5, 0.6).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_mat, "emission_energy_multiplier", 5.0, 0.6).set_trans(Tween.TRANS_SINE)

func set_armed(v: bool) -> void:
	armed = v
	if _beam != null:
		_beam.visible = v

func _on_body_entered(_body: Node3D) -> void:
	if armed:
		tripped.emit()

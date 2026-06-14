class_name Guard
extends Node3D
## A rank-and-file sentry: a reskinned library humanoid that patrols waypoints (or scans
## in place), projects a vision cone, and can be silently taken down from behind. Detection
## itself is aggregated by the level (it owns the meter); the guard just answers can_see().

var sight_range := 9.0
var fov_half := 33.0
var move_speed := 1.7
var scan_arc := 55.0
var scan_speed := 0.7
var model_yaw_offset := 0.0
var neutralized := false

var _waypoints: Array = []
var _model: Node3D
var _cone: VisionCone
var _loco := Locomotion.new()
var _wp := 0
var _scan_t := 0.0
var _base_yaw := 0.0
var _state := ""

func setup(model_path: String, opts: Dictionary = {}) -> void:
	sight_range = float(opts.get("range", sight_range))
	fov_half = float(opts.get("fov", fov_half))
	move_speed = float(opts.get("speed", move_speed))
	model_yaw_offset = float(opts.get("yaw_offset", 0.0))
	scan_arc = float(opts.get("scan_arc", scan_arc))
	_base_yaw = float(opts.get("face_yaw", 0.0))
	var tint: Variant = opts.get("tint", null)
	var wp: Variant = opts.get("waypoints", [])
	if wp is Array:
		for v in wp:
			if v is Vector3:
				_waypoints.append(v)

	if bool(opts.get("camera", false)):
		_model = _camera_model()
		add_child(_model)
	else:
		_model = WorldKit.instance_glb(model_path)
		if _model == null:
			_model = _fallback_model()
		_model.scale = Vector3.ONE * float(opts.get("scale", 1.0))
		add_child(_model)
		if tint is Color:
			WorldKit.recolor(_model, tint)
		if model_yaw_offset != 0.0:
			_model.rotation.y = model_yaw_offset
	_loco.setup(_model)

	_cone = VisionCone.new()
	add_child(_cone)
	_cone.build(sight_range, fov_half)

	rotation.y = _base_yaw
	_set_state("idle")

func _process(delta: float) -> void:
	if neutralized:
		return
	if _waypoints.size() >= 2:
		_patrol(delta)
	else:
		_scan(delta)

func _patrol(delta: float) -> void:
	var target: Vector3 = _waypoints[_wp]
	var to := target - global_position
	to.y = 0.0
	var d := to.length()
	if d < 0.3:
		_wp = (_wp + 1) % _waypoints.size()
		return
	var dir := to.normalized()
	global_position += dir * minf(move_speed * delta, d)
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 0.18)
	_set_state("walk")

func _scan(delta: float) -> void:
	_scan_t += delta * scan_speed
	rotation.y = _base_yaw + deg_to_rad(scan_arc) * sin(_scan_t)
	_set_state("idle")

func _set_state(s: String) -> void:
	if s == _state:
		return
	_state = s
	_loco.play(s)

func can_see_player(point: Vector3) -> bool:
	return not neutralized and _cone != null and _cone.can_see(point)

func set_alert(t: float) -> void:
	if _cone != null:
		_cone.set_alert(t)

func forward() -> Vector3:
	var f := global_transform.basis.z
	f.y = 0.0
	if f.length() < 0.001:
		return Vector3.FORWARD
	return f.normalized()

func neutralize() -> void:
	if neutralized:
		return
	neutralized = true
	if _cone != null:
		_cone.set_visible_cone(false)
	_set_state("idle")
	if _model != null:
		var t := _model.create_tween()
		t.tween_property(_model, "rotation:x", deg_to_rad(-82.0), 0.45)
		t.parallel().tween_property(_model, "position:y", -0.25, 0.45)

func _fallback_model() -> Node3D:
	var n := Node3D.new()
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.3
	cap.height = 1.7
	body.mesh = cap
	body.position.y = 0.95
	body.material_override = WorldKit.mat(Color(0.18, 0.2, 0.26))
	n.add_child(body)
	var head := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.18
	sph.height = 0.36
	head.mesh = sph
	head.position.y = 1.75
	head.material_override = WorldKit.mat(Color(0.7, 0.6, 0.52))
	n.add_child(head)
	return n

func _camera_model() -> Node3D:
	var n := Node3D.new()
	var housing := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.34, 0.26, 0.5)
	housing.mesh = bm
	housing.material_override = WorldKit.mat(Color(0.12, 0.12, 0.14), 0.5, 0.4)
	n.add_child(housing)
	var lens := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.09
	cyl.bottom_radius = 0.11
	cyl.height = 0.18
	lens.mesh = cyl
	lens.rotation_degrees.x = 90.0
	lens.position.z = 0.3
	lens.material_override = WorldKit.mat(Color(0.05, 0.05, 0.06), 0.2, 0.6)
	n.add_child(lens)
	var dot := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.035
	sph.height = 0.07
	dot.mesh = sph
	dot.position = Vector3(0.12, 0.12, 0.18)
	dot.material_override = WorldKit.mat(Color(1.0, 0.2, 0.15), 0.2, 0.0, 4.0)
	n.add_child(dot)
	return n

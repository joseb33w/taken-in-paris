extends LevelBase
## Level 3 - Louvre After Hours. Slip past sweeping camera cones and laser tripwires, lift
## the cipher fragments, and crack the cipher (link the two) to find the way down.

var _lasers: Array = []

func _level_index() -> int:
	return 3

func _is_outdoor() -> bool:
	return false

func _build_level() -> void:
	place_player(Vector3(0, 0, 16), 0.0)

	# marble gallery floor + ceiling
	var floor := ground(Vector2(24, 46), Color(0.62, 0.6, 0.62), Vector3(0, 0, -3), "")
	var fm := floor.get_child(0)
	if fm is MeshInstance3D:
		(fm as MeshInstance3D).material_override = WorldKit.mat(Color(0.6, 0.58, 0.6), 0.25, 0.1)
	_ceiling(Vector3(0, 5, -3), Vector2(24, 46))

	var gallery := Color(0.46, 0.4, 0.36)
	wall(Vector3(-11, 0, 18), Vector3(-11, 0, -20), 5.0, gallery)
	wall(Vector3(11, 0, 18), Vector3(11, 0, -20), 5.0, gallery)
	wall(Vector3(-11, 0, 18), Vector3(11, 0, 18), 5.0, gallery)
	wall(Vector3(-11, 0, -20), Vector3(11, 0, -20), 5.0, gallery)
	# mid partition with a doorway gap
	wall(Vector3(-11, 0, 0), Vector3(-2.5, 0, 0), 5.0, gallery)
	wall(Vector3(2.5, 0, 0), Vector3(11, 0, 0), 5.0, gallery)

	# art + plinths
	_artframe(Vector3(-10.7, 2.4, 8), 90, Color(0.7, 0.4, 0.2))
	_artframe(Vector3(10.7, 2.4, -8), -90, Color(0.25, 0.45, 0.7))
	_artframe(Vector3(-10.7, 2.4, -14), 90, Color(0.5, 0.3, 0.6))
	_plinth(Vector3(-7, 0, 6))
	_plinth(Vector3(7, 0, -5))
	_plinth(Vector3(0, 0, -15))
	prop("res://models/v_ms_control_box.glb", Vector3(9.5, 0, 3), -90, 1.0, true)
	prop("res://models/v_ms_cabinet_basic.glb", Vector3(-9.5, 0, -10), 90, 1.0, true)

	# gallery spotlights
	add_light(Vector3(-7, 4.2, 6), Color(1.0, 0.9, 0.7), 3.0, 7)
	add_light(Vector3(7, 4.2, -5), Color(0.8, 0.85, 1.0), 3.0, 7)
	add_light(Vector3(0, 4.2, -15), Color(1.0, 0.9, 0.7), 3.0, 7)

	# sweeping ceiling cameras
	spawn_camera(Vector3(8, 3.4, 11), -PI / 2.0, {"range": 10.0, "fov": 24.0, "scan_arc": 42.0})
	spawn_camera(Vector3(-8, 3.4, -6), PI / 2.0, {"range": 10.0, "fov": 24.0, "scan_arc": 42.0})
	spawn_camera(Vector3(0, 3.6, -18), 0.0, {"range": 11.0, "fov": 22.0, "scan_arc": 36.0})

	# laser tripwires (doorway + a corridor)
	_laser(Vector3(-2.5, 0, 0), Vector3(-0.2, 0, 0))
	_laser(Vector3(0.2, 0, 0), Vector3(2.5, 0, 0))
	_laser(Vector3(-11, 0, -10), Vector3(-4, 0, -10))
	_laser(Vector3(4, 0, 9), Vector3(11, 0, 9))

	# the cipher + keycard
	spawn_clue("l3_cipher_a", Vector3(-7, 1.0, 6))
	spawn_clue("l3_keycard", Vector3(7, 1.0, -5))
	spawn_clue("l3_cipher_b", Vector3(0, 1.0, -15))

	make_exit(Vector3(0, 0, -18.5), true)

func _laser(a: Vector3, b: Vector3) -> void:
	var l := LaserTrip.new()
	add_child(l)
	l.setup(a + Vector3(0, 0.8, 0), b + Vector3(0, 0.8, 0))
	l.tripped.connect(_on_laser.bind(l))
	_lasers.append(l)

func _on_laser(l: LaserTrip) -> void:
	if _finished:
		return
	detection = minf(1.0, detection + 0.55)
	if hud != null:
		hud.set_detection(detection)
		hud.flash_msg("Tripwire!")
	_flash_alarm()
	l.set_armed(false)
	var tm := get_tree().create_timer(0.9)
	tm.timeout.connect(func() -> void:
		if is_instance_valid(l):
			l.set_armed(true))

func _ceiling(pos: Vector3, size: Vector2) -> void:
	var mi := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = size
	pl.orientation = PlaneMesh.FACE_Y
	mi.mesh = pl
	mi.rotation_degrees.x = 180.0
	mi.material_override = WorldKit.mat(Color(0.1, 0.1, 0.13), 0.9)
	add_child(mi)
	mi.position = pos

func _plinth(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.9, 1.0, 0.9)
	mi.mesh = bm
	mi.material_override = WorldKit.mat(Color(0.5, 0.48, 0.5), 0.4)
	var body := StaticBody3D.new()
	body.collision_layer = WorldKit.L_WORLD
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(0.9, 1.0, 0.9)
	col.shape = cs
	body.add_child(col)
	body.add_child(mi)
	add_child(body)
	body.position = pos + Vector3(0, 0.5, 0)

func _artframe(pos: Vector3, yaw: float, color: Color) -> void:
	var frame := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.2, 1.6, 0.12)
	frame.mesh = bm
	frame.material_override = WorldKit.mat(Color(0.3, 0.24, 0.12), 0.6, 0.2)
	add_child(frame)
	frame.position = pos
	frame.rotation_degrees.y = yaw
	var art := MeshInstance3D.new()
	var ab := BoxMesh.new()
	ab.size = Vector3(1.9, 1.3, 0.04)
	art.mesh = ab
	art.material_override = WorldKit.mat(color, 0.5, 0.0, 0.8)
	add_child(art)
	art.position = pos + Vector3(sin(deg_to_rad(yaw)) * 0.08, 0, cos(deg_to_rad(yaw)) * 0.08)
	art.rotation_degrees.y = yaw

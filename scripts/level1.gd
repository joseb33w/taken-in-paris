extends LevelBase
## Level 1 - Montmartre Rooftops. Tail the kidnapper across the zinc roofs without crossing
## his light cone or the sentries'. Collect the evidence, deduce the lead to the Marais.

const KIDNAPPER := "res://models/henchman.glb"

func _level_index() -> int:
	return 1

func _is_outdoor() -> bool:
	return true

func _build_level() -> void:
	place_player(Vector3(0, 0, 16), 0.0)

	# rooftop surface
	ground(Vector2(40, 54), Color(0.21, 0.23, 0.27), Vector3(0, 0, -3), "")
	# parapet ring (1.2m walls keep you on the roof)
	var stone := Color(0.32, 0.33, 0.36)
	wall(Vector3(-15, 0, 20), Vector3(-15, 0, -24), 1.2, stone)
	wall(Vector3(15, 0, 20), Vector3(15, 0, -24), 1.2, stone)
	wall(Vector3(-15, 0, 20), Vector3(15, 0, 20), 1.2, stone)
	wall(Vector3(-15, 0, -24), Vector3(15, 0, -24), 1.2, stone)

	# the Paris below + skyline: a ring of lit Haussmann blocks (their roofs loom over parapets)
	var ring := [
		Vector3(-24, -6, 6), Vector3(24, -6, 2), Vector3(-26, -7, -10), Vector3(25, -6, -14),
		Vector3(-22, -5, -22), Vector3(22, -7, -22), Vector3(0, -8, -30), Vector3(-12, -7, 26), Vector3(12, -6, 26),
	]
	var i := 0
	for p: Vector3 in ring:
		var s := Vector3(10 + (i % 3) * 2, 20 + (i % 4) * 4, 10)
		haussmann_block(p, s, float((i * 37) % 90), float(i + 1), Color(0.5, 0.5, 0.55) if i % 2 == 0 else Color(0.6, 0.56, 0.5))
		i += 1
	# signature skyline anchor
	place_tower(Vector3(6, -10, -210), 1.3, 20.0)

	# rooftop clutter (cover + atmosphere)
	prop("res://models/v_ms_cable_reel.glb", Vector3(-9, 0, 12), 20, 1.0, true)
	prop("res://models/v_ms_brick_pile.glb", Vector3(9, 0, -2), 0, 1.0, true)
	_chimney(Vector3(-11, 0, -16))
	_chimney(Vector3(12, 0, 6))
	_acunit(Vector3(7, 0, 14))
	_acunit(Vector3(-6, 0, -20))
	add_light(Vector3(0, 6, 0), Color(0.5, 0.6, 0.9), 1.2, 26)

	# the kidnapper you tail - a forward cone; do not get in front of him
	spawn_guard(KIDNAPPER, Vector3(0, 0, 6), {
		"range": 8.5, "fov": 34.0, "speed": 1.7, "scale": 1.0,
		"waypoints": [Vector3(-8, 0, 8), Vector3(8, 0, 4), Vector3(8, 0, -8), Vector3(-8, 0, -12), Vector3(-8, 0, 8)],
	})
	# sentries scanning the roofs
	spawn_guard(GUARD_A, Vector3(11, 0, 0), {"range": 9.0, "fov": 32.0, "face_yaw": -PI / 2.0, "scan_arc": 60.0, "tint": Color(0.16, 0.17, 0.22)})
	spawn_guard(GUARD_B, Vector3(-11, 0, -16), {"range": 9.0, "fov": 30.0, "face_yaw": PI / 2.0, "scan_arc": 55.0, "tint": Color(0.18, 0.16, 0.2)})

	# evidence along the route
	spawn_clue("l1_van", Vector3(6, 0, 11))
	spawn_clue("l1_route", Vector3(-6, 0, -2))
	spawn_clue("l1_receipt", Vector3(3, 0, -14))

	make_exit(Vector3(0, 0, -21), true)

func _chimney(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 2.4, 1.2)
	mi.mesh = bm
	mi.material_override = WorldKit.mat(Color(0.45, 0.3, 0.26), 0.9)
	var body := StaticBody3D.new()
	body.collision_layer = WorldKit.L_WORLD
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(1.2, 2.4, 1.2)
	col.shape = cs
	body.add_child(col)
	body.add_child(mi)
	add_child(body)
	body.position = pos + Vector3(0, 1.2, 0)

func _acunit(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.6, 1.0, 1.2)
	mi.mesh = bm
	mi.material_override = WorldKit.mat(Color(0.3, 0.32, 0.35), 0.6, 0.3)
	var body := StaticBody3D.new()
	body.collision_layer = WorldKit.L_WORLD
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(1.6, 1.0, 1.2)
	col.shape = cs
	body.add_child(col)
	body.add_child(mi)
	add_child(body)
	body.position = pos + Vector3(0, 0.5, 0)

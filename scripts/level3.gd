extends LevelBase
## District 3 - THE LOUVRE, after hours. Cold marble galleries, sweeping camera cones and
## laser tripwires. Lift the cipher fragments, pick the display case for the keycard, slip
## past the night guard, and crack the cipher (link the two) to find the way down.

const GUARD_SEC := "You are Faucon, a bored Louvre night-security guard doing the graveyard shift, Paris. You are officious and a little lonely. You have NOT noticed Etienne yet and assume he is a new cleaner if he stays calm. You let slip that 'archive crates' were brought in to the Egyptian sub-level after closing on someone's authority you didn't question. Short, dry, atmospheric lines. Never narrate actions. Never break character."

var _lasers: Array = []

func _level_index() -> int:
	return 3

func _is_outdoor() -> bool:
	return false

func _env_profile() -> Dictionary:
	return {
		"outdoor": false,
		"bg_color": Color(0.04, 0.05, 0.07),
		"ambient_color": Color(0.30, 0.34, 0.44),
		"ambient_energy": 0.8,
		"fog_color": Color(0.08, 0.09, 0.12),
		"fog_density": 0.02,
		"exposure": 1.05,
		"ambience": "amb_gallery",
		"base_tension": 0.12,
	}

func _build_level() -> void:
	place_player(Vector3(0, 0, 16), 0.0)
	set_objective("THE LOUVRE\nCameras and lasers. Find the cipher. Don't trip the alarm.")

	var floor := ground(Vector2(24, 46), Color(0.62, 0.6, 0.62), Vector3(0, 0, -3))
	var fm := floor.get_child(0)
	if fm is MeshInstance3D:
		(fm as MeshInstance3D).material_override = WorldKit.mat(Color(0.62, 0.6, 0.62), 0.22, 0.15)
	_ceiling(Vector3(0, 5, -3), Vector2(24, 46))

	var gallery := Color(0.5, 0.46, 0.42)
	wall(Vector3(-11, 0, 18), Vector3(-11, 0, -20), 5.0, gallery)
	wall(Vector3(11, 0, 18), Vector3(11, 0, -20), 5.0, gallery)
	wall(Vector3(-11, 0, 18), Vector3(11, 0, 18), 5.0, gallery)
	wall(Vector3(-11, 0, -20), Vector3(11, 0, -20), 5.0, gallery)
	wall(Vector3(-11, 0, 0), Vector3(-2.5, 0, 0), 5.0, gallery)
	wall(Vector3(2.5, 0, 0), Vector3(11, 0, 0), 5.0, gallery)

	# art, plinths (statues), benches, velvet ropes
	_artframe(Vector3(-10.7, 2.4, 8), 90, Color(0.7, 0.4, 0.2))
	_artframe(Vector3(10.7, 2.4, -8), -90, Color(0.25, 0.45, 0.7))
	_artframe(Vector3(-10.7, 2.4, -14), 90, Color(0.5, 0.3, 0.6))
	_artframe(Vector3(10.7, 2.4, 10), -90, Color(0.6, 0.5, 0.2))
	_plinth(Vector3(-7, 0, 6))
	_plinth(Vector3(7, 0, -5))
	_plinth(Vector3(0, 0, -15))
	_plinth(Vector3(-6, 0, -12))
	Dressing.bench(self, Vector3(0, 0, 8), 0.0, Color(0.3, 0.2, 0.16))
	Dressing.bench(self, Vector3(3, 0, -10), 0.0, Color(0.3, 0.2, 0.16))
	_rope(Vector3(-4, 0, 4), Vector3(4, 0, 4))
	prop("res://models/v_ms_control_box.glb", Vector3(9.5, 0, 3), -90, 1.0, true)
	prop("res://models/v_ms_cabinet_basic.glb", Vector3(-9.5, 0, -10), 90, 1.0, true)

	add_light(Vector3(-7, 4.2, 6), Color(1.0, 0.92, 0.78), 2.6, 7)
	add_light(Vector3(7, 4.2, -5), Color(0.82, 0.88, 1.0), 2.6, 7)
	add_light(Vector3(0, 4.2, -15), Color(1.0, 0.92, 0.78), 2.6, 7)
	add_light(Vector3(0, 4.2, 12), Color(0.9, 0.92, 1.0), 2.2, 8)

	# sweeping cameras + laser tripwires
	spawn_camera(Vector3(8, 3.4, 11), -PI / 2.0, {"range": 10.0, "fov": 24.0, "scan_arc": 42.0})
	spawn_camera(Vector3(-8, 3.4, -6), PI / 2.0, {"range": 10.0, "fov": 24.0, "scan_arc": 42.0})
	spawn_camera(Vector3(0, 3.6, -18), 0.0, {"range": 11.0, "fov": 22.0, "scan_arc": 36.0})
	_laser(Vector3(-2.5, 0, 0), Vector3(-0.2, 0, 0))
	_laser(Vector3(0.2, 0, 0), Vector3(2.5, 0, 0))
	_laser(Vector3(-11, 0, -10), Vector3(-4, 0, -10))
	_laser(Vector3(4, 0, 9), Vector3(11, 0, 9))

	# the night guard you can bluff / pump for info
	spawn_talker("res://models/cop.glb", Vector3(8.5, 0, 14), {
		"name": "Faucon, night security", "persona": GUARD_SEC, "voice": "cop",
		"face_yaw": -PI / 2.0, "greeting": "Evening. ...you the new cleaner? Badge?",
		"barks": ["All quiet on my watch.", "Those archive crates went to the sub-level. Odd hour for it."],
	})

	# cipher + keycard (keycard now lives in a display case you pick)
	spawn_clue("l3_cipher_a", Vector3(-7, 1.0, 6))
	spawn_clue("l3_cipher_b", Vector3(0, 1.0, -15))
	spawn_lock("l3_case", Vector3(7, 0, -5), {"label": "Pick the display case", "clue_id": "l3_keycard", "pins": 4})
	spawn_photo("l3_map", Vector3(-10.4, 1.2, -14), {"label": "Photograph the circled gallery map", "lead": "egyptian_sublevel"})
	spawn_note("l3_memo", "Staff memo", "A memo pinned by the door: 'Catacombs maintenance access via Denfert-Rochereau - keycard required.'", Vector3(9.0, 0, -2))

	make_exit(Vector3(0, 0, -18.5), true, "DESCEND")

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
	Audio.sfx("sfx_spotted", -4.0)
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
	mi.material_override = WorldKit.mat(Color(0.12, 0.12, 0.15), 0.9)
	add_child(mi)
	mi.position = pos

func _plinth(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.9, 1.0, 0.9)
	mi.mesh = bm
	mi.material_override = WorldKit.mat(Color(0.52, 0.5, 0.52), 0.4)
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
	# a small bust on top
	var bust := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.22; sm.height = 0.5
	bust.mesh = sm
	bust.material_override = WorldKit.mat(Color(0.7, 0.68, 0.62), 0.5)
	bust.position = pos + Vector3(0, 1.25, 0)
	add_child(bust)

func _rope(a: Vector3, b: Vector3) -> void:
	for p in [a, b]:
		var post := MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 0.04; cm.bottom_radius = 0.05; cm.height = 0.9
		post.mesh = cm
		post.material_override = WorldKit.mat(Color(0.6, 0.5, 0.2), 0.3, 0.6)
		post.position = p + Vector3(0, 0.45, 0)
		add_child(post)
	var rope := MeshInstance3D.new()
	var rb := BoxMesh.new(); rb.size = Vector3(a.distance_to(b), 0.04, 0.04)
	rope.mesh = rb
	rope.material_override = WorldKit.mat(Color(0.6, 0.1, 0.12), 0.7)
	add_child(rope)
	rope.global_position = (a + b) * 0.5 + Vector3(0, 0.8, 0)
	rope.look_at(b + Vector3(0, 0.8, 0), Vector3.UP)
	rope.rotate_object_local(Vector3.UP, PI / 2.0)

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

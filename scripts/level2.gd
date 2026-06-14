extends LevelBase
## Level 2 - Marais Bistro. Lift the evidence off the terrasse without the waiter seeing,
## duck into the bistro, then interrogate the waiter. Deduce the lead to the Louvre.

const WAITER_PERSONA := "You are Tariq, the night waiter at Le Corbeau, a cramped bistro on rue des Rosiers in the Marais, Paris. It is well past midnight. You are jumpy and evasive - you were paid to keep quiet about the men in dark suits who used the private cellar tonight. Under pressure you will admit, reluctantly and in character, that they left with heavy crates stencilled 'DCRI archives' and drove toward the Louvre, the Porte des Lions staff entrance, after closing. Speak in short, nervous, atmospheric lines with a faint French inflection. Never narrate actions. Never break character. Make Etienne work for the truth; do not dump everything at once."

const INFORMANT_PERSONA := "You are Mireille, an old flower-seller who works the Marais corner every night, Paris. You miss nothing on this street. You are wry and a little sad. You saw a black van and three men in dark suits loading crates outside Le Corbeau earlier; you will share what you saw if Etienne is kind, and you will gently push him to check the terrasse tables and to lean on the waiter. Speak in short, warm, atmospheric lines. Never narrate actions. Never break character."

func _level_index() -> int:
	return 2

func _is_outdoor() -> bool:
	return true

func _build_level() -> void:
	place_player(Vector3(0, 0, 20), 0.0)

	ground(Vector2(18, 56), Color(0.16, 0.16, 0.19), Vector3(0, 0, -4), "")
	# sidewalks
	_strip(Vector3(-6.5, 0.04, -4), Vector2(4, 56), Color(0.26, 0.26, 0.29))
	_strip(Vector3(6.5, 0.04, -4), Vector2(4, 56), Color(0.26, 0.26, 0.29))

	# the custom Haussmann cafe, front (cafe + awning) facing the street (+X)
	var cafe := WorldKit.instance_glb("res://models/haussmann_cafe.glb")
	if cafe != null:
		cafe.rotation_degrees.y = 90.0
		add_child(cafe)
		cafe.position = Vector3(-13.5, 0, -2)
		WorldKit.add_static_box(cafe, WorldKit.L_WORLD, Vector3(0.9, 1.0, 0.9))

	# street facades opposite + further down
	haussmann_block(Vector3(12, 0, 8), Vector3(10, 22, 10), -90, 3.0, Color(0.62, 0.58, 0.52))
	haussmann_block(Vector3(12, 0, -16), Vector3(10, 26, 10), -90, 5.0, Color(0.55, 0.55, 0.58))
	haussmann_block(Vector3(-13, 0, -22), Vector3(12, 24, 10), 90, 7.0, Color(0.6, 0.56, 0.5))
	place_tower(Vector3(20, -6, -150), 1.0, -30.0)

	# warm street lighting + signage
	_streetlamp(Vector3(-5.5, 0, 6))
	_streetlamp(Vector3(5.5, 0, -10))
	add_light(Vector3(-5, 4, -2), Color(1.0, 0.8, 0.45), 3.0, 9)
	prop("res://models/v_ms_board_message.glb", Vector3(-5.5, 0, 3), -90, 1.0, false)

	# a small bistro interior to duck into (open doorway facing the street / +Z)
	_bistro_interior(Vector3(-4.5, 0, 12))

	# terrasse tables on the sidewalk
	_table(Vector3(-4.5, 0, -1))
	_table(Vector3(-3.5, 0, 4))
	prop("res://models/v_ms_chair_sun.glb", Vector3(-6, 0, -1), 30, 1.0, false)
	prop("res://models/v_ms_chair_sun.glb", Vector3(-5, 0, 5), -20, 1.0, false)

	# the waiter: a suspect AND a sensor (do not let him see you lift the evidence)
	spawn_talker(NPC_MODEL, Vector3(-6.5, 0, -2), {
		"name": "Tariq, the waiter", "persona": WAITER_PERSONA, "clue_id": "l2_waiter",
		"face_yaw": PI / 2.0, "tint": Color(0.18, 0.18, 0.2),
		"cone": true, "range": 7.0, "fov": 36.0, "scan_arc": 52.0, "scan_speed": 0.6,
	})
	# a friendly informant on the corner
	spawn_talker(NPC_MODEL, Vector3(5, 0, 10), {
		"name": "Mireille, the flower-seller", "persona": INFORMANT_PERSONA, "clue_id": "",
		"face_yaw": -PI / 2.0, "tint": Color(0.45, 0.3, 0.35),
	})
	# a lookout patrolling the street
	spawn_guard(GUARD_A, Vector3(4, 0, -6), {
		"range": 8.0, "fov": 30.0, "speed": 1.6, "tint": Color(0.16, 0.16, 0.2),
		"waypoints": [Vector3(4, 0, -2), Vector3(4, 0, -18), Vector3(-2, 0, -18), Vector3(-2, 0, -2), Vector3(4, 0, -2)],
	})

	# evidence: matches on the terrasse (needs sneaking past Tariq); ledger inside the bistro
	spawn_clue("l2_matches", Vector3(-4.5, 0, -1))
	spawn_clue("l2_ledger", Vector3(-4.5, 0, 12))

	make_exit(Vector3(0, 0, -24), true)

func _strip(pos: Vector3, size: Vector2, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = size
	mi.mesh = pl
	mi.material_override = WorldKit.mat(color, 0.9)
	add_child(mi)
	mi.position = pos

func _table(pos: Vector3) -> void:
	prop("res://models/crate.glb", pos, 0, 1.1, false)
	prop("res://models/chair.glb", pos + Vector3(0.9, 0, 0.3), -120, 1.0, false)
	prop("res://models/chair.glb", pos + Vector3(-0.9, 0, -0.3), 60, 1.0, false)

func _streetlamp(pos: Vector3) -> void:
	var post := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.12
	cyl.height = 4.0
	post.mesh = cyl
	post.material_override = WorldKit.mat(Color(0.1, 0.1, 0.12), 0.4, 0.6)
	post.position = pos + Vector3(0, 2, 0)
	add_child(post)
	var lamp := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.22
	sph.height = 0.44
	lamp.mesh = sph
	lamp.material_override = WorldKit.mat(Color(1.0, 0.85, 0.5), 0.2, 0.0, 4.0)
	lamp.position = pos + Vector3(0, 4, 0)
	add_child(lamp)
	add_light(pos + Vector3(0, 4, 0), Color(1.0, 0.82, 0.45), 2.4, 8)

func _bistro_interior(c: Vector3) -> void:
	var wallcol := Color(0.3, 0.22, 0.16)
	wall(c + Vector3(-3, 0, -3), c + Vector3(3, 0, -3), 3.0, wallcol)
	wall(c + Vector3(-3, 0, -3), c + Vector3(-3, 0, 3), 3.0, wallcol)
	wall(c + Vector3(3, 0, -3), c + Vector3(3, 0, 3), 3.0, wallcol)
	wall(c + Vector3(-3, 0, 3), c + Vector3(-1.2, 0, 3), 3.0, wallcol)
	wall(c + Vector3(1.2, 0, 3), c + Vector3(3, 0, 3), 3.0, wallcol)
	_strip(c + Vector3(0, 0.05, 0), Vector2(6, 6), Color(0.32, 0.24, 0.18))
	prop("res://models/v_ms_cabinet_basic.glb", c + Vector3(2, 0, -2), 180, 1.0, true)
	prop("res://models/crate.glb", c + Vector3(0, 0, -0.5), 0, 1.0, false)
	prop("res://models/food.glb", c + Vector3(0, 0.7, -0.5), 0, 1.0, false)
	prop("res://models/v_ms_candle.glb", c + Vector3(-2, 0, -2), 0, 1.0, false)
	add_light(c + Vector3(0, 2.4, 0), Color(1.0, 0.72, 0.4), 3.2, 7)

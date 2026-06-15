extends LevelBase
## District 2 - THE MARAIS, neon night. A roamable bistro street: Le Corbeau with its terrace
## and cellar, wet cobbles under neon, patrons, an informant and a flic. Lift the matchbook
## past the waiter's gaze, pick the cellar for the ledger, make the waiter talk, deduce -> Louvre.

const WAITER := "You are Tariq, the night waiter at Le Corbeau on rue des Rosiers in the Marais, Paris. It is past midnight. You are jumpy and evasive - you were paid to stay quiet about the men in dark suits who used the private cellar tonight. Under real pressure you admit, reluctantly, in character, that they left with heavy crates stencilled 'DCRI archives' and drove toward the Louvre, the Porte des Lions staff entrance, after closing. Short, nervous, atmospheric lines, faint French inflection. Make Etienne work for it. Never narrate actions. Never break character."
const FURET := "You are 'Le Furet', a twitchy small-time Marais informant in a hooded coat, Paris. You sell what you see. You know the men used Le Corbeau's cellar and that a girl was moved in a crate-van toward the river. You will trade the tip for respect, or for being left alone. Short, anxious, street-smart lines. Never narrate actions. Never break character."
const PATRON := "You are a late patron at a Marais bistro terrace, Paris, half a carafe in. You are gossipy and unbothered. You saw waiters carrying heavy crates up from the cellar and complaining. You will share it cheerfully if asked. Short, warm, tipsy lines. Never narrate actions. Never break character."
const COP2 := "You are Gardien Morel of the Police Nationale on Marais night patrol, Paris. Weary and skeptical. You think Etienne is a drunk with a story, but you confirm a black crate-van was double-parked outside Le Corbeau earlier. Short, clipped lines. Never narrate actions. Never break character."

func _level_index() -> int:
	return 2

func _env_profile() -> Dictionary:
	return {
		"outdoor": true,
		"sky_top": Color(0.03, 0.04, 0.10),
		"sky_horizon": Color(0.12, 0.10, 0.22),
		"ground": Color(0.04, 0.05, 0.08),
		"ambient_color": Color(0.20, 0.24, 0.38),
		"ambient_energy": 0.85,
		"sky_contrib": 0.4,
		"sun_color": Color(0.4, 0.5, 0.9),
		"sun_energy": 0.35,
		"sun_rot": Vector3(-62.0, 20.0, 0.0),
		"fog_color": Color(0.10, 0.12, 0.24),
		"fog_density": 0.02,
		"exposure": 1.0,
		"ambience": "amb_street",
		"base_tension": 0.05,
	}

func _build_level() -> void:
	place_player(Vector3(0, 0, 22), 0.0)
	set_objective("THE MARAIS\nLe Corbeau. Lift the evidence. Make the waiter talk.")

	# wet cobbles (slightly metallic so the neon reflects)
	var g := ground(Vector2(20, 58), Color(0.10, 0.11, 0.14), Vector3(0, 0, -4))
	var gm := g.get_child(0)
	if gm is MeshInstance3D:
		(gm as MeshInstance3D).material_override = WorldKit.mat(Color(0.10, 0.11, 0.14), 0.35, 0.25)
	_strip(Vector3(-7, 0.04, -4), Vector2(4, 58), Color(0.16, 0.17, 0.2))
	_strip(Vector3(7, 0.04, -4), Vector2(4, 58), Color(0.16, 0.17, 0.2))

	# the bespoke Haussmann cafe (Le Corbeau) facing the street, plus opposite facades
	var cafe := WorldKit.instance_glb("res://models/haussmann_cafe.glb")
	if cafe != null:
		cafe.rotation_degrees.y = 90.0
		add_child(cafe)
		cafe.position = Vector3(-13.5, 0, -2)
		WorldKit.add_static_box(cafe, WorldKit.L_WORLD, Vector3(0.9, 1.0, 0.9))
	haussmann_block(Vector3(13, 0, 8), Vector3(11, 22, 11), -90, 3.0, Color(0.42, 0.4, 0.5))
	haussmann_block(Vector3(13, 0, -16), Vector3(11, 26, 11), -90, 5.0, Color(0.38, 0.4, 0.52))
	haussmann_block(Vector3(-13, 0, -24), Vector3(12, 24, 11), 90, 7.0, Color(0.4, 0.38, 0.48))
	haussmann_block(Vector3(0, 0, -32), Vector3(16, 28, 10), 0.0, 9.0, Color(0.4, 0.4, 0.5))
	place_tower(Vector3(22, -6, -150), 1.0, -30.0)

	# neon signage glow + warm cafe pools + a cafe ambience near the bistro
	_neon(Vector3(-9.6, 3.6, 0), Color(1.0, 0.2, 0.5))
	_neon(Vector3(11.4, 4.2, -8), Color(0.2, 0.9, 1.0))
	_neon(Vector3(11.4, 3.4, 6), Color(0.9, 0.5, 1.0))
	Dressing.awning(self, Vector3(-9.0, 3.0, 1.5), 5.5, 0.0, Color(0.5, 0.1, 0.15))
	Dressing.string_lights(self, Vector3(-10, 3.3, 2.6), Vector3(-3, 3.3, 2.6), 8)
	add_light(Vector3(-7, 2.6, -2), Color(1.0, 0.7, 0.4), 3.2, 9)
	var cafe_amb := Node3D.new(); add_child(cafe_amb); cafe_amb.position = Vector3(-8, 1.5, 2)
	Audio.attach_loop_3d(cafe_amb, "amb_cafe", -6.0, 16.0)

	# the bistro interior to duck into
	_bistro_interior(Vector3(-4.5, 0, 12))

	# terrasse tables with seated patrons
	Dressing.cafe_set(self, Vector3(-4.5, 0, -1))
	Dressing.cafe_set(self, Vector3(-3.5, 0, 5))

	# street dressing
	for z in [14, 2, -12, -22]:
		Dressing.street_light(self, Vector3(-6.2, 0, z), 0.0, Color(0.7, 0.8, 1.0))
		Dressing.street_light(self, Vector3(6.2, 0, z - 5), 0.0, Color(0.7, 0.8, 1.0))
	Dressing.bench(self, Vector3(5.6, 0, 6), -90.0)
	Dressing.hydrant(self, Vector3(-5.8, 0, 16))
	Dressing.trash(self, Vector3(5.8, 0, -2), "A")
	Dressing.dumpster(self, Vector3(6.0, 0, -20), -90.0)
	Dressing.car(self, "taxi", Vector3(6.0, 0, -8), -90.0)
	Dressing.car(self, "sedan", Vector3(-5.8, 0, -16), 90.0, Color(0.12, 0.12, 0.14))
	Dressing.plane_tree(self, Vector3(7.5, 0, 12), 0.45)
	Dressing.plane_tree(self, Vector3(-7.5, 0, -10), 0.45)

	# --- the cast ---
	# the waiter is a SUSPECT and a SENSOR - don't let him see you lift the matchbook
	spawn_talker("res://models/waiter.glb", Vector3(-6.5, 0, -2), {
		"name": "Tariq, the waiter", "persona": WAITER, "clue_id": "l2_waiter", "voice": "waiter",
		"face_yaw": PI / 2.0, "greeting": "We are closed. ...you again. What do you want.",
		"cone": true, "range": 7.0, "fov": 36.0, "scan_arc": 52.0, "scan_speed": 0.6,
		"barks": ["Please, monsieur, not here.", "I saw nothing. Nothing!"],
	})
	spawn_talker("res://models/informant.glb", Vector3(5.5, 0, 10), {
		"name": "Le Furet", "persona": FURET, "voice": "informant",
		"face_yaw": -PI / 2.0, "greeting": "Psst. Vasseur. I know things. What's it worth.",
		"barks": ["I see everything on this street.", "A crate-van. Toward the river. That's free."],
	})
	spawn_talker("res://models/cop.glb", Vector3(4.5, 0, -18), {
		"name": "Gardien Morel", "persona": COP2, "voice": "cop",
		"face_yaw": PI, "greeting": "Go home, monsieur. ...fine. There was a van.",
		"barks": ["Patrol. Move along.", "Double-parked van. I logged it."],
	})
	# seated patrons (gossip + life)
	spawn_talker("res://models/flower_seller.glb", Vector3(-4.2, 0, -0.4), {
		"name": "A bistro patron", "persona": PATRON, "voice": "flower_seller", "seated": true,
		"face_yaw": -PI / 2.0, "greeting": "Sante! Sit. You look like you need a drink.",
		"barks": ["Garcon! Another carafe!", "They lugged crates up from that cellar all night."],
	})
	# a lookout patrolling the street
	spawn_guard(GUARD_A, Vector3(4, 0, -6), {
		"range": 8.0, "fov": 30.0, "speed": 1.6, "tint": Color(0.14, 0.14, 0.18),
		"waypoints": [Vector3(4, 0, -2), Vector3(4, 0, -18), Vector3(-2, 0, -18), Vector3(-2, 0, -2), Vector3(4, 0, -2)],
	})

	# --- evidence + optional investigation ---
	spawn_clue("l2_matches", Vector3(-4.5, 0, -1))           # on the terrasse, under the waiter's gaze
	spawn_lock("l2_cellar", Vector3(-5.0, 0, 12.5), {"label": "Pick the cellar door", "clue_id": "l2_ledger", "pins": 4})
	spawn_photo("l2_crates", Vector3(-6.5, 0, 13.5), {"label": "Photograph the DCRI crates", "lead": "dcri_crates"})
	spawn_note("l2_napkin", "Scrawled napkin", "A napkin under a glass: 'Louvre - Porte des Lions - after close. Bring the archives.'", Vector3(-3.2, 0, 5))
	spawn_eavesdrop("l2_terrace", Vector3(-2, 0, 4), [
		{"speaker": "Patron", "profile": "flower_seller", "text": "Heavy crates, stencilled DCRI. From a bistro cellar! Absurd."},
		{"speaker": "Le Furet", "profile": "informant", "text": "Not absurd. Government archives. They went to the Louvre, the staff door."},
	], "louvre", 3.4)

	make_exit(Vector3(0, 0, -26), true, "THE LOUVRE")

func _neon(pos: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(1.6, 0.5, 0.08)
	mi.mesh = bm
	mi.material_override = WorldKit.mat(col, 0.2, 0.0, 4.0)
	add_child(mi)
	mi.position = pos
	add_light(pos + Vector3(0, 0, 0.5), col, 1.6, 5.0)

func _strip(pos: Vector3, size: Vector2, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var pl := PlaneMesh.new(); pl.size = size
	mi.mesh = pl
	mi.material_override = WorldKit.mat(color, 0.8, 0.1)
	add_child(mi)
	mi.position = pos

func _bistro_interior(c: Vector3) -> void:
	var wallcol := Color(0.28, 0.2, 0.16)
	wall(c + Vector3(-3, 0, -3), c + Vector3(3, 0, -3), 3.0, wallcol)
	wall(c + Vector3(-3, 0, -3), c + Vector3(-3, 0, 3), 3.0, wallcol)
	wall(c + Vector3(3, 0, -3), c + Vector3(3, 0, 3), 3.0, wallcol)
	wall(c + Vector3(-3, 0, 3), c + Vector3(-1.2, 0, 3), 3.0, wallcol)
	wall(c + Vector3(1.2, 0, 3), c + Vector3(3, 0, 3), 3.0, wallcol)
	_strip(c + Vector3(0, 0.05, 0), Vector2(6, 6), Color(0.3, 0.22, 0.16))
	prop("res://models/v_ms_cabinet_basic.glb", c + Vector3(2, 0, -2), 180, 1.0, true)
	prop("res://models/crate.glb", c + Vector3(0, 0, -0.5), 0, 1.0, false)
	prop("res://models/food.glb", c + Vector3(0, 0.7, -0.5), 0, 1.0, false)
	prop("res://models/v_ms_candle.glb", c + Vector3(-2, 0, -2), 0, 1.0, false)
	add_light(c + Vector3(0, 2.4, 0), Color(1.0, 0.72, 0.4), 3.2, 7)

extends LevelBase
## District 1 - MONTMARTRE, golden evening. A roamable square of winding streets, a lit
## cafe, market stalls and a busker. Tail the kidnapper's van crew without being seen;
## photograph the van, lift the receipt, talk to the locals, and deduce the lead to the Marais.

const KIDNAPPER := "res://models/henchman.glb"

const MIREILLE := "You are Mireille, an old flower-seller who has worked the Montmartre steps every evening for forty years, Paris. You miss nothing on this square. Tonight you saw a black panel van and three hard-faced men in dark coats load crates near the funicular, and a little girl who did not want to go. You are wry, warm and a little frightened. If Etienne is gentle you will tell him about the van and point him to the cafe terrace and the chalk marks on the wall. Speak in short, warm, atmospheric lines with a faint French inflection. Never narrate actions. Never break character."
const WAITER1 := "You are Gilles, the tired night waiter at a Montmartre cafe on the square, Paris. You served the men in dark coats earlier; they left a receipt on the terrace and argued about an address in the Marais. You are evasive - you do not want trouble - but under kind pressure you admit the men were rough and in a hurry. Speak in short, weary, atmospheric lines. Never narrate actions. Never break character."
const BUSKER := "You are Theo, a street musician who plays accordion on the Montmartre steps every night, Paris. You are dreamy, philosophical and slightly drunk on the evening. You half-noticed the van and the men but you mostly want to talk about Paris, love and the light. Occasionally you let slip something useful about which way the van went. Speak in short, lyrical, atmospheric lines. Never narrate actions. Never break character."
const COP1 := "You are Brigadier Lefevre of the Police Nationale, posted on the Montmartre square, Paris. You are bored, officious and unhelpful at first. You will not take a frantic father seriously, but if Etienne stays calm you let slip that you waved a black van through earlier and thought nothing of it. Speak in short, clipped, official lines. Never narrate actions. Never break character."

func _level_index() -> int:
	return 1

func _env_profile() -> Dictionary:
	return {
		"outdoor": true,
		"sky_top": Color(0.36, 0.30, 0.46),
		"sky_horizon": Color(0.98, 0.62, 0.32),
		"ground": Color(0.18, 0.12, 0.10),
		"ambient_color": Color(0.55, 0.42, 0.34),
		"ambient_energy": 1.15,
		"sky_contrib": 0.5,
		"sun_color": Color(1.0, 0.72, 0.42),
		"sun_energy": 1.25,
		"sun_rot": Vector3(-16.0, 48.0, 0.0),
		"fog_color": Color(0.85, 0.55, 0.38),
		"fog_density": 0.012,
		"exposure": 1.05,
		"ambience": "amb_street",
		"base_tension": 0.0,
	}

func _build_level() -> void:
	place_player(Vector3(0, 0, 24), 0.0)
	set_objective("MONTMARTRE\nFind the van crew. Don't be seen. Read the square.")

	# warm cobbled square + side street
	ground(Vector2(52, 64), Color(0.30, 0.24, 0.21), Vector3(0, 0, -4))
	_strip(Vector3(0, 0.04, -4), Vector2(8, 64), Color(0.34, 0.27, 0.24))   # the lane down the middle

	# Haussmann walls lining the square (kept off the lane so you can roam)
	var i := 0
	for spec: Array in [
		[Vector3(-20, 0, 10), Vector3(12, 22, 12), 90.0],
		[Vector3(-20, 0, -8), Vector3(12, 26, 12), 90.0],
		[Vector3(-20, 0, -24), Vector3(12, 20, 12), 90.0],
		[Vector3(20, 0, 8), Vector3(12, 24, 12), -90.0],
		[Vector3(20, 0, -10), Vector3(12, 28, 12), -90.0],
		[Vector3(20, 0, -26), Vector3(12, 22, 12), -90.0],
		[Vector3(0, 0, -34), Vector3(16, 30, 12), 0.0],
	]:
		haussmann_block(spec[0], spec[1], spec[2], float(i + 1),
			Color(0.66, 0.5, 0.36) if i % 2 == 0 else Color(0.6, 0.46, 0.34))
		i += 1
	place_tower(Vector3(28, -8, -180), 1.2, 18.0)   # Sacre-Coeur-ish silhouette stand-in (Eiffel mesh, far)

	# --- the lit cafe on the left ---
	var cafe := Vector3(-11, 0, 6)
	Dressing.awning(self, cafe + Vector3(2.0, 3.2, 1.2), 5.0, 0.0, Color(0.7, 0.16, 0.16))
	Dressing.string_lights(self, cafe + Vector3(-2, 3.4, 2.2), cafe + Vector3(6, 3.4, 2.2), 8)
	Dressing.cafe_set(self, cafe + Vector3(1, 0, 3))
	Dressing.cafe_set(self, cafe + Vector3(4, 0, 3.5))
	add_light(cafe + Vector3(2, 2.6, 2), Color(1.0, 0.8, 0.45), 3.0, 8)

	# --- market stalls on the square ---
	Dressing.market_stall(self, Vector3(8, 0, 2), -20.0, Color(0.8, 0.3, 0.25))
	Dressing.market_stall(self, Vector3(10, 0, -6), 25.0, Color(0.3, 0.5, 0.7))
	Dressing.kiosk(self, Vector3(13, 0, -18), -60.0)

	# --- street furniture / dressing down the lane ---
	for z in [16, 4, -8, -20]:
		Dressing.street_light(self, Vector3(-6.5, 0, z), 0.0, Color(1.0, 0.78, 0.42))
		Dressing.street_light(self, Vector3(6.5, 0, z - 6), 0.0, Color(1.0, 0.78, 0.42))
	Dressing.bench(self, Vector3(-5.5, 0, 12), 90.0)
	Dressing.bench(self, Vector3(5.5, 0, -2), -90.0)
	Dressing.hydrant(self, Vector3(5.6, 0, 14))
	Dressing.trash(self, Vector3(-5.6, 0, -16), "B")
	Dressing.plane_tree(self, Vector3(-7.5, 0, -2), 0.5)
	Dressing.plane_tree(self, Vector3(7.5, 0, 8), 0.55)
	Dressing.plane_tree(self, Vector3(7.5, 0, -22), 0.5)
	for b in [Vector3(-8, 0, 18), Vector3(9, 0, 16), Vector3(-9, 0, -28), Vector3(9, 0, -30)]:
		Dressing.bush(self, b, 1.1)
	Dressing.car(self, "sedan", Vector3(-6.2, 0, -10), 90.0, Color(0.2, 0.22, 0.26))
	Dressing.car(self, "hatchback", Vector3(6.4, 0, 4), -90.0, Color(0.5, 0.12, 0.12))

	# --- the black van (the photo op that gives you the plate) ---
	var van_pos := Vector3(6.0, 0, -24)
	_van(van_pos, -90.0)
	spawn_photo("l1_van_photo", van_pos + Vector3(-1.6, 0, 0), {
		"label": "Photograph the van's plate", "clue_id": "l1_van",
	})

	# --- the cast ---
	spawn_talker("res://models/flower_seller.glb", Vector3(7.5, 0, 0), {
		"name": "Mireille, the flower-seller", "persona": MIREILLE, "voice": "flower_seller",
		"face_yaw": -PI / 2.0, "clue_id": "",
		"greeting": "Monsieur Vasseur... you have your mother's worried eyes. Ask me what I saw.",
		"barks": ["Roses, monsieur? No? ...you are looking for someone.", "That van. It had no business on my square."],
	})
	spawn_talker("res://models/waiter.glb", Vector3(-7.0, 0, 7), {
		"name": "Gilles, the cafe waiter", "persona": WAITER1, "voice": "waiter",
		"face_yaw": PI / 2.0, "seated": false,
		"greeting": "We are closing, monsieur. ...you are not here for coffee, are you.",
		"barks": ["Last orders!", "Those men did not tip. Rough sort."],
	})
	var busker := spawn_talker("res://models/musician.glb", Vector3(2.5, 0, 14), {
		"name": "Theo, the busker", "persona": BUSKER, "voice": "musician",
		"face_yaw": PI, "greeting": "Ah, a sad face for a golden evening. Sit, listen.",
		"barks": ["La la... Paris is a song nobody finishes.", "The van went east. East, toward the Marais."],
	})
	Audio.attach_loop_3d(busker, "accordion", -3.0, 20.0)
	spawn_talker("res://models/cop.glb", Vector3(-3.0, 0, -22), {
		"name": "Brigadier Lefevre", "persona": COP1, "voice": "cop",
		"face_yaw": 0.0, "greeting": "Move along, monsieur. ...what van?",
		"barks": ["Circulez. Nothing to see.", "I waved a black van through. Routine."],
	})
	# kids playing near the cafe (pure Parisian life)
	spawn_talker("res://models/kid.glb", Vector3(-3.5, 0, 16), {
		"name": "A kid", "voice": "kid",
		"persona": "You are a Montmartre street kid playing tag at dusk, Paris. You are cheeky and distractible but you saw the men put a crying girl in a black van. You will blurt it out if asked directly. Short, childish lines. Never narrate actions. Never break character.",
		"greeting": "You're it! ...hey, are you a flic?",
		"barks": ["Tag! You're it!", "We saw a girl crying in that van. Weird."],
		"waypoints": [Vector3(-3.5, 0, 16), Vector3(-1.0, 0, 18), Vector3(-4.5, 0, 19), Vector3(-3.5, 0, 16)],
		"speed": 1.6,
	})

	# the kidnapper you tail + sentries (the stealth spine)
	spawn_guard(KIDNAPPER, Vector3(2, 0, -6), {
		"range": 8.5, "fov": 34.0, "speed": 1.7,
		"waypoints": [Vector3(2, 0, -6), Vector3(4, 0, -22), Vector3(-3, 0, -26), Vector3(-2, 0, -10), Vector3(2, 0, -6)],
	})
	spawn_guard(GUARD_A, Vector3(-4, 0, -28), {"range": 8.5, "fov": 30.0, "face_yaw": 0.0, "scan_arc": 60.0, "tint": Color(0.16, 0.16, 0.2)})
	spawn_guard(GUARD_B, Vector3(5, 0, -16), {"range": 8.5, "fov": 30.0, "face_yaw": PI, "scan_arc": 55.0, "tint": Color(0.18, 0.16, 0.2)})

	# --- evidence + optional investigation ---
	spawn_clue("l1_receipt", Vector3(-9.0, 0, 7))            # on the cafe terrace
	spawn_note("l1_chalk", "Chalk route", "Chalk arrows scrawled on the wall, heading east toward the Marais - and a hasty word: 'Corbeau'.", Vector3(-7.5, 0, -18))
	spawn_lock("l1_cellar", Vector3(-9.5, 0, -2), {"label": "Jimmy the cafe cellar hatch", "lead": "montmartre_cellar", "pins": 3})
	spawn_eavesdrop("l1_gossip", Vector3(9, 0, 8), [
		{"speaker": "Vendor", "profile": "informant", "text": "Three of them. Crates. And the child - she fought them."},
		{"speaker": "Mireille", "profile": "flower_seller", "text": "Hush. They drove east. Le Corbeau, in the Marais. Say nothing."},
	], "marais_bistro", 3.4)

	make_exit(Vector3(0, 0, -30), true, "EAST - THE MARAIS")

func _van(pos: Vector3, yaw_deg: float) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = WorldKit.L_WORLD
	body.collision_mask = 0
	var mat := WorldKit.mat(Color(0.07, 0.07, 0.09), 0.5, 0.3)
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(2.0, 1.9, 4.6)
	box.mesh = bm; box.material_override = mat; box.position.y = 1.15
	body.add_child(box)
	var cab := MeshInstance3D.new()
	var cm := BoxMesh.new(); cm.size = Vector3(2.0, 1.2, 1.4)
	cab.mesh = cm; cab.material_override = mat; cab.position = Vector3(0, 0.95, 2.6)
	body.add_child(cab)
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new(); cs.size = Vector3(2.0, 2.1, 6.0)
	col.shape = cs; col.position.y = 1.05
	body.add_child(col)
	add_child(body)
	body.position = pos
	body.rotation_degrees.y = yaw_deg

func _strip(pos: Vector3, size: Vector2, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var pl := PlaneMesh.new(); pl.size = size
	mi.mesh = pl
	mi.material_override = WorldKit.mat(color, 0.9)
	add_child(mi)
	mi.position = pos

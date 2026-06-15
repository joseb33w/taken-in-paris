extends LevelBase
## District 5 - EIFFEL TOWER FINALE, blue night. Reach Margaux and the mastermind before the
## helicopter spools up. How many clues you cracked AND how thoroughly you investigated Paris
## (leads found) set the clock, the cordon, and how it ends.

const MASTERMIND := "res://models/henchman.glb"

var _clock := 60.0
var _clock_total := 60.0
var _ended := false
var _rotor: Node3D
var _tier := 1
var _thorough := 0

func _level_index() -> int:
	return 5

func _is_outdoor() -> bool:
	return true

func _env_profile() -> Dictionary:
	return {
		"outdoor": true,
		"sky_top": Color(0.02, 0.03, 0.10),
		"sky_horizon": Color(0.10, 0.12, 0.26),
		"ground": Color(0.04, 0.05, 0.08),
		"ambient_color": Color(0.22, 0.26, 0.42),
		"ambient_energy": 0.9,
		"sky_contrib": 0.45,
		"sun_color": Color(0.45, 0.55, 0.95),
		"sun_energy": 0.4,
		"sun_rot": Vector3(-60.0, 25.0, 0.0),
		"fog_color": Color(0.10, 0.13, 0.26),
		"fog_density": 0.014,
		"exposure": 1.05,
		"ambience": "amb_street",
		"base_tension": 0.35,
	}

func _build_level() -> void:
	place_player(Vector3(0, 0, 22), 0.0)

	var solved := Game.clues_solved
	_thorough = Game.leads_found().size()
	if solved >= 3:
		_tier = 3
		_clock_total = 78.0
	elif solved == 2:
		_tier = 2
		_clock_total = 62.0
	else:
		_tier = 1
		_clock_total = 50.0
	# investigating Paris thoroughly buys you an edge at the finale
	if _thorough >= 4 and _tier < 3:
		_tier += 1
		_clock_total += 12.0
	_clock = _clock_total

	ground(Vector2(46, 70), Color(0.13, 0.14, 0.17), Vector3(0, 0, -8))
	place_tower(Vector3(0, 0, -42), 0.5, 0.0)
	haussmann_block(Vector3(-22, 0, 6), Vector3(11, 24, 11), 90, 2.0, Color(0.42, 0.42, 0.5))
	haussmann_block(Vector3(22, 0, 6), Vector3(11, 22, 11), -90, 4.0, Color(0.44, 0.42, 0.5))
	haussmann_block(Vector3(-22, 0, -16), Vector3(11, 26, 11), 90, 6.0, Color(0.4, 0.4, 0.5))
	haussmann_block(Vector3(22, 0, -16), Vector3(11, 24, 11), -90, 8.0, Color(0.42, 0.42, 0.52))
	add_light(Vector3(0, 8, -10), Color(0.5, 0.6, 0.95), 1.5, 40)

	# plaza dressing
	for z in [12, 0, -12]:
		Dressing.street_light(self, Vector3(-12, 0, z), 0.0, Color(0.7, 0.8, 1.0))
		Dressing.street_light(self, Vector3(12, 0, z), 0.0, Color(0.7, 0.8, 1.0))
	Dressing.bench(self, Vector3(-9, 0, 14), 0.0)
	Dressing.bench(self, Vector3(9, 0, 14), 0.0)
	Dressing.car(self, "police", Vector3(-12, 0, 18), 90.0)
	Dressing.car(self, "sedan", Vector3(12, 0, 18), -90.0, Color(0.1, 0.1, 0.12))
	prop("res://models/v_ms_barrier_road.glb", Vector3(-4, 0, 16), 0, 1.0, true)
	prop("res://models/v_ms_barrier_road.glb", Vector3(4, 0, 16), 0, 1.0, true)
	Dressing.plane_tree(self, Vector3(-15, 0, 2), 0.55)
	Dressing.plane_tree(self, Vector3(15, 0, 2), 0.55)

	# helicopter on its pad, rotors winding up (with a rotor-spool loop)
	_helipad(Vector3(0, 0, -32))

	# the mastermind + Margaux
	var boss := WorldKit.instance_glb(MASTERMIND)
	if boss == null:
		boss = Node3D.new()
	add_child(boss)
	boss.position = Vector3(-1.5, 0, -28)
	var bl := Locomotion.new()
	bl.setup(boss)
	bl.play("idle")
	var girl := WorldKit.instance_glb("res://models/daughter.glb")
	if girl != null:
		add_child(girl)
		girl.position = Vector3(1.6, 0, -28)
		var gl := Locomotion.new()
		gl.setup(girl)
		gl.play("scared")
	add_light(Vector3(0, 3, -28), Color(1.0, 0.8, 0.5), 2.6, 8)

	# guards between you and her, scaled by how blind you are going in
	var guard_sets := {
		3: [[Vector3(-6, 0, 4), -PI / 2.0], [Vector3(6, 0, -8), PI / 2.0]],
		2: [[Vector3(-6, 0, 6), -PI / 2.0], [Vector3(6, 0, -4), PI / 2.0], [Vector3(0, 0, -14), 0.0]],
		1: [[Vector3(-7, 0, 8), -PI / 2.0], [Vector3(7, 0, 2), PI / 2.0], [Vector3(-5, 0, -10), 0.0], [Vector3(6, 0, -16), 0.0]],
	}
	var sets: Array = guard_sets[_tier]
	var idx := 0
	for entry: Array in sets:
		var model := GUARD_A if idx % 2 == 0 else GUARD_B
		spawn_guard(model, entry[0], {
			"range": 8.5, "fov": 32.0, "face_yaw": entry[1], "scan_arc": 58.0,
			"tint": Color(0.14, 0.14, 0.18),
			"waypoints": [entry[0], entry[0] + Vector3(0, 0, -4)] if idx % 2 == 1 else [],
		})
		idx += 1

	spawn_clue("l5_manifest", Vector3(-8, 0, -2))
	spawn_photo("l5_face", Vector3(-3.0, 0, -24), {"label": "Photograph the mastermind", "lead": "mastermind_id"})

	var rescue := Area3D.new()
	rescue.collision_layer = 0
	rescue.collision_mask = WorldKit.L_PLAYER
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 3.2
	cs.height = 3.0
	col.shape = cs
	col.position.y = 1.5
	rescue.add_child(col)
	add_child(rescue)
	rescue.position = Vector3(0.5, 0, -28)
	rescue.body_entered.connect(_on_reach)

	set_objective("EIFFEL TOWER\nReach Margaux before the helicopter lifts off.")
	if hud != null:
		hud.set_clock("ROTORS  " + Game.format_time(_clock), false)
	# the mastermind's taunt
	var tm := get_tree().create_timer(1.6)
	tm.timeout.connect(func() -> void:
		Voice.say("You actually came, Vasseur. The rotors are turning. You are already too late.", "henchman", "The mastermind"))

func _level_process(delta: float) -> void:
	if _ended:
		return
	_clock -= delta
	if _rotor != null:
		var spin: float = lerpf(3.0, 46.0, 1.0 - clampf(_clock / _clock_total, 0.0, 1.0))
		_rotor.rotate_y(spin * delta)
	if hud != null:
		hud.set_clock("ROTORS  " + Game.format_time(maxf(0.0, _clock)), _clock < 15.0)
	Audio.set_tension(clampf(maxf(detection, 0.4 + (1.0 - _clock / _clock_total) * 0.6), 0.0, 1.0))
	if _clock <= 0.0:
		_miss()

func _miss() -> void:
	_clock = maxf(18.0, _clock_total * 0.5)
	Audio.sfx("sfx_spotted")
	if hud != null:
		hud.flash_msg("He's lifting off - GO NOW")
	if player != null:
		player.teleport(spawn_pos, spawn_yaw)
		player.shake(0.25)
	_flash_alarm()

func _on_reach(body: Node3D) -> void:
	if _ended or not (body is Player):
		return
	_ended = true
	if player != null:
		player.control_enabled = false
		player.shake(0.2)
	Audio.set_tension(0.0)
	Audio.sfx("sfx_deduce")
	WorldKit.spawn_burst(self, Vector3(0.5, 1.0, -28), Color(0.5, 1.0, 0.7), 30)
	if hud != null:
		hud.set_clock("", false)
		hud.flash_msg("MARGAUX IS SAFE")
	Voice.say("Papa! I knew you'd come.", "margaux", "Margaux")
	var result := _ending_for_tier()
	var tm := get_tree().create_timer(2.4)
	tm.timeout.connect(func() -> void: finish_finale(result))

func _ending_for_tier() -> Dictionary:
	var coda := "  You found %d extra leads reading the city." % _thorough if _thorough > 0 else ""
	if _tier >= 3:
		return {"outcome": "win", "title": "PERFECT RESCUE",
			"text": "You read every clue Paris left you, anticipated the handoff, and reached Margaux before the rotors even turned. The mastermind never saw you coming. She is safe, and the network is blown wide open." + coda}
	elif _tier == 2:
		return {"outcome": "win", "title": "RESCUE",
			"text": "The leads you cracked were enough. You cut through the cordon and pulled Margaux clear as the helicopter strained against its moorings. Close - but she is in your arms, and Paris exhales." + coda}
	return {"outcome": "win", "title": "NARROW ESCAPE",
		"text": "Half-blind, working on instinct and too few clues, you threw yourself through the rotor-wash and dragged Margaux from the skids at the last second. You both made it - barely. Next time, read the city closer." + coda}

func _helipad(pos: Vector3) -> void:
	var pad := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 4.0
	cyl.bottom_radius = 4.0
	cyl.height = 0.1
	pad.mesh = cyl
	pad.material_override = WorldKit.mat(Color(0.9, 0.7, 0.2), 0.4, 0.0, 1.2)
	add_child(pad)
	pad.position = pos + Vector3(0, 0.06, 0)

	var heli := Node3D.new()
	add_child(heli)
	heli.position = pos + Vector3(0, 0.6, 0)
	var bodym := MeshInstance3D.new()
	var bbm := BoxMesh.new()
	bbm.size = Vector3(1.8, 1.4, 3.4)
	bodym.mesh = bbm
	bodym.material_override = WorldKit.mat(Color(0.1, 0.12, 0.15), 0.4, 0.5)
	bodym.position.y = 0.7
	heli.add_child(bodym)
	var tail := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(0.3, 0.3, 2.6)
	tail.mesh = tb
	tail.material_override = WorldKit.mat(Color(0.1, 0.12, 0.15), 0.4, 0.5)
	tail.position = Vector3(0, 0.9, 2.6)
	heli.add_child(tail)
	var mast := MeshInstance3D.new()
	var mm := CylinderMesh.new()
	mm.top_radius = 0.08
	mm.bottom_radius = 0.08
	mm.height = 0.5
	mast.mesh = mm
	mast.position.y = 1.6
	mast.material_override = WorldKit.mat(Color(0.08, 0.08, 0.1), 0.4, 0.6)
	heli.add_child(mast)
	_rotor = Node3D.new()
	_rotor.position.y = 1.85
	heli.add_child(_rotor)
	for i in range(4):
		var blade := MeshInstance3D.new()
		var blm := BoxMesh.new()
		blm.size = Vector3(5.0, 0.05, 0.22)
		blade.mesh = blm
		blade.material_override = WorldKit.mat(Color(0.05, 0.05, 0.06), 0.4)
		blade.rotation.y = i * (PI / 2.0)
		_rotor.add_child(blade)
	add_light(pos + Vector3(0, 2, 0), Color(1.0, 0.8, 0.4), 2.2, 8)
	Audio.attach_loop_3d(heli, "sfx_heli", -4.0, 40.0)

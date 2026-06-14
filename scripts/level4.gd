extends LevelBase
## Level 4 - The Catacombs. Descend to the "rescue" - it is a trap. An alarm trips, the
## tunnels begin to seal, and you sprint back to the surface before the clock runs out.

const SEAL_SECONDS := 30.0

var _sprung := false
var _sprinting := false
var _seal_time := SEAL_SECONDS
var _chamber_start := Vector3(0, 0, -12)
var _gates: Array = []

func _level_index() -> int:
	return 4

func _is_outdoor() -> bool:
	return false

func _build_level() -> void:
	place_player(Vector3(0, 0, 18), 0.0)
	set_objective("THE CATACOMBS\nFollow the tunnel down. Find Margaux.")

	# tunnel floor + ceiling + walls (a straight bone-lined corridor into a chamber)
	var stone := Color(0.26, 0.24, 0.2)
	ground(Vector2(12, 48), Color(0.18, 0.16, 0.14), Vector3(0, 0, -2), "")
	_ceiling(Vector3(0, 4, -2), Vector2(12, 48))
	wall(Vector3(-3.5, 0, 20), Vector3(-3.5, 0, -12), 4.0, stone)
	wall(Vector3(3.5, 0, 20), Vector3(3.5, 0, -12), 4.0, stone)
	wall(Vector3(-3.5, 0, 20), Vector3(3.5, 0, 20), 4.0, stone)
	# chamber (widened) at the far end
	wall(Vector3(-7, 0, -12), Vector3(-3.5, 0, -12), 4.0, stone)
	wall(Vector3(3.5, 0, -12), Vector3(7, 0, -12), 4.0, stone)
	wall(Vector3(-7, 0, -12), Vector3(-7, 0, -22), 4.0, stone)
	wall(Vector3(7, 0, -12), Vector3(7, 0, -22), 4.0, stone)
	wall(Vector3(-7, 0, -22), Vector3(7, 0, -22), 4.0, stone)
	ground(Vector2(14, 12), Color(0.2, 0.18, 0.15), Vector3(0, 0, -17), "")
	_ceiling(Vector3(0, 4, -17), Vector2(14, 12))

	# bone-pile / crypt dressing + candle light
	prop("res://models/v_ms_brick_pile.glb", Vector3(-2.6, 0, 8), 10, 1.0, false)
	prop("res://models/v_ms_brick_pile.glb", Vector3(2.6, 0, -4), -30, 1.0, false)
	prop("res://models/v_ms_cable_reel.glb", Vector3(2.4, 0, 2), 0, 1.0, true)
	_candle(Vector3(-3.2, 1.2, 12))
	_candle(Vector3(3.2, 1.2, 0))
	_candle(Vector3(-3.2, 1.2, -8))
	_candle(Vector3(-6.5, 1.2, -18))
	_candle(Vector3(6.5, 1.2, -18))
	add_light(Vector3(0, 3, 10), Color(0.9, 0.6, 0.35), 1.6, 9)
	add_light(Vector3(0, 3, -6), Color(0.9, 0.55, 0.3), 1.6, 9)

	# the lure: "Margaux" waiting in the chamber (it is a decoy)
	var girl := WorldKit.instance_glb("res://models/daughter.glb")
	if girl != null:
		add_child(girl)
		girl.position = Vector3(0, 0, -19)
		girl.rotation_degrees.y = 0.0
		var loco := Locomotion.new()
		loco.setup(girl)
		loco.play("idle")
	add_light(Vector3(0, 2.5, -19), Color(0.6, 0.75, 1.0), 2.4, 6)

	# the trap trigger
	var trap := Area3D.new()
	trap.collision_layer = 0
	trap.collision_mask = WorldKit.L_PLAYER
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8, 3, 5)
	col.shape = box
	col.position.y = 1.5
	trap.add_child(col)
	add_child(trap)
	trap.position = Vector3(0, 0, -18)
	trap.body_entered.connect(_on_trap)

func _on_trap(body: Node3D) -> void:
	if _sprung or not (body is Player):
		return
	_sprung = true
	_sprinting = true
	_seal_time = SEAL_SECONDS
	Game.add_clue("l4_note")
	Game.add_clue("l4_charge")
	Game.force_solve(4)
	set_objective("RUN. The tunnels are sealing behind you.")
	if hud != null:
		hud.flash_msg("IT'S A TRAP - RUN")
		hud.set_clock("SEAL  " + Game.format_time(SEAL_SECONDS), true)
	_flash_alarm()
	if player != null:
		player.shake(0.3)
	# the exit opens back at the surface (sprint target)
	make_exit(Vector3(0, 0, 19), false)
	# drop the sealing gates behind you over the countdown
	_drop_gate(Vector3(0, 0, -10), SEAL_SECONDS * 0.2)
	_drop_gate(Vector3(0, 0, 0), SEAL_SECONDS * 0.45)
	_drop_gate(Vector3(0, 0, 10), SEAL_SECONDS * 0.7)

func _level_process(delta: float) -> void:
	if not _sprinting:
		return
	_seal_time -= delta
	if hud != null:
		hud.set_clock("SEAL  " + Game.format_time(maxf(0.0, _seal_time)), true)
	if _seal_time <= 0.0:
		_fail_sprint()

func _fail_sprint() -> void:
	_seal_time = SEAL_SECONDS
	if hud != null:
		hud.flash_msg("The tunnel sealed - go again")
		hud.set_clock("SEAL  " + Game.format_time(SEAL_SECONDS), true)
	if player != null:
		player.teleport(_chamber_start, 0.0)
		player.shake(0.2)
	_flash_alarm()

func _drop_gate(pos: Vector3, when: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(7, 4, 0.4)
	mi.mesh = bm
	mi.material_override = WorldKit.mat(Color(0.2, 0.18, 0.16), 0.8, 0.2)
	add_child(mi)
	mi.position = pos + Vector3(0, 6.0, 0)
	_gates.append(mi)
	var tm := get_tree().create_timer(when)
	tm.timeout.connect(func() -> void:
		if not is_instance_valid(mi):
			return
		var t := mi.create_tween()
		t.tween_property(mi, "position:y", 2.0, 0.5).set_trans(Tween.TRANS_BOUNCE)
		if player != null:
			player.shake(0.12))

func _candle(pos: Vector3) -> void:
	prop("res://models/v_ms_candle.glb", pos - Vector3(0, 1.2, 0), 0, 1.2, false)
	add_light(pos, Color(1.0, 0.6, 0.25), 1.4, 5)

func _ceiling(pos: Vector3, size: Vector2) -> void:
	var mi := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = size
	mi.mesh = pl
	mi.rotation_degrees.x = 180.0
	mi.material_override = WorldKit.mat(Color(0.12, 0.1, 0.09), 0.95)
	add_child(mi)
	mi.position = pos

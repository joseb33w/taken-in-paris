class_name Player
extends CharacterBody3D
## Third-person stealth controller. Dual input: left-half virtual joystick + WASD to move,
## right-half drag + mouse-drag to look. Action buttons are real Controls that consume their
## own touch, so dragging to look NEVER triggers interact/takedown. Hold-interact to collect
## clues; tap to talk; takedown a guard from close behind.

const WALK_SPEED := 2.9
const RUN_SPEED := 5.6
const SNEAK_SPEED := 1.9
const RUN_ANIM_THRESH := 3.5
const ACCEL := 12.0
const GRAVITY := 20.0
const LOOK_SENS := 0.005
const INTERACT_RANGE := 2.7
const INTERACT_HOLD := 0.6
const TAKEDOWN_RANGE := 2.4
const MODEL_YAW_OFFSET := 0.0   # spy_hero.glb is authored facing +Z; no PI flip needed

var control_enabled := true
var is_sneaking := false
var is_moving := false

var hud: Node
var level: Node

var _model: Node3D
var _loco := Locomotion.new()
var _pivot: Node3D
var _spring: SpringArm3D
var _cam: Camera3D
var _yaw := 0.0
var _model_yaw := 0.0

var _move_touch := -1
var _move_origin := Vector2.ZERO
var _move_vec := Vector2.ZERO
var _look_touch := -1

var _hud_interact := false
var _interact_held := false
var _interact_prev := false
var _hold_t := 0.0
var _cur_target: Node = null

var _shake := 0.0
var _cam_base := Vector3.ZERO

func _ready() -> void:
	collision_layer = WorldKit.L_PLAYER
	collision_mask = WorldKit.L_WORLD

	var col := CollisionShape3D.new()
	var caps := CapsuleShape3D.new()
	caps.radius = 0.34
	caps.height = 1.7
	col.shape = caps
	col.position.y = 0.9
	add_child(col)

	_pivot = Node3D.new()
	_pivot.position = Vector3(0.0, 1.45, 0.0)
	add_child(_pivot)
	_spring = SpringArm3D.new()
	_spring.spring_length = 5.3
	_spring.rotation_degrees.x = -20.0
	_spring.collision_mask = WorldKit.L_WORLD
	_spring.margin = 0.35
	_pivot.add_child(_spring)
	_cam = Camera3D.new()
	_cam.fov = 66.0
	_spring.add_child(_cam)
	_cam.current = true
	_cam_base = Vector3.ZERO

	_model = WorldKit.instance_glb("res://models/spy_hero.glb")
	if _model == null:
		_model = _fallback_model()
	add_child(_model)
	_loco.setup(_model)
	_loco.play("idle")

func set_camera_yaw(y: float) -> void:
	_yaw = y

func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if control_enabled:
		input = _keyboard_vector() + _move_vec
		if input.length() > 1.0:
			input = input.normalized()

	var max_speed := SNEAK_SPEED if is_sneaking else (RUN_SPEED if input.length() > 0.82 else WALK_SPEED)
	var world_dir := (Basis(Vector3.UP, _yaw) * Vector3(input.x, 0.0, input.y))
	world_dir.y = 0.0
	var target_h := world_dir * (input.length() * max_speed)
	velocity.x = move_toward(velocity.x, target_h.x, ACCEL * delta)
	velocity.z = move_toward(velocity.z, target_h.z, ACCEL * delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -1.0
	move_and_slide()

	var hspeed := Vector2(velocity.x, velocity.z).length()
	is_moving = hspeed > 0.25
	if is_moving and world_dir.length() > 0.05:
		var want := atan2(world_dir.x, world_dir.z) + MODEL_YAW_OFFSET
		_model_yaw = lerp_angle(_model_yaw, want, 0.22)
		_model.rotation.y = _model_yaw
		if hspeed > RUN_ANIM_THRESH and not is_sneaking:
			_loco.play("run", 1.1)
		else:
			_loco.play("walk", 1.4 if is_sneaking else 1.0)
	else:
		_loco.play("idle")

	_pivot.rotation.y = _yaw
	if _shake > 0.001:
		_shake = move_toward(_shake, 0.0, delta * 2.5)
		_cam.position = _cam_base + Vector3(randf_range(-_shake, _shake), randf_range(-_shake, _shake), 0.0)
	else:
		_cam.position = _cam_base

func _process(delta: float) -> void:
	if not control_enabled:
		_interact_held = false
		_interact_prev = false
		if hud != null and hud.has_method("set_prompt"):
			hud.call("set_prompt", "")
		return
	_interact_held = _hud_interact or Input.is_action_pressed("interact")
	var interact_just := _interact_held and not _interact_prev
	_interact_prev = _interact_held

	if Input.is_action_just_pressed("sneak"):
		toggle_sneak()
	if Input.is_action_just_pressed("takedown"):
		try_takedown()
	if Input.is_action_just_pressed("dossier"):
		_open_dossier()

	_update_interaction(delta, interact_just)

func _update_interaction(delta: float, interact_just: bool) -> void:
	var target := _nearest_interactable()
	if target != _cur_target:
		_cur_target = target
		_hold_t = 0.0
		if hud != null:
			hud.call("set_hold", 0.0)
	if target == null:
		if hud != null:
			hud.call("set_prompt", "")
		return
	var kind := str(target.call("interact_kind"))
	if kind == "talk":
		if hud != null:
			hud.call("set_prompt", str(target.call("prompt_text")))
		if interact_just:
			_open_chat(target)
	elif kind == "clue":
		if hud != null:
			hud.call("set_prompt", "Hold to " + str(target.call("prompt_text")).to_lower())
		if _interact_held:
			_hold_t += delta
			if hud != null:
				hud.call("set_hold", clampf(_hold_t / INTERACT_HOLD, 0.0, 1.0))
			if _hold_t >= INTERACT_HOLD:
				_hold_t = 0.0
				if hud != null:
					hud.call("set_hold", 0.0)
				_collect(target)
		else:
			_hold_t = 0.0
			if hud != null:
				hud.call("set_hold", 0.0)

func _nearest_interactable() -> Node:
	var best: Node = null
	var best_d := INTERACT_RANGE
	for n in get_tree().get_nodes_in_group("interactable"):
		if not (n is Node3D):
			continue
		if n.has_method("can_interact") and not n.call("can_interact"):
			continue
		var d := global_position.distance_to((n as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = n
	return best

func _collect(target: Node) -> void:
	if target.has_method("collect"):
		target.call("collect")
		WorldKit.hit_flash(_model, Color(0.5, 0.9, 1.0), 0.1)
		shake(0.05)

func _open_chat(target: Node) -> void:
	if level != null and level.has_method("open_chat"):
		level.call("open_chat", target)

func _open_dossier() -> void:
	if level != null and level.has_method("open_dossier"):
		level.call("open_dossier")

func open_dossier_now() -> void:
	_open_dossier()

func toggle_sneak() -> void:
	is_sneaking = not is_sneaking
	if hud != null:
		hud.call("set_sneak", is_sneaking)

func try_takedown() -> void:
	var best: Guard = null
	var best_d := TAKEDOWN_RANGE
	for g in get_tree().get_nodes_in_group("guard"):
		if not (g is Guard):
			continue
		var guard := g as Guard
		if guard.neutralized:
			continue
		var d := global_position.distance_to(guard.global_position)
		if d > best_d:
			continue
		var to_player := (global_position - guard.global_position)
		to_player.y = 0.0
		if to_player.length() < 0.05:
			continue
		if guard.forward().dot(to_player.normalized()) < -0.1:
			best = guard
			best_d = d
	if best != null:
		best.neutralize()
		WorldKit.spawn_burst(level if level != null else get_parent(), best.global_position + Vector3.UP, Color(1.0, 0.85, 0.3), 22)
		shake(0.16)
		if hud != null:
			hud.call("flash_msg", "Guard down")

func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

func set_hud_interact(v: bool) -> void:
	_hud_interact = v

func teleport(p: Vector3, yaw := 0.0) -> void:
	velocity = Vector3.ZERO
	global_position = p
	_yaw = yaw
	_model_yaw = yaw
	if _model != null:
		_model.rotation.y = yaw
	if _pivot != null:
		_pivot.rotation.y = yaw

func _keyboard_vector() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		v.x -= 1.0
	if Input.is_action_pressed("move_right"):
		v.x += 1.0
	if Input.is_action_pressed("move_up"):
		v.y -= 1.0
	if Input.is_action_pressed("move_down"):
		v.y += 1.0
	return v

func _unhandled_input(event: InputEvent) -> void:
	if not control_enabled:
		return
	var half := get_viewport().get_visible_rect().size.x * 0.5
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if t.position.x < half and _move_touch == -1 and not _over_button(t.position):
				_move_touch = t.index
				_move_origin = t.position
				_move_vec = Vector2.ZERO
				if hud != null:
					hud.call("show_joystick", t.position)
			elif t.position.x >= half and _look_touch == -1 and not _over_button(t.position):
				_look_touch = t.index
		else:
			if t.index == _move_touch:
				_move_touch = -1
				_move_vec = Vector2.ZERO
				if hud != null:
					hud.call("hide_joystick")
			elif t.index == _look_touch:
				_look_touch = -1
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _move_touch:
			var off := d.position - _move_origin
			_move_vec = (off / 90.0).limit_length(1.0)
			if hud != null:
				hud.call("move_knob", off.limit_length(60.0))
		elif d.index == _look_touch:
			_yaw -= d.relative.x * LOOK_SENS
	elif event is InputEventMouseMotion:
		var m := event as InputEventMouseMotion
		if m.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_yaw -= m.relative.x * LOOK_SENS

func _over_button(pos: Vector2) -> bool:
	if hud != null and hud.has_method("point_over_button"):
		return bool(hud.call("point_over_button", pos))
	return false

func _fallback_model() -> Node3D:
	var n := Node3D.new()
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.32
	cap.height = 1.7
	body.mesh = cap
	body.position.y = 0.9
	body.material_override = WorldKit.mat(Color(0.16, 0.14, 0.12))
	n.add_child(body)
	var coat := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.7, 0.9, 0.45)
	coat.mesh = bm
	coat.position = Vector3(0.0, 0.7, 0.0)
	coat.material_override = WorldKit.mat(Color(0.22, 0.18, 0.13))
	n.add_child(coat)
	var head := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.17
	sph.height = 0.34
	head.mesh = sph
	head.position.y = 1.74
	head.material_override = WorldKit.mat(Color(0.74, 0.62, 0.54))
	n.add_child(head)
	# a small "+Z is front" nose so the fallback also faces forward correctly
	var nose := MeshInstance3D.new()
	var nb := BoxMesh.new()
	nb.size = Vector3(0.1, 0.1, 0.12)
	nose.mesh = nb
	nose.position = Vector3(0.0, 1.74, 0.2)
	nose.material_override = WorldKit.mat(Color(0.6, 0.5, 0.44))
	n.add_child(nose)
	return n

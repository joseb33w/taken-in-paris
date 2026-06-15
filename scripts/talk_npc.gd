class_name TalkNPC
extends Node3D
## An informant or suspect you can interrogate in free-form conversation (LLM brain). The
## persona carries the NPC's location and a real clue; the first successful exchange logs a
## testimony clue card into the dossier. NPCs also bark ambient lines and pose talk/sit.

var display_name := "Informant"
var npc_persona := ""
var clue_id := ""
var clue_given := false
var voice_profile := "informant"
var greeting := ""
var seated := false
var bark_lines: Array = []
var _bark_cd := 0.0

var _model: Node3D
var _loco := Locomotion.new()
var _waypoints: Array = []
var _wp := 0
var move_speed := 1.1
var model_yaw_offset := 0.0
var talking := false

# optional vision cone (a suspect who must not see you lift the evidence)
var _cone: VisionCone
var neutralized := false
var _scan := false
var _scan_t := 0.0
var _scan_arc := 50.0
var _scan_speed := 0.6
var _base_yaw := 0.0

func setup(model_path: String, opts: Dictionary = {}) -> void:
	display_name = str(opts.get("name", "Informant"))
	npc_persona = str(opts.get("persona", ""))
	clue_id = str(opts.get("clue_id", ""))
	move_speed = float(opts.get("speed", move_speed))
	model_yaw_offset = float(opts.get("yaw_offset", 0.0))
	_base_yaw = float(opts.get("face_yaw", 0.0))
	voice_profile = str(opts.get("voice", "informant"))
	greeting = str(opts.get("greeting", ""))
	seated = bool(opts.get("seated", false))
	var bl: Variant = opts.get("barks", [])
	if bl is Array:
		bark_lines = bl
	_bark_cd = randf_range(3.0, 10.0)
	var wp: Variant = opts.get("waypoints", [])
	if wp is Array:
		for v in wp:
			if v is Vector3:
				_waypoints.append(v)

	add_to_group("interactable")
	add_to_group("talk")

	_model = WorldKit.instance_glb(model_path)
	if _model == null:
		_model = _fallback_model()
	_model.scale = Vector3.ONE * float(opts.get("scale", 1.0))
	add_child(_model)
	var tint: Variant = opts.get("tint", null)
	if tint is Color:
		WorldKit.recolor(_model, tint)
	if model_yaw_offset != 0.0:
		_model.rotation.y = model_yaw_offset
	_loco.setup(_model)
	_loco.play("idle")
	rotation.y = _base_yaw

	if bool(opts.get("cone", false)):
		_cone = VisionCone.new()
		add_child(_cone)
		_cone.build(float(opts.get("range", 7.5)), float(opts.get("fov", 34.0)), Color(1.0, 0.6, 0.3))
		_scan = true
		_scan_arc = float(opts.get("scan_arc", 50.0))
		_scan_speed = float(opts.get("scan_speed", 0.6))
		add_to_group("guard")

func _process(delta: float) -> void:
	if talking:
		return
	_maybe_bark(delta)
	if seated:
		_loco.play("sit")
		return
	if _scan and _waypoints.size() < 2:
		_scan_t += delta * _scan_speed
		rotation.y = _base_yaw + deg_to_rad(_scan_arc) * sin(_scan_t)
		return
	if _waypoints.size() < 2:
		return
	var target: Vector3 = _waypoints[_wp]
	var to := target - global_position
	to.y = 0.0
	var d := to.length()
	if d < 0.3:
		_wp = (_wp + 1) % _waypoints.size()
		return
	var dir := to.normalized()
	global_position += dir * minf(move_speed * delta, d)
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 0.15)
	_loco.play("walk")

func can_see_player(point: Vector3) -> bool:
	return _cone != null and not talking and _cone.can_see(point)

func set_alert(t: float) -> void:
	if _cone != null:
		_cone.set_alert(t)

func forward() -> Vector3:
	var f := global_transform.basis.z
	f.y = 0.0
	return f.normalized() if f.length() > 0.001 else Vector3.FORWARD

func interact_kind() -> String:
	return "talk"

func prompt_text() -> String:
	return "Interrogate " + display_name

func can_interact() -> bool:
	return true

func persona() -> String:
	return npc_persona

func _maybe_bark(delta: float) -> void:
	if bark_lines.is_empty():
		return
	_bark_cd -= delta
	if _bark_cd > 0.0:
		return
	var pl := get_tree().get_first_node_in_group("player")
	if pl == null or not (pl is Node3D):
		return
	if global_position.distance_to((pl as Node3D).global_position) > 7.0:
		_bark_cd = 1.0
		return
	_bark_cd = randf_range(9.0, 17.0)
	var line := str(bark_lines[randi() % bark_lines.size()])
	if Voice.bark(line, voice_profile, display_name):
		_loco.play("gesture")

func voice_key() -> String:
	return voice_profile

func opening_line() -> String:
	return greeting if greeting != "" else "Etienne... you should not be here. What do you want?"

func begin_talk(player_pos: Vector3) -> void:
	talking = true
	_loco.play("talk")
	var to := player_pos - global_position
	to.y = 0.0
	if to.length() > 0.05:
		rotation.y = atan2(to.x, to.z)

func end_talk() -> void:
	talking = false
	_loco.play("sit" if seated else "idle")

func grant_clue() -> String:
	if clue_id != "" and not clue_given and not Game.has_clue(clue_id):
		clue_given = true
		Game.add_clue(clue_id)
		return clue_id
	clue_given = true
	return ""

func _fallback_model() -> Node3D:
	var n := Node3D.new()
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.28
	cap.height = 1.65
	body.mesh = cap
	body.position.y = 0.9
	body.material_override = WorldKit.mat(Color(0.35, 0.3, 0.26))
	n.add_child(body)
	var head := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.17
	sph.height = 0.34
	head.mesh = sph
	head.position.y = 1.7
	head.material_override = WorldKit.mat(Color(0.72, 0.6, 0.52))
	n.add_child(head)
	return n

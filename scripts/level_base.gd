class_name LevelBase
extends Node3D
## Common gameplay frame for a district: environment, player, HUD, dossier, chat, detection
## aggregation, spotted/respawn, exit gating, and pause-on-overlay. Subclasses override
## _level_index(), _build_level(), and optionally _is_outdoor()/_level_process().

var level_num := 1
var main: Node

var player: Player
var hud: Hud
var dossier: Dossier
var chat: ChatPanel

var spawn_pos := Vector3.ZERO
var spawn_yaw := 0.0

var detection := 0.0
var _finished := false
var _spot_lock := 0.0
var _exit_node: Node3D
var _exit_requires_deduction := true
var _alarm_layer: CanvasLayer
var _alarm_rect: ColorRect

# guard models reused as reskinned rank-and-file
const GUARD_A := "res://models/guard_soldier.glb"
const GUARD_B := "res://models/guard_vanguard.glb"
const NPC_MODEL := "res://models/informant.glb"

func _ready() -> void:
	level_num = _level_index()
	Game.current_level = level_num
	_build_common()
	_build_level()
	_show_title()

func _level_index() -> int:
	return 1

func _is_outdoor() -> bool:
	return true

func _build_level() -> void:
	pass

func _level_process(_delta: float) -> void:
	pass

## Set the on-screen objective line (forwards to the HUD). Levels override the title-card
## objective with an in-the-moment instruction by calling this.
func set_objective(text: String) -> void:
	if hud != null:
		hud.set_objective(text)

# ---------------------------------------------------------------- common

func _build_common() -> void:
	_build_env(_is_outdoor())

	player = Player.new()
	add_child(player)
	player.teleport(spawn_pos, spawn_yaw)

	hud = Hud.new()
	hud.setup(player)
	add_child(hud)
	player.hud = hud
	player.level = self

	dossier = Dossier.new()
	add_child(dossier)
	dossier.solved.connect(_on_deduction_solved)
	dossier.closed.connect(_on_overlay_closed)

	chat = ChatPanel.new()
	add_child(chat)
	chat.closed.connect(_on_overlay_closed)

	_alarm_layer = CanvasLayer.new()
	_alarm_layer.layer = 30
	add_child(_alarm_layer)
	_alarm_rect = ColorRect.new()
	_alarm_rect.color = Color(1, 0.1, 0.1, 0.0)
	_alarm_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_alarm_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_alarm_layer.add_child(_alarm_rect)

func _build_env(outdoor: bool) -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	if outdoor:
		env.background_mode = Environment.BG_SKY
		var sky := Sky.new()
		var sm := ShaderMaterial.new()
		sm.shader = load("res://shaders/night_sky.gdshader")
		sky.sky_material = sm
		env.sky = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_sky_contribution = 0.6
		env.ambient_light_color = Color(0.28, 0.32, 0.45)
		env.ambient_light_energy = 1.0
		env.fog_enabled = true
		env.fog_light_color = Color(0.18, 0.2, 0.32)
		env.fog_density = 0.018
		env.fog_sky_affect = 0.2
	else:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.03, 0.035, 0.05)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.2, 0.22, 0.3)
		env.ambient_light_energy = 0.7
		env.fog_enabled = true
		env.fog_light_color = Color(0.05, 0.06, 0.08)
		env.fog_density = 0.03
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
	sun.light_color = Color(0.7, 0.78, 1.0) if outdoor else Color(0.5, 0.55, 0.7)
	sun.light_energy = 0.7 if outdoor else 0.4
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)

	get_viewport().msaa_3d = Viewport.MSAA_2X

func _process(delta: float) -> void:
	if _finished:
		return
	if _spot_lock > 0.0:
		_spot_lock -= delta
	_update_detection(delta)
	if hud != null:
		hud.set_time(Game.format_time(Game.run_elapsed))
	_level_process(delta)

func _update_detection(delta: float) -> void:
	if player == null:
		return
	var p := player.global_position
	var seen := false
	var closest := 999.0
	for g in get_tree().get_nodes_in_group("guard"):
		if not (g is Node3D) or not g.has_method("can_see_player"):
			continue
		var sees: bool = g.call("can_see_player", p)
		if sees:
			seen = true
			closest = minf(closest, p.distance_to((g as Node3D).global_position))
		if g.has_method("set_alert"):
			g.call("set_alert", detection if sees else 0.12)
	if _spot_lock > 0.0:
		seen = false
	if seen:
		var prox := clampf(1.0 - closest / 13.0, 0.25, 1.0)
		var rate := (0.4 + prox * 0.7) * (0.45 if player.is_sneaking else 1.0)
		detection += rate * delta
	else:
		detection -= 0.55 * delta
	detection = clampf(detection, 0.0, 1.0)
	if hud != null:
		hud.set_detection(detection)
	if detection >= 1.0:
		_spotted()

func _spotted() -> void:
	if _spot_lock > 0.0:
		return
	detection = 0.0
	_spot_lock = 1.6
	if hud != null:
		hud.set_detection(0.0)
		hud.flash_msg("SPOTTED - get back to cover")
	if player != null:
		player.shake(0.3)
		player.teleport(spawn_pos, spawn_yaw)
	_flash_alarm()
	on_spotted()

func on_spotted() -> void:
	pass

func _flash_alarm() -> void:
	_alarm_rect.color = Color(1, 0.1, 0.1, 0.45)
	var t := _alarm_rect.create_tween()
	t.tween_property(_alarm_rect, "color:a", 0.0, 0.7)

# ---------------------------------------------------------------- overlays

func open_dossier() -> void:
	if _finished:
		return
	get_tree().paused = true
	player.control_enabled = false
	dossier.open(level_num)

func open_chat(npc: Node) -> void:
	if _finished:
		return
	get_tree().paused = true
	player.control_enabled = false
	if npc.has_method("begin_talk"):
		npc.call("begin_talk", player.global_position)
	chat.open(npc)

func _on_overlay_closed() -> void:
	get_tree().paused = false
	if player != null:
		player.control_enabled = true

func _on_deduction_solved(level: int) -> void:
	if hud != null:
		hud.show_toast("Deduction made - the way forward is open.")
	if _exit_node != null:
		_pulse_exit()
	level_deduced(level)

func level_deduced(_level: int) -> void:
	pass

# ---------------------------------------------------------------- world helpers

func place_building(path: String, pos: Vector3, yaw_deg := 0.0, scale := 1.0, outline := false) -> Node3D:
	var m := WorldKit.instance_glb(path)
	if m == null:
		return null
	m.scale = Vector3.ONE * scale
	m.rotation_degrees.y = yaw_deg
	add_child(m)
	m.position = pos
	WorldKit.add_static_box(m, WorldKit.L_WORLD)
	if outline:
		WorldKit.apply_outline(m, 0.02)
	return m

func ground(size: Vector2, color: Color, center := Vector3.ZERO, tex_path := "") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = WorldKit.L_WORLD
	body.collision_mask = 0
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	mi.mesh = plane
	var m := WorldKit.mat(color, 0.9, 0.0)
	if tex_path != "" and ResourceLoader.exists(tex_path):
		var tex := load(tex_path)
		if tex is Texture2D:
			m.albedo_texture = tex
			m.uv1_scale = Vector3(size.x / 4.0, size.y / 4.0, 1.0)
	mi.material_override = m
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 0.4, size.y)
	col.shape = box
	col.position.y = -0.2
	body.add_child(col)
	add_child(body)
	body.position = center
	return body

func wall(from: Vector3, to: Vector3, height: float, color: Color, thick := 0.4) -> void:
	var mid := (from + to) * 0.5
	var dist := maxf(0.4, from.distance_to(to))
	var body := StaticBody3D.new()
	body.collision_layer = WorldKit.L_WORLD
	body.collision_mask = 0
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(thick, height, dist)
	mi.mesh = bm
	mi.material_override = WorldKit.mat(color, 0.85, 0.0)
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(thick, height, dist)
	col.shape = box
	body.add_child(col)
	add_child(body)
	body.global_position = mid + Vector3.UP * height * 0.5
	body.look_at(Vector3(to.x, body.global_position.y, to.z), Vector3.UP)

func add_light(pos: Vector3, color: Color, energy := 2.0, rng := 8.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = false
	add_child(l)
	l.position = pos
	return l

func spawn_guard(model_path: String, pos: Vector3, opts: Dictionary = {}) -> Guard:
	var g := Guard.new()
	g.add_to_group("guard")
	add_child(g)
	g.position = pos
	g.setup(model_path, opts)
	return g

func spawn_camera(pos: Vector3, face_yaw: float, opts: Dictionary = {}) -> Guard:
	var o := opts.duplicate()
	o["camera"] = true
	o["face_yaw"] = face_yaw
	o["range"] = float(opts.get("range", 8.5))
	o["fov"] = float(opts.get("fov", 26.0))
	o["scan_arc"] = float(opts.get("scan_arc", 38.0))
	o["scan_speed"] = float(opts.get("scan_speed", 0.6))
	var g := Guard.new()
	g.scan_speed = float(o["scan_speed"])
	g.add_to_group("guard")
	add_child(g)
	g.position = pos
	g.setup("", o)
	return g

func spawn_clue(id: String, pos: Vector3) -> ClueNode:
	if Game.has_clue(id):
		return null
	var c := ClueNode.new()
	add_child(c)
	c.position = pos
	c.setup(id)
	return c

func spawn_talker(model_path: String, pos: Vector3, opts: Dictionary = {}) -> TalkNPC:
	var t := TalkNPC.new()
	add_child(t)
	t.position = pos
	t.setup(model_path, opts)
	return t

func place_player(pos: Vector3, yaw := 0.0) -> void:
	spawn_pos = pos
	spawn_yaw = yaw
	if player != null:
		player.teleport(pos, yaw)

const FACADE_SHADER := "res://shaders/facade.gdshader"

## A code-built lit Haussmann building block (facade shader + slate mansard + collider).
func haussmann_block(pos: Vector3, size: Vector3, yaw_deg := 0.0, seed := 1.0, wall := Color(0.80, 0.76, 0.68)) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = WorldKit.L_WORLD
	body.collision_mask = 0
	var facade := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	facade.mesh = bm
	facade.position.y = size.y * 0.5
	var mat := ShaderMaterial.new()
	mat.shader = load(FACADE_SHADER)
	mat.set_shader_parameter("seed", seed)
	mat.set_shader_parameter("wall", wall)
	mat.set_shader_parameter("lit_ratio", 0.4)
	facade.material_override = mat
	body.add_child(facade)
	var roof := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(size.x * 1.02, size.y * 0.14, size.z * 1.02)
	roof.mesh = rb
	roof.position.y = size.y + size.y * 0.07
	roof.material_override = WorldKit.mat(Color(0.15, 0.16, 0.19), 0.7)
	body.add_child(roof)
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(size.x, size.y * 1.14, size.z)
	col.shape = cs
	col.position.y = size.y * 0.57
	body.add_child(col)
	add_child(body)
	body.position = pos
	body.rotation_degrees.y = yaw_deg
	return body

## A small prop from a glb. collide=true adds a mesh-derived collider; tint optional.
func prop(path: String, pos: Vector3, yaw_deg := 0.0, scale := 1.0, collide := false, tint: Variant = null) -> Node3D:
	var m := WorldKit.instance_glb(path)
	if m == null:
		return null
	m.scale = Vector3.ONE * scale
	m.rotation_degrees.y = yaw_deg
	add_child(m)
	m.position = pos
	if tint is Color:
		WorldKit.recolor(m, tint)
	if collide:
		WorldKit.add_static_box(m, WorldKit.L_WORLD, Vector3(0.9, 1.0, 0.9))
	return m

## Scatter a prop's mesh many times via one MultiMesh (cheap crowd/dressing).
func scatter_prop(path: String, count: int, center: Vector3, r_min: float, r_max: float, y := 0.0, seed_v := 7) -> void:
	var src := WorldKit.instance_glb(path)
	if src == null:
		return
	var mesh := WorldKit.first_mesh(src)
	src.free()
	if mesh == null:
		return
	var mmi := WorldKit.scatter(mesh, count, center, r_min, r_max, y, seed_v)
	add_child(mmi)

func place_tower(pos: Vector3, scale := 0.5, yaw := 0.0) -> Node3D:
	var t := WorldKit.instance_glb("res://models/eiffel_tower.glb")
	if t == null:
		return null
	t.scale = Vector3.ONE * scale
	t.rotation_degrees.y = yaw
	add_child(t)
	t.position = pos
	return t

func make_exit(pos: Vector3, requires_deduction := true, label := "EXIT") -> Node3D:
	_exit_requires_deduction = requires_deduction
	var node := Node3D.new()
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.7
	torus.outer_radius = 1.0
	ring.mesh = torus
	ring.material_override = WorldKit.mat(Color(0.3, 1.0, 0.5), 0.2, 0.0, 4.0)
	ring.rotation_degrees.x = 90.0
	ring.position.y = 1.0
	node.add_child(ring)
	var beam := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 7.0
	beam.mesh = cyl
	beam.position.y = 3.5
	var bm := WorldKit.mat(Color(0.3, 1.0, 0.5), 0.1, 0.0, 1.5)
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.albedo_color = Color(0.3, 1.0, 0.5, 0.14)
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam.material_override = bm
	node.add_child(beam)
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = WorldKit.L_PLAYER
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.2
	shape.height = 3.0
	col.shape = shape
	col.position.y = 1.5
	area.add_child(col)
	node.add_child(area)
	add_child(node)
	node.position = pos
	area.body_entered.connect(_on_exit_entered)
	_exit_node = node
	var spin := ring.create_tween().set_loops()
	spin.tween_property(ring, "rotation:y", TAU, 4.0).as_relative()
	return node

func _pulse_exit() -> void:
	if _exit_node == null:
		return
	var t := _exit_node.create_tween()
	t.tween_property(_exit_node, "scale", Vector3.ONE * 1.25, 0.25)
	t.tween_property(_exit_node, "scale", Vector3.ONE, 0.25)

func _on_exit_entered(body: Node3D) -> void:
	if _finished or not (body is Player):
		return
	if _exit_requires_deduction and not Game.deduction_solved(level_num):
		if hud != null:
			hud.flash_msg("Crack the case first - open CASE")
		return
	complete_level()

func complete_level() -> void:
	if _finished:
		return
	_finished = true
	if level_num < 5:
		Game.unlock_level(level_num + 1)
	if hud != null:
		hud.flash_msg("DISTRICT CLEARED")
	get_tree().paused = false
	if player != null:
		player.control_enabled = false
	var tm := get_tree().create_timer(1.4)
	tm.timeout.connect(func() -> void:
		if main != null and main.has_method("on_level_cleared"):
			main.call("on_level_cleared", level_num))

func finish_finale(result: Dictionary) -> void:
	if _finished:
		return
	_finished = true
	get_tree().paused = false
	if player != null:
		player.control_enabled = false
	if main != null and main.has_method("on_finale"):
		main.call("on_finale", result)

func _show_title() -> void:
	var info: Dictionary = Game.LEVELS.get(level_num, {})
	if hud != null:
		hud.set_objective(str(info.get("name", "")) + "\n" + str(info.get("tagline", "")))
	var layer := CanvasLayer.new()
	layer.layer = 25
	add_child(layer)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var t1 := Label.new()
	t1.text = str(info.get("name", "")).to_upper()
	t1.add_theme_font_size_override("font_size", 34)
	t1.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	t1.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	t1.add_theme_constant_override("outline_size", 6)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t1.custom_minimum_size = Vector2(340, 0)
	box.add_child(t1)
	var t2 := Label.new()
	t2.text = str(info.get("tagline", ""))
	t2.add_theme_font_size_override("font_size", 18)
	t2.add_theme_color_override("font_color", Color(0.9, 0.92, 1))
	t2.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	t2.add_theme_constant_override("outline_size", 4)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t2.custom_minimum_size = Vector2(340, 0)
	box.add_child(t2)
	center.add_child(box)
	box.modulate.a = 0.0
	var t := box.create_tween()
	t.tween_property(box, "modulate:a", 1.0, 0.5)
	t.tween_interval(2.0)
	t.tween_property(box, "modulate:a", 0.0, 0.8)
	t.tween_callback(layer.queue_free)

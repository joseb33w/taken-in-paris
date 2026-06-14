class_name WorldKit
extends RefCounted
## Shared world-building helpers: instance models, derive colliders from the SCALED mesh
## AABB (never a constant), MultiMesh scatter, materials, and the ink-outline next_pass.

const OUTLINE_SHADER := "res://shaders/outline.gdshader"

# Collision layer convention (one across the whole game):
# 1 = world/props, 2 = player, 3 = guards, 4 = clues/triggers, 5 = takedown sense
const L_WORLD := 1
const L_PLAYER := 2
const L_GUARD := 3
const L_TRIGGER := 4

static func mat(color: Color, rough := 0.8, metal := 0.0, emit_energy := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if emit_energy > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emit_energy
	return m

static func merged_aabb(n: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for m: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		if m.mesh == null:
			continue
		var a := m.get_aabb()
		a = m.transform * a
		if first:
			out = a
			first = false
		else:
			out = out.merge(a)
	return out

## Snug static collider from the model's own (scaled) mesh bounds, rotated with it.
static func add_static_box(model: Node3D, layer := L_WORLD, shrink := Vector3(0.85, 1.0, 0.85)) -> StaticBody3D:
	var aabb := merged_aabb(model)
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var s := model.scale
	box.size = Vector3(maxf(0.2, aabb.size.x * s.x * shrink.x), maxf(0.2, aabb.size.y * s.y * shrink.y), maxf(0.2, aabb.size.z * s.z * shrink.z))
	col.shape = box
	col.position = aabb.get_center() * s
	body.add_child(col)
	body.rotation = model.rotation
	model.add_child(body)
	return body

static func instance_glb(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var res := load(path)
	if res is PackedScene:
		return (res as PackedScene).instantiate() as Node3D
	return null

static func apply_outline(root: Node3D, width := 0.018, color := Color(0.02, 0.02, 0.03)) -> void:
	var sh := load(OUTLINE_SHADER) as Shader
	if sh == null:
		return
	for m: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if m.mesh == null:
			continue
		var count := maxi(1, m.mesh.get_surface_count())
		for s in range(count):
			var base: Material = m.get_active_material(s)
			var mat_dup: Material = base.duplicate() if base != null else StandardMaterial3D.new()
			var outline := ShaderMaterial.new()
			outline.shader = sh
			outline.set_shader_parameter("outline", width)
			outline.set_shader_parameter("col", color)
			mat_dup.next_pass = outline
			m.set_surface_override_material(s, mat_dup)

static func recolor(root: Node3D, tint: Color) -> void:
	for m: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if m.mesh == null:
			continue
		for s in range(maxi(1, m.mesh.get_surface_count())):
			var base: Material = m.get_active_material(s)
			var sm := (base.duplicate() if base != null else StandardMaterial3D.new()) as StandardMaterial3D
			if sm == null:
				continue
			sm.albedo_color = tint
			m.set_surface_override_material(s, sm)

## One-draw-call scatter of a mesh around an area. Returns the node to add to the tree.
static func scatter(mesh: Mesh, count: int, center: Vector3, r_min: float, r_max: float, y := 0.0, seed_v := 1234) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in count:
		var a := rng.randf() * TAU
		var rad := rng.randf_range(r_min, r_max)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.85, 1.25))
		var pos := center + Vector3(cos(a) * rad, y, sin(a) * rad)
		mm.set_instance_transform(i, Transform3D(basis, pos))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	return mmi

static func first_mesh(root: Node3D) -> Mesh:
	for m: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if m.mesh != null:
			return m.mesh
	return null

## One-shot particle burst at a world point (juice for collect / takedown).
static func spawn_burst(host: Node, world_pos: Vector3, color: Color, amount := 20) -> void:
	if host == null or not host.is_inside_tree():
		return
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.55
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 75.0
	p.initial_velocity_min = 1.8
	p.initial_velocity_max = 4.2
	p.gravity = Vector3(0.0, -5.0, 0.0)
	p.scale_amount_min = 0.05
	p.scale_amount_max = 0.13
	var sm := SphereMesh.new()
	sm.radius = 0.06
	sm.height = 0.12
	sm.radial_segments = 6
	sm.rings = 4
	p.mesh = sm
	p.material_override = mat(color, 0.4, 0.0, 3.0)
	host.add_child(p)
	p.global_position = world_pos
	p.emitting = true
	var tm := host.get_tree().create_timer(1.4)
	tm.timeout.connect(p.queue_free)

## Briefly flash a model's materials toward white (hit-flash juice). Safe on any model.
static func hit_flash(root: Node3D, color := Color(1, 1, 1), dur := 0.12) -> void:
	for m: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if m.mesh == null:
			continue
		for s in range(maxi(1, m.mesh.get_surface_count())):
			var base: Material = m.get_active_material(s)
			var sm := (base.duplicate() if base != null else StandardMaterial3D.new()) as StandardMaterial3D
			if sm == null:
				continue
			sm.emission_enabled = true
			var orig_e := sm.emission_energy_multiplier
			sm.emission = color
			sm.emission_energy_multiplier = 4.0
			m.set_surface_override_material(s, sm)
			var t := m.create_tween()
			t.tween_interval(dur)
			t.tween_property(sm, "emission_energy_multiplier", orig_e, 0.18)

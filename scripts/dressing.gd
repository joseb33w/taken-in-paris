class_name Dressing
extends RefCounted
## Paris street-dressing kit. Places the kk_city low-poly set (benches, streetlights,
## hydrants, dumpsters, cars, bushes) plus trees and a few code-built pieces (kiosk, market
## stall, awning, string-lights) at the RIGHT scale, GROUNDED (base on the floor, never
## floating/sunk), with mesh-derived colliders. host is a LevelBase (uses add_child/add_light).

const KC := "res://models/kc_"
const KC_S := 4.5          # kk_city kit is authored ~1/4.5 real scale
const TREE := "res://models/q_tree.glb"
const BIG_TREE := "res://models/q_birch.glb"

# Place a glb grounded so its mesh base sits exactly on pos.y, with optional collider+tint.
static func place(host: Node3D, path: String, pos: Vector3, yaw_deg := 0.0, scale := 1.0, collide := false, tint: Variant = null) -> Node3D:
	var m := WorldKit.instance_glb(path)
	if m == null:
		return null
	m.scale = Vector3.ONE * scale
	m.rotation_degrees.y = yaw_deg
	host.add_child(m)
	var aabb := WorldKit.merged_aabb(m)
	m.position = Vector3(pos.x, pos.y - aabb.position.y * scale, pos.z)
	if tint is Color:
		WorldKit.recolor(m, tint)
	if collide:
		WorldKit.add_static_box(m, WorldKit.L_WORLD)
	return m

# ---------------------------------------------------------------- street furniture

static func street_light(host: Node3D, pos: Vector3, yaw := 0.0, warm := Color(1.0, 0.82, 0.5), energy := 2.6) -> Node3D:
	var m := place(host, KC + "streetlight.glb", pos, yaw, KC_S, false)
	host.add_light(pos + Vector3(0, 3.9, 0), warm, energy, 9.0)
	return m

static func bench(host: Node3D, pos: Vector3, yaw := 0.0, tint: Variant = null) -> Node3D:
	return place(host, KC + "bench.glb", pos, yaw, KC_S, true, tint)

static func hydrant(host: Node3D, pos: Vector3) -> Node3D:
	return place(host, KC + "firehydrant.glb", pos, 0.0, KC_S, false, Color(0.62, 0.16, 0.13))

static func trash(host: Node3D, pos: Vector3, variant := "A") -> Node3D:
	return place(host, KC + "trash_" + variant + ".glb", pos, 0.0, KC_S * 1.1, false)

static func dumpster(host: Node3D, pos: Vector3, yaw := 0.0, tint := Color(0.22, 0.4, 0.32)) -> Node3D:
	return place(host, KC + "dumpster.glb", pos, yaw, KC_S, true, tint)

static func bush(host: Node3D, pos: Vector3, scale := 1.0) -> Node3D:
	return place(host, KC + "bush.glb", pos, randf() * 360.0, KC_S * scale, false)

static func car(host: Node3D, kind: String, pos: Vector3, yaw := 0.0, tint: Variant = null) -> Node3D:
	return place(host, KC + "car_" + kind + ".glb", pos, yaw, KC_S, true, tint)

static func tree(host: Node3D, pos: Vector3, scale := 1.0) -> Node3D:
	return place(host, TREE, pos, randf() * 360.0, scale, true)

static func plane_tree(host: Node3D, pos: Vector3, scale := 0.55) -> Node3D:
	# the tall Paris plane tree (q_birch) scaled down to line a boulevard
	return place(host, BIG_TREE, pos, randf() * 360.0, scale, true, Color(0.34, 0.42, 0.26))

# ---------------------------------------------------------------- code-built pieces

## A Parisian café table set: round bistro table + two chairs (kk_restaurant).
static func cafe_set(host: Node3D, pos: Vector3, yaw := 0.0) -> void:
	var top := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.42; cyl.bottom_radius = 0.42; cyl.height = 0.05
	top.mesh = cyl
	top.material_override = WorldKit.mat(Color(0.1, 0.1, 0.12), 0.5, 0.3)
	top.position = pos + Vector3(0, 0.72, 0)
	host.add_child(top)
	var leg := MeshInstance3D.new()
	var lc := CylinderMesh.new(); lc.top_radius = 0.05; lc.bottom_radius = 0.07; lc.height = 0.72
	leg.mesh = lc
	leg.material_override = WorldKit.mat(Color(0.08, 0.08, 0.1), 0.5, 0.4)
	leg.position = pos + Vector3(0, 0.36, 0)
	host.add_child(leg)
	place(host, "res://models/chair.glb", pos + Vector3(0.6, 0, 0.2).rotated(Vector3.UP, deg_to_rad(yaw)), yaw + 200.0, 0.78, false)
	place(host, "res://models/chair.glb", pos + Vector3(-0.6, 0, -0.2).rotated(Vector3.UP, deg_to_rad(yaw)), yaw + 20.0, 0.78, false)

## A striped café awning anchored to a facade (decorative, no collision).
static func awning(host: Node3D, pos: Vector3, width := 4.0, yaw := 0.0, col := Color(0.7, 0.16, 0.16)) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, 0.12, 1.4)
	mi.mesh = bm
	mi.material_override = WorldKit.mat(col, 0.8)
	mi.position = pos
	mi.rotation_degrees = Vector3(-14.0, yaw, 0.0)
	host.add_child(mi)
	# scalloped front lip
	var lip := MeshInstance3D.new()
	var lb := BoxMesh.new(); lb.size = Vector3(width, 0.28, 0.06)
	lip.mesh = lb
	lip.material_override = WorldKit.mat(col.lerp(Color(1, 1, 1), 0.15), 0.8)
	lip.position = pos + Vector3(0, -0.18, 0.7).rotated(Vector3.UP, deg_to_rad(yaw))
	lip.rotation_degrees.y = yaw
	host.add_child(lip)

## A Parisian newsstand / kiosk (code-built, collidable) with a little sign.
static func kiosk(host: Node3D, pos: Vector3, yaw := 0.0) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = WorldKit.L_WORLD
	body.collision_mask = 0
	var hut := MeshInstance3D.new()
	var hb := BoxMesh.new(); hb.size = Vector3(2.2, 2.4, 1.6)
	hut.mesh = hb
	hut.material_override = WorldKit.mat(Color(0.12, 0.22, 0.18), 0.7, 0.1)
	hut.position.y = 1.2
	body.add_child(hut)
	var roof := MeshInstance3D.new()
	var rb := BoxMesh.new(); rb.size = Vector3(2.5, 0.6, 1.9)
	roof.mesh = rb
	roof.material_override = WorldKit.mat(Color(0.08, 0.14, 0.12), 0.6)
	roof.position.y = 2.6
	body.add_child(roof)
	var sign := MeshInstance3D.new()
	var sb := BoxMesh.new(); sb.size = Vector3(1.4, 0.5, 0.08)
	sign.mesh = sb
	sign.material_override = WorldKit.mat(Color(0.95, 0.8, 0.2), 0.4, 0.0, 1.6)
	sign.position = Vector3(0, 2.0, 0.85)
	body.add_child(sign)
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new(); cs.size = Vector3(2.2, 2.8, 1.6)
	col.shape = cs; col.position.y = 1.4
	body.add_child(col)
	host.add_child(body)
	body.position = pos
	body.rotation_degrees.y = yaw

## A market stall: four posts, a striped canopy, a goods table.
static func market_stall(host: Node3D, pos: Vector3, yaw := 0.0, col := Color(0.8, 0.3, 0.25)) -> void:
	var root := Node3D.new()
	host.add_child(root)
	root.position = pos
	root.rotation_degrees.y = yaw
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var post := MeshInstance3D.new()
			var pc := CylinderMesh.new(); pc.top_radius = 0.05; pc.bottom_radius = 0.05; pc.height = 2.2
			post.mesh = pc
			post.material_override = WorldKit.mat(Color(0.3, 0.22, 0.16), 0.8)
			post.position = Vector3(sx * 1.1, 1.1, sz * 0.7)
			root.add_child(post)
	var canopy := MeshInstance3D.new()
	var cb := BoxMesh.new(); cb.size = Vector3(2.6, 0.12, 1.8)
	canopy.mesh = cb
	canopy.material_override = WorldKit.mat(col, 0.8)
	canopy.position.y = 2.2
	root.add_child(canopy)
	var table := StaticBody3D.new()
	table.collision_layer = WorldKit.L_WORLD; table.collision_mask = 0
	var tm := MeshInstance3D.new()
	var tb := BoxMesh.new(); tb.size = Vector3(2.4, 0.1, 1.0)
	tm.mesh = tb
	tm.material_override = WorldKit.mat(Color(0.4, 0.3, 0.22), 0.8)
	tm.position.y = 0.9
	table.add_child(tm)
	var tc := CollisionShape3D.new()
	var tcs := BoxShape3D.new(); tcs.size = Vector3(2.4, 0.9, 1.0)
	tc.shape = tcs; tc.position.y = 0.45
	table.add_child(tc)
	root.add_child(table)
	# a few crates of goods on top (reuse the crate model)
	place(root, "res://models/crate.glb", Vector3(-0.6, 0.95, 0), 10.0, 0.6, false, col.lerp(Color(1, 1, 1), 0.2))
	place(root, "res://models/crate.glb", Vector3(0.6, 0.95, 0), -20.0, 0.6, false)

## A warm string of bistro lights between two points (atmosphere, no collision).
static func string_lights(host: Node3D, from: Vector3, to: Vector3, count := 9, col := Color(1.0, 0.8, 0.45)) -> void:
	for i in range(count + 1):
		var f := float(i) / float(count)
		var p := from.lerp(to, f)
		# gentle catenary sag
		p.y -= sin(f * PI) * 0.6
		var bulb := MeshInstance3D.new()
		var sm := SphereMesh.new(); sm.radius = 0.07; sm.height = 0.14
		bulb.mesh = sm
		bulb.material_override = WorldKit.mat(col, 0.2, 0.0, 4.0)
		bulb.position = p
		host.add_child(bulb)

class_name VisionCone
extends Node3D
## A flashlight-style ground sector that shows a guard/camera field of view and tests
## line-of-sight. Forward is local +Z (orient with rotation.y = atan2(dir.x, dir.z)).

var sight_range := 9.0
var fov_half := 33.0
var eye_height := 1.45

var _mat: StandardMaterial3D
var _mi: MeshInstance3D
var _built := false

func build(p_range: float, p_fov_half: float, base_color := Color(1.0, 0.82, 0.2)) -> void:
	sight_range = p_range
	fov_half = p_fov_half
	var mesh := _sector(sight_range, fov_half)
	_mi = MeshInstance3D.new()
	_mi.mesh = mesh
	_mi.position.y = 0.07
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.albedo_color = Color(base_color.r, base_color.g, base_color.b, 0.16)
	_mat.emission_enabled = true
	_mat.emission = base_color
	_mat.emission_energy_multiplier = 1.1
	_mat.disable_receive_shadows = true
	_mi.material_override = _mat
	add_child(_mi)
	_built = true

func set_alert(t: float) -> void:
	if not _built:
		return
	var col := Color(1.0, 0.82, 0.2).lerp(Color(1.0, 0.16, 0.1), clampf(t, 0.0, 1.0))
	_mat.albedo_color = Color(col.r, col.g, col.b, 0.16 + 0.2 * clampf(t, 0.0, 1.0))
	_mat.emission = col

func set_visible_cone(v: bool) -> void:
	if _built:
		_mi.visible = v

func can_see(point: Vector3) -> bool:
	var origin := global_position
	var fwd := global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.001:
		return false
	fwd = fwd.normalized()
	var to := point - origin
	var dist := to.length()
	if dist > sight_range or dist < 0.05:
		return dist < 0.05
	var flat := Vector3(to.x, 0.0, to.z)
	if flat.length() < 0.001:
		return true
	flat = flat.normalized()
	var ang := rad_to_deg(acos(clampf(fwd.dot(flat), -1.0, 1.0)))
	if ang > fov_half:
		return false
	# line of sight against world geometry (layer 1)
	var world := get_world_3d()
	if world == null:
		return true
	var space := world.direct_space_state
	var from := origin + Vector3.UP * eye_height
	var target := point + Vector3.UP * 0.6
	var q := PhysicsRayQueryParameters3D.create(from, target, 1)
	q.collide_with_areas = false
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return true
	var hd: float = (hit["position"] - from).length()
	var td := (target - from).length()
	return hd >= td - 0.6

func _sector(radius: float, half_deg: float, segments := 18) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := deg_to_rad(half_deg)
	for i in range(segments):
		var a0 := -half + (2.0 * half) * float(i) / float(segments)
		var a1 := -half + (2.0 * half) * float(i + 1) / float(segments)
		var p0 := Vector3(sin(a0) * radius, 0.0, cos(a0) * radius)
		var p1 := Vector3(sin(a1) * radius, 0.0, cos(a1) * radius)
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3.ZERO)
		st.set_normal(Vector3.UP)
		st.add_vertex(p0)
		st.set_normal(Vector3.UP)
		st.add_vertex(p1)
	return st.commit()

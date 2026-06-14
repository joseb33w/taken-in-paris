class_name ClueNode
extends Node3D
## A glowing evidence beacon. Hold-interact (handled by the player) to collect; emits a
## beam so it is discoverable across the level. Colour keyed to the clue kind.

var clue_id := ""
var collected := false
var _core: MeshInstance3D
var _col := Color(0.3, 0.85, 1.0)

func setup(id: String) -> void:
	clue_id = id
	add_to_group("interactable")
	add_to_group("clue")
	var def := Game.clue_def(id)
	var kind := str(def.get("kind", "physical"))
	var col := Color(0.3, 0.85, 1.0)
	if kind == "testimony":
		col = Color(0.4, 1.0, 0.55)
	elif kind == "cipher":
		col = Color(1.0, 0.82, 0.25)
	_col = col

	_core = MeshInstance3D.new()
	var oct := SphereMesh.new()
	oct.radius = 0.22
	oct.height = 0.5
	oct.radial_segments = 5
	oct.rings = 3
	_core.mesh = oct
	_core.material_override = WorldKit.mat(col, 0.2, 0.0, 4.0)
	_core.position.y = 1.0
	add_child(_core)

	var beam := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.1
	cyl.height = 6.0
	beam.mesh = cyl
	beam.position.y = 3.0
	var bm := WorldKit.mat(col, 0.1, 0.0, 2.0)
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.albedo_color = Color(col.r, col.g, col.b, 0.18)
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam.material_override = bm
	add_child(beam)

	var t := _core.create_tween().set_loops()
	t.tween_property(_core, "position:y", 1.25, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_core, "position:y", 0.95, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var spin := _core.create_tween().set_loops()
	spin.tween_property(_core, "rotation:y", TAU, 3.0).as_relative()

func interact_kind() -> String:
	return "clue"

func prompt_text() -> String:
	return "Collect evidence"

func can_interact() -> bool:
	return not collected

func collect() -> bool:
	if collected:
		return false
	collected = true
	remove_from_group("interactable")
	Game.add_clue(clue_id)
	WorldKit.spawn_burst(get_parent(), global_position + Vector3.UP, _col, 24)
	var t := create_tween()
	t.tween_property(self, "scale", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)
	return true

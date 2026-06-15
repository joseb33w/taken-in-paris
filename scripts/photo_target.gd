class_name PhotoTarget
extends Node3D
## Something worth a photo for the case file (a plate, a face at a window, a chalk mark).
## Tap to photograph: a shutter, a flash, and the shot is logged as a lead. Persists.

var photo_id := ""
var label := "Photograph this"
var reward_clue := ""
var reward_lead := ""
var shot := false
var _ring: MeshInstance3D

func setup(id: String, opts: Dictionary = {}) -> void:
	photo_id = id
	label = str(opts.get("label", "Photograph this"))
	reward_clue = str(opts.get("clue_id", ""))
	reward_lead = str(opts.get("lead", id))
	shot = Game.has_flag("photo_" + id)
	add_to_group("interactable")
	add_to_group("photo")
	# a thin framing reticle so the player knows it's a photo op
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.34
	tm.outer_radius = 0.4
	_ring.mesh = tm
	var col := Color(0.4, 0.85, 1.0) if not shot else Color(0.5, 0.55, 0.6)
	var m := WorldKit.mat(col, 0.2, 0.0, 3.0)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring.material_override = m
	_ring.position.y = 1.4
	add_child(_ring)
	var t := _ring.create_tween().set_loops()
	t.tween_property(_ring, "rotation:z", TAU, 5.0).as_relative()

func interact_kind() -> String:
	return "photo"

func prompt_text() -> String:
	return "Photographed" if shot else label

func can_interact() -> bool:
	return not shot

func on_photographed() -> void:
	if shot:
		return
	shot = true
	Game.set_flag("photo_" + photo_id, true)
	if _ring != null:
		var m := WorldKit.mat(Color(0.5, 0.55, 0.6), 0.2, 0.0, 1.5)
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_ring.material_override = m
	if reward_clue != "":
		Game.add_clue(reward_clue)
	if reward_lead != "":
		Game.add_lead(reward_lead)
	Game.toast.emit("Shot logged to the case file.")

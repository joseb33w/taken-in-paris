class_name LockNode
extends Node3D
## A locked strongbox / cellar hatch you can pick (the lock-pick minigame). On success it
## yields its reward - a clue card, a lead, or just bragging rights - and stays unlocked
## across devices via a flag. Tap to attempt.

var lock_id := ""
var pins := 3
var reward_clue := ""
var reward_lead := ""
var label := "Pick the lock"
var picked := false
var _box: MeshInstance3D
var _keyhole: MeshInstance3D

func setup(id: String, opts: Dictionary = {}) -> void:
	lock_id = id
	pins = int(opts.get("pins", 3))
	reward_clue = str(opts.get("clue_id", ""))
	reward_lead = str(opts.get("lead", ""))
	label = str(opts.get("label", "Pick the lock"))
	picked = Game.has_flag("lock_" + id)
	add_to_group("interactable")
	add_to_group("lock")

	_box = MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(0.7, 0.5, 0.5)
	_box.mesh = bm
	_box.material_override = WorldKit.mat(Color(0.32, 0.24, 0.16), 0.6, 0.3)
	_box.position.y = 0.45
	add_child(_box)
	var band := MeshInstance3D.new()
	var bb := BoxMesh.new(); bb.size = Vector3(0.74, 0.12, 0.54)
	band.mesh = bb
	band.material_override = WorldKit.mat(Color(0.18, 0.16, 0.14), 0.4, 0.7)
	band.position.y = 0.45
	add_child(band)
	_keyhole = MeshInstance3D.new()
	var km := SphereMesh.new(); km.radius = 0.05; km.height = 0.1
	_keyhole.mesh = km
	_keyhole.material_override = WorldKit.mat(Color(1.0, 0.85, 0.3) if not picked else Color(0.4, 0.9, 0.5), 0.3, 0.0, 3.0)
	_keyhole.position = Vector3(0, 0.45, 0.26)
	add_child(_keyhole)
	WorldKit.add_static_box(self, WorldKit.L_WORLD)

func interact_kind() -> String:
	return "lock"

func prompt_text() -> String:
	return "Open the box (it's unlocked)" if picked else label

func can_interact() -> bool:
	return not picked

func on_picked() -> void:
	if picked:
		return
	picked = true
	Game.set_flag("lock_" + lock_id, true)
	Audio.sfx("sfx_door")
	if _keyhole != null:
		_keyhole.material_override = WorldKit.mat(Color(0.4, 0.9, 0.5), 0.3, 0.0, 3.0)
	if _box != null:
		var t := _box.create_tween()
		t.tween_property(_box, "rotation:x", deg_to_rad(-35.0), 0.4).set_trans(Tween.TRANS_BACK)
	if reward_clue != "":
		Game.add_clue(reward_clue)
	if reward_lead != "":
		Game.add_lead(reward_lead)
		Game.toast.emit("Lead found")
	WorldKit.spawn_burst(get_parent(), global_position + Vector3.UP, Color(1.0, 0.85, 0.4), 18)

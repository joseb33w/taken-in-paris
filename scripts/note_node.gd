class_name NoteNode
extends Node3D
## A hidden clue note tucked into the world (a chalk scrawl, a torn napkin, a pinned flyer).
## Tap to read; the first read logs the lead to your dossier flags and Etienne reads it aloud.
## Off the critical path - pure optional investigation that persists across devices.

var note_id := ""
var title := "Note"
var body := ""
var found := false
var _card: MeshInstance3D

func setup(id: String, p_title: String, p_body: String) -> void:
	note_id = id
	title = p_title
	body = p_body
	found = Game.has_flag("note_" + id)
	add_to_group("interactable")
	add_to_group("note")

	_card = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.34, 0.44, 0.02)
	_card.mesh = bm
	var col := Color(0.5, 1.0, 0.55) if not found else Color(0.5, 0.55, 0.6)
	_card.material_override = WorldKit.mat(Color(0.92, 0.88, 0.78), 0.6, 0.0, 0.0)
	_card.position.y = 1.1
	_card.rotation_degrees = Vector3(6.0, 18.0, -4.0)
	add_child(_card)
	# a soft glow halo so it's discoverable but subtle (no beam - it's "hidden")
	var halo := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.16; sm.height = 0.32
	halo.mesh = sm
	var hm := WorldKit.mat(col, 0.2, 0.0, 3.0)
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.albedo_color = Color(col.r, col.g, col.b, 0.22)
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo.mesh = sm
	halo.material_override = hm
	halo.position.y = 1.1
	add_child(halo)
	var t := _card.create_tween().set_loops()
	t.tween_property(_card, "position:y", 1.2, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_card, "position:y", 1.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func interact_kind() -> String:
	return "note"

func prompt_text() -> String:
	return "Read the note"

func can_interact() -> bool:
	return true

func mark_found() -> void:
	if found:
		return
	found = true
	Game.set_flag("note_" + note_id, true)
	Game.add_lead(note_id)
	if _card != null:
		WorldKit.hit_flash(_card, Color(0.6, 1.0, 0.7), 0.15)

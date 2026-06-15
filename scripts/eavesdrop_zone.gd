class_name EavesdropZone
extends Area3D
## Step into the zone (quietly) to overhear a scripted exchange between two Parisians -
## voiced + subtitled. Reveals a lead the first time, then persists. Sneaking isn't required
## but the lines hint that you should. Fires once.

var zone_id := ""
var lines: Array = []      # [{speaker, profile, text}, ...]
var lead := ""
var fired := false
var _running := false

func setup(id: String, p_lines: Array, p_lead := "", radius := 3.2) -> void:
	zone_id = id
	lines = p_lines
	lead = p_lead
	fired = Game.has_flag("eaves_" + id)
	collision_layer = 0
	collision_mask = WorldKit.L_PLAYER
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = radius
	cs.height = 4.0
	col.shape = cs
	col.position.y = 1.0
	add_child(col)
	body_entered.connect(_on_enter)

func _on_enter(body: Node3D) -> void:
	if fired or _running or not (body is Player):
		return
	_running = true
	await _play()
	_running = false

func _play() -> void:
	Voice.say("(You hold back in the shadows and listen...)", "narrator", "")
	await get_tree().create_timer(2.0).timeout
	for entry in lines:
		if not (entry is Dictionary):
			continue
		var d: Dictionary = entry
		Voice.say(str(d.get("text", "")), str(d.get("profile", "narrator")), str(d.get("speaker", "")))
		var t := str(d.get("text", ""))
		await get_tree().create_timer(clampf(2.2 + float(t.length()) * 0.05, 2.5, 7.0)).timeout
	fired = true
	Game.set_flag("eaves_" + zone_id, true)
	if lead != "":
		Game.add_lead(lead)
	Game.toast.emit("You overheard something useful.")

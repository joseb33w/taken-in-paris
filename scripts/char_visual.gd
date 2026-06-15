class_name Locomotion
extends RefCounted
## Robustly drives idle / walk / run on ANY rigged glb (Meshy or library) by mapping a
## logical state to the best-matching clip name, case-insensitive. Falls back to a
## procedural bob flag when the model carries no animations, so nobody ever T-poses.

var anim: AnimationPlayer
var clip_map: Dictionary = {}
var current := ""
var has_anim := false

func setup(root: Node) -> void:
	anim = _find_anim(root)
	has_anim = anim != null and anim.get_animation_list().size() > 0
	if has_anim:
		_build_map()

func _find_anim(n: Node) -> AnimationPlayer:
	for c: AnimationPlayer in n.find_children("*", "AnimationPlayer", true, false):
		return c
	return null

func _build_map() -> void:
	var list := anim.get_animation_list()
	var first := list[0]
	clip_map["idle"] = _best(list, ["idle", "rest", "stand", "breath"], first)
	clip_map["walk"] = _best(list, ["walk", "walking"], str(clip_map["idle"]))
	clip_map["run"] = _best(list, ["sprint", "running", "run", "jog"], str(clip_map["walk"]))
	clip_map["scared"] = _best(list, ["scared", "fear", "crouch", "cower", "sit"], str(clip_map["idle"]))
	clip_map["talk"] = _best(list, ["talk", "speak", "chat", "gesture", "wave", "point", "yes", "agree"], str(clip_map["idle"]))
	clip_map["gesture"] = _best(list, ["gesture", "wave", "point", "talk", "clap", "nod"], str(clip_map["idle"]))
	clip_map["sit"] = _best(list, ["sit", "seated", "sitting", "chair", "rest", "crouch"], str(clip_map["idle"]))
	clip_map["lean"] = _best(list, ["lean", "idle_lean", "rest", "stand"], str(clip_map["idle"]))

func _best(list: PackedStringArray, keys: Array, fallback: String) -> String:
	for k in keys:
		for a in list:
			if str(k) in a.to_lower():
				return a
	return fallback

func clip_for(state: String) -> String:
	return str(clip_map.get(state, ""))

func has_clip(state: String) -> bool:
	if not has_anim:
		return false
	var clip := clip_for(state)
	return clip != "" and anim.has_animation(clip)

func play(state: String, speed: float = 1.0) -> void:
	if not has_anim:
		return
	var clip := clip_for(state)
	if clip == "" or not anim.has_animation(clip):
		return
	anim.speed_scale = speed
	if clip == current:
		return
	current = clip
	var a := anim.get_animation(clip)
	if a != null and a.loop_mode == Animation.LOOP_NONE:
		a.loop_mode = Animation.LOOP_LINEAR
	anim.play(clip, 0.2)

extends Node
## Soundscape director (autoload "Audio"). One ambience bed per district, two crossfaded
## music layers (explore <-> tension) driven by a 0..1 tension value, a round-robin SFX
## pool for one-shots, and positional 3D loops (the busker's accordion). All streams are
## small synthesized OGGs under res://audio/. Runs during pause so menus/chat keep sound.

const DIR := "res://audio/"
const LOOPING := {
	"amb_street": true, "amb_cafe": true, "amb_gallery": true, "amb_crypt": true,
	"music_explore": true, "music_tension": true, "accordion": true,
	"sfx_alarm": true, "sfx_heli": true,
}

var _streams: Dictionary = {}
var _amb: AudioStreamPlayer
var _amb_b: AudioStreamPlayer        # second ambience player for crossfade
var _mus_explore: AudioStreamPlayer
var _mus_tension: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_i := 0

var _amb_key := ""
var _tension := 0.0
var _tension_target := 0.0
var _music_on := false
var _master_muted := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_bus("Music", -6.0)
	_make_bus("Ambience", -9.0)
	_make_bus("SFX", -3.0)

	_amb = _player("Ambience"); _amb.volume_db = -80.0
	_amb_b = _player("Ambience"); _amb_b.volume_db = -80.0
	_mus_explore = _player("Music"); _mus_explore.volume_db = -80.0
	_mus_tension = _player("Music"); _mus_tension.volume_db = -80.0
	for i in range(8):
		_sfx_pool.append(_player("SFX"))

func _make_bus(name: String, db: float) -> void:
	if AudioServer.get_bus_index(name) != -1:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, name)
	AudioServer.set_bus_send(idx, "Master")
	AudioServer.set_bus_volume_db(idx, db)

func _player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	return p

func _stream(key: String) -> AudioStream:
	if _streams.has(key):
		return _streams[key]
	var path := DIR + key + ".ogg"
	if not ResourceLoader.exists(path):
		return null
	var s := load(path)
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = bool(LOOPING.get(key, false))
	_streams[key] = s
	return s

# ---------------------------------------------------------------- public API

## Switch the ambient bed (crossfades). key in {amb_street,amb_cafe,amb_gallery,amb_crypt}.
func ambience(key: String) -> void:
	if key == _amb_key:
		return
	_amb_key = key
	var s := _stream(key)
	if s == null:
		return
	# swap players so the old bed fades out while the new fades in
	var tmp := _amb
	_amb = _amb_b
	_amb_b = tmp
	_amb.stream = s
	_amb.play()
	var ti := create_tween()
	ti.tween_property(_amb, "volume_db", -10.0, 1.2)
	var to := create_tween()
	to.tween_property(_amb_b, "volume_db", -80.0, 1.2)
	to.tween_callback(_amb_b.stop)

## Start the two music layers (idempotent). Call once per level build.
func start_music() -> void:
	var e := _stream("music_explore")
	var t := _stream("music_tension")
	if e == null or t == null:
		return
	if not _music_on:
		_mus_explore.stream = e
		_mus_tension.stream = t
		_mus_explore.play()
		_mus_tension.play()
		_music_on = true
	_apply_music_mix(true)

## 0 = calm exploration, 1 = full tension. Crossfades the two music layers smoothly.
func set_tension(t: float) -> void:
	_tension_target = clampf(t, 0.0, 1.0)

func _process(delta: float) -> void:
	if absf(_tension - _tension_target) > 0.001:
		_tension = move_toward(_tension, _tension_target, delta * 0.8)
		_apply_music_mix(false)

func _apply_music_mix(_immediate: bool) -> void:
	if not _music_on:
		return
	# equal-power-ish crossfade in dB
	var calm := lerpf(-12.0, -40.0, _tension)
	var tense := lerpf(-40.0, -8.0, _tension)
	_mus_explore.volume_db = calm
	_mus_tension.volume_db = tense

func stop_music() -> void:
	_music_on = false
	_mus_explore.stop()
	_mus_tension.stop()

## Fire a one-shot SFX (round-robin pool). vol_db trims level; pitch jitter optional.
func sfx(name: String, vol_db := 0.0, pitch := 1.0) -> void:
	var s := _stream(name)
	if s == null:
		return
	var p := _sfx_pool[_sfx_i]
	_sfx_i = (_sfx_i + 1) % _sfx_pool.size()
	p.stream = s
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.play()

## Attach a looping positional 3D sound to a node (e.g. the busker's accordion).
func attach_loop_3d(parent: Node3D, key: String, vol_db := -2.0, max_dist := 22.0) -> AudioStreamPlayer3D:
	var s := _stream(key)
	if s == null or parent == null:
		return null
	var p := AudioStreamPlayer3D.new()
	p.stream = s
	p.bus = "Ambience"
	p.volume_db = vol_db
	p.max_distance = max_dist
	p.unit_size = 4.0
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(p)
	p.play()
	return p

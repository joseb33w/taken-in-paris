class_name LockMinigame
extends CanvasLayer
## Lock-pick minigame: a marker sweeps a track; tap PICK (or interact) while it's over the
## moving sweet-spot to set a pin. Set all the pins to open. A miss costs the pin and nudges
## detection. Runs while the world is paused. Drives the marker in _process (no bound tween).
## The track width fits the live viewport so the panel never clips a narrow portrait phone.

signal closed
signal solved(node: Node)

const MARK_W := 14.0

var _lock: Node
var _pins_total := 3
var _pins_done := 0
var _active := false
var _pos := 0.0
var _dir := 1.0
var _speed := 320.0
var _zone_x := 0.0
var _zone_w := 90.0
var _track_w := 440.0

var _vb: VBoxContainer
var _track: Panel
var _marker: ColorRect
var _zone: ColorRect
var _status: Label
var _pin_label: Label

func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()
	get_viewport().size_changed.connect(_fit)

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.12, 0.99)
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.5, 0.55, 0.7, 0.6)
	sb.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	_vb = VBoxContainer.new()
	_vb.add_theme_constant_override("separation", 14)
	_vb.custom_minimum_size = Vector2(_track_w, 0)
	panel.add_child(_vb)
	var head := Label.new()
	head.text = "PICK THE LOCK"
	head.add_theme_font_size_override("font_size", 24)
	head.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vb.add_child(head)
	_pin_label = Label.new()
	_pin_label.add_theme_font_size_override("font_size", 15)
	_pin_label.add_theme_color_override("font_color", Color(0.85, 0.9, 1))
	_pin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vb.add_child(_pin_label)

	_track = Panel.new()
	_track.custom_minimum_size = Vector2(_track_w, 40)
	var ts := StyleBoxFlat.new()
	ts.bg_color = Color(0.04, 0.05, 0.07, 1)
	ts.set_corner_radius_all(6)
	ts.set_border_width_all(1)
	ts.border_color = Color(0.4, 0.45, 0.55, 0.6)
	_track.add_theme_stylebox_override("panel", ts)
	_vb.add_child(_track)
	_zone = ColorRect.new()
	_zone.color = Color(0.3, 0.85, 0.45, 0.55)
	_zone.position = Vector2(0, 4)
	_zone.size = Vector2(_zone_w, 32)
	_track.add_child(_zone)
	_marker = ColorRect.new()
	_marker.color = Color(1.0, 0.9, 0.4)
	_marker.position = Vector2(0, 0)
	_marker.size = Vector2(MARK_W, 40)
	_track.add_child(_marker)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 14)
	_status.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(_track_w, 0)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vb.add_child(_status)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_vb.add_child(row)
	var pick := _btn("PICK", Color(0.2, 0.55, 0.85))
	pick.pressed.connect(_attempt)
	row.add_child(pick)
	var give := _btn("BACK OFF", Color(0.4, 0.34, 0.34))
	give.pressed.connect(close)
	row.add_child(give)

func _fit() -> void:
	_track_w = clampf(get_viewport().get_visible_rect().size.x - 44.0, 240.0, 440.0)
	if _vb != null:
		_vb.custom_minimum_size.x = _track_w
	if _track != null:
		_track.custom_minimum_size.x = _track_w
	if _status != null:
		_status.custom_minimum_size.x = _track_w

func open(lock: Node) -> void:
	_lock = lock
	_pins_total = maxi(1, int(lock.get("pins")))
	_pins_done = 0
	_speed = 300.0
	_pos = 0.0
	_dir = 1.0
	_active = true
	visible = true
	_fit()
	_status.text = "Tap PICK when the marker is in the green."
	_new_zone()
	_update_pins()

func close() -> void:
	_active = false
	visible = false
	closed.emit()

func _new_zone() -> void:
	_zone_w = clampf(110.0 - _pins_done * 12.0, 60.0, 110.0)
	_zone_x = randf_range(0.0, maxf(0.0, _track_w - MARK_W - _zone_w))
	_zone.position = Vector2(_zone_x, 4)
	_zone.size = Vector2(_zone_w, 32)

func _update_pins() -> void:
	_pin_label.text = "Pins set: %d / %d" % [_pins_done, _pins_total]

func _process(delta: float) -> void:
	if not _active:
		return
	_pos += _dir * _speed * delta
	if _pos <= 0.0:
		_pos = 0.0; _dir = 1.0
	elif _pos >= _track_w - MARK_W:
		_pos = _track_w - MARK_W; _dir = -1.0
	_marker.position.x = _pos
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("takedown"):
		_attempt()

func _attempt() -> void:
	if not _active:
		return
	var center := _pos + MARK_W * 0.5
	if center >= _zone_x and center <= _zone_x + _zone_w:
		_pins_done += 1
		Audio.sfx("sfx_pick_tick", -2.0, 1.2)
		_update_pins()
		if _pins_done >= _pins_total:
			_succeed()
		else:
			_speed = minf(_speed + 55.0, 520.0)
			_new_zone()
			_status.text = "Click. Keep going..."
	else:
		Audio.sfx("sfx_pick_fail")
		_status.text = "The pick slips. Steady..."
		_status.modulate = Color(1, 0.5, 0.5)
		var t := _status.create_tween()
		t.tween_property(_status, "modulate", Color(1, 1, 1), 0.5)
		_pins_done = maxi(0, _pins_done - 1)
		_update_pins()

func _succeed() -> void:
	_active = false
	Audio.sfx("sfx_pick_ok")
	_status.text = "The lock gives. Open."
	if _lock != null and _lock.has_method("on_picked"):
		_lock.call("on_picked")
	solved.emit(_lock)
	var tm := get_tree().create_timer(0.9)
	tm.timeout.connect(close)

func _btn(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(140, 46)
	b.add_theme_font_size_override("font_size", 17)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color.r, color.g, color.b, 0.92)
	sb.set_corner_radius_all(9)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", sb)
	return b

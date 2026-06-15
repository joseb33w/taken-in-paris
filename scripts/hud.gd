class_name Hud
extends CanvasLayer
## Gameplay HUD. Root is a pass-through Control so touches reach the player's
## _unhandled_input; the action Buttons are STOP controls that consume their own touch, so
## a press-then-drag on a button can never become a look-drag. Responsive: relaid out from
## the LIVE viewport size + safe-area insets on every resize.

var player: Node

var _root: Control
var _joy_base: Panel
var _joy_knob: Panel
var _detect_bg: Panel
var _detect_fill: ColorRect
var _detect_label: Label
var _clock: Label
var _objective: Label
var _timer: Label
var _prompt: Label
var _hold_bg: Panel
var _hold_fill: ColorRect
var _toast: Label
var _msg: Label
var _flash: ColorRect
var _btn_interact: Button
var _btn_takedown: Button
var _btn_sneak: Button
var _btn_dossier: Button
var _buttons: Array = []
var _insets := {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}

func setup(p: Node) -> void:
	player = p

func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_joy_base = _circle(150.0, Color(1, 1, 1, 0.10), Color(1, 1, 1, 0.22))
	_joy_base.visible = false
	_root.add_child(_joy_base)
	_joy_knob = _circle(64.0, Color(1, 1, 1, 0.22), Color(1, 1, 1, 0.4))
	_joy_knob.visible = false
	_root.add_child(_joy_knob)

	_detect_bg = Panel.new()
	_detect_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style(_detect_bg, Color(0, 0, 0, 0.55), Color(1, 1, 1, 0.15))
	_root.add_child(_detect_bg)
	_detect_fill = ColorRect.new()
	_detect_fill.color = Color(0.3, 0.85, 0.4)
	_detect_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detect_bg.add_child(_detect_fill)
	_detect_label = _label("DETECTION", 13, Color(0.85, 0.9, 0.95))
	_root.add_child(_detect_label)

	_clock = _label("", 22, Color(1, 0.85, 0.3))
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_clock.visible = false
	_root.add_child(_clock)

	_objective = _label("", 16, Color(0.92, 0.95, 1.0))
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(_objective)

	_timer = _label("00:00", 20, Color(0.8, 0.9, 1.0))
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(_timer)

	_prompt = _label("", 18, Color(1, 1, 1))
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_prompt)
	_hold_bg = Panel.new()
	_hold_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style(_hold_bg, Color(0, 0, 0, 0.5), Color(1, 1, 1, 0.2))
	_hold_bg.visible = false
	_root.add_child(_hold_bg)
	_hold_fill = ColorRect.new()
	_hold_fill.color = Color(0.4, 0.85, 1.0)
	_hold_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hold_bg.add_child(_hold_fill)

	_toast = _label("", 16, Color(0.6, 1.0, 0.7))
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	_root.add_child(_toast)

	_msg = _label("", 26, Color(1, 0.4, 0.35))
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.modulate.a = 0.0
	_root.add_child(_msg)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)

	_btn_interact = _make_button("GRAB", Color(0.2, 0.55, 0.8))
	_btn_takedown = _make_button("TAKE", Color(0.7, 0.3, 0.3))
	_btn_sneak = _make_button("SNEAK", Color(0.3, 0.5, 0.4))
	_btn_dossier = _make_button("CASE", Color(0.5, 0.4, 0.6))
	_buttons = [_btn_interact, _btn_takedown, _btn_sneak, _btn_dossier]
	for b: Button in _buttons:
		_root.add_child(b)

	_btn_interact.button_down.connect(func() -> void: if player != null: player.call("set_hud_interact", true))
	_btn_interact.button_up.connect(func() -> void: if player != null: player.call("set_hud_interact", false))
	_btn_takedown.pressed.connect(func() -> void: if player != null: player.call("try_takedown"))
	_btn_sneak.pressed.connect(func() -> void: if player != null: player.call("toggle_sneak"))
	_btn_dossier.pressed.connect(func() -> void: if player != null: player.call("open_dossier_now"))

	Game.toast.connect(show_toast)
	get_viewport().size_changed.connect(_relayout)
	_refresh_insets()
	_relayout()
	await get_tree().process_frame
	await get_tree().process_frame
	_refresh_insets()
	_relayout()

func _relayout() -> void:
	if _root == null:
		return
	var s := get_viewport().get_visible_rect().size
	var top := maxf(10.0, _insets["top"])
	var bot := maxf(12.0, _insets["bottom"])
	var lft := maxf(12.0, _insets["left"])
	var rgt := maxf(12.0, _insets["right"])

	var dw := 220.0
	_detect_bg.position = Vector2(s.x * 0.5 - dw * 0.5, top + 22.0)
	_detect_bg.size = Vector2(dw, 14.0)
	_detect_label.position = Vector2(s.x * 0.5 - dw * 0.5, top + 2.0)
	_detect_label.size = Vector2(dw, 18.0)
	_detect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_clock.position = Vector2(s.x * 0.5 - 120.0, top + 40.0)
	_clock.size = Vector2(240.0, 30.0)

	_objective.position = Vector2(lft, top + 2.0)
	_objective.size = Vector2(minf(s.x * 0.5, 320.0), 70.0)

	_timer.position = Vector2(s.x - rgt - 150.0, top + 2.0)
	_timer.size = Vector2(150.0, 26.0)

	var big := 116.0
	var sm := 86.0
	var bx := s.x - rgt - big - 8.0
	var by := s.y - bot - big - 8.0
	_btn_interact.position = Vector2(bx, by)
	_btn_interact.size = Vector2(big, big)
	_btn_takedown.position = Vector2(bx - sm - 12.0, by + (big - sm))
	_btn_takedown.size = Vector2(sm, sm)
	_btn_sneak.position = Vector2(bx + (big - sm), by - sm - 12.0)
	_btn_sneak.size = Vector2(sm, sm)
	_btn_dossier.position = Vector2(s.x - rgt - sm, top + 64.0)
	_btn_dossier.size = Vector2(sm, sm)

	_prompt.position = Vector2(s.x * 0.5 - 220.0, s.y * 0.60)
	_prompt.size = Vector2(440.0, 30.0)
	_hold_bg.position = Vector2(s.x * 0.5 - 90.0, s.y * 0.60 + 32.0)
	_hold_bg.size = Vector2(180.0, 10.0)
	_hold_fill.position = Vector2.ZERO
	_hold_fill.size = Vector2(0.0, 10.0)

	_toast.position = Vector2(s.x * 0.5 - 260.0, s.y * 0.5 + 120.0)
	_toast.size = Vector2(520.0, 26.0)
	_msg.position = Vector2(s.x * 0.5 - 280.0, s.y * 0.42)
	_msg.size = Vector2(560.0, 40.0)

func _refresh_insets() -> void:
	if not OS.has_feature("web"):
		return
	var js := """(() => { const d=document.createElement('div');
		d.style.cssText='position:fixed;top:env(safe-area-inset-top);bottom:env(safe-area-inset-bottom);left:env(safe-area-inset-left);right:env(safe-area-inset-right)';
		document.body.appendChild(d); const r=getComputedStyle(d);
		const o={top:parseFloat(r.top)||0,bottom:parseFloat(r.bottom)||0,left:parseFloat(r.left)||0,right:parseFloat(r.right)||0};
		d.remove(); return JSON.stringify(o); })()"""
	var raw: Variant = JavaScriptBridge.eval(js, true)
	if raw == null:
		return
	var parsed: Variant = JSON.parse_string(str(raw))
	if parsed is Dictionary:
		_insets = parsed

# ---- public API used by Player / Level ----

func set_prompt(text: String) -> void:
	_prompt.text = text
	if text == "":
		_hold_bg.visible = false

func set_hold(t: float) -> void:
	if t <= 0.0:
		_hold_bg.visible = false
		_hold_fill.size = Vector2(0.0, 10.0)
		return
	_hold_bg.visible = true
	_hold_fill.size = Vector2(180.0 * clampf(t, 0.0, 1.0), 10.0)

func set_objective(text: String) -> void:
	_objective.text = text

func set_detection(t: float) -> void:
	var c := clampf(t, 0.0, 1.0)
	_detect_fill.size = Vector2(220.0 * c, 14.0)
	_detect_fill.color = Color(0.3, 0.85, 0.4).lerp(Color(1.0, 0.2, 0.15), c)

func set_time(text: String) -> void:
	_timer.text = text

func set_clock(text: String, danger := false) -> void:
	_clock.visible = text != ""
	_clock.text = text
	_clock.modulate = Color(1, 0.35, 0.3) if danger else Color(1, 0.85, 0.3)

func set_sneak(on: bool) -> void:
	_btn_sneak.modulate = Color(0.6, 1.0, 0.7) if on else Color(1, 1, 1)

func show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var t := _toast.create_tween()
	t.tween_interval(1.8)
	t.tween_property(_toast, "modulate:a", 0.0, 0.8)

func photo_flash() -> void:
	if _flash == null:
		return
	_flash.color = Color(1, 1, 1, 0.75)
	var t := _flash.create_tween()
	t.tween_property(_flash, "color:a", 0.0, 0.4)

func flash_msg(text: String) -> void:
	_msg.text = text
	_msg.modulate.a = 1.0
	var t := _msg.create_tween()
	t.tween_interval(1.0)
	t.tween_property(_msg, "modulate:a", 0.0, 0.7)

func show_joystick(pos: Vector2) -> void:
	_joy_base.visible = true
	_joy_knob.visible = true
	_joy_base.position = pos - _joy_base.size * 0.5
	_joy_knob.position = pos - _joy_knob.size * 0.5
	_joy_base.set_meta("center", pos)

func move_knob(off: Vector2) -> void:
	if not _joy_base.visible:
		return
	var center: Vector2 = _joy_base.get_meta("center", Vector2.ZERO)
	_joy_knob.position = center + off - _joy_knob.size * 0.5

func hide_joystick() -> void:
	_joy_base.visible = false
	_joy_knob.visible = false

func point_over_button(pos: Vector2) -> bool:
	for b: Button in _buttons:
		if b.visible and b.get_global_rect().has_point(pos):
			return true
	return false

# ---- builders ----

func _label(text: String, fsize: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 4)
	return l

func _make_button(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 18)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color.r, color.g, color.b, 0.82)
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(2)
	sb.border_color = Color(1, 1, 1, 0.35)
	var sb_press := sb.duplicate() as StyleBoxFlat
	sb_press.bg_color = Color(color.r, color.g, color.b, 1.0)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb_press)
	b.add_theme_stylebox_override("focus", sb)
	return b

func _circle(diam: float, fill: Color, border: Color) -> Panel:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size = Vector2(diam, diam)
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(int(diam * 0.5))
	sb.set_border_width_all(2)
	sb.border_color = border
	p.add_theme_stylebox_override("panel", sb)
	return p

func _style(p: Panel, bg: Color, border: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(1)
	sb.border_color = border
	p.add_theme_stylebox_override("panel", sb)

class_name ChatPanel
extends CanvasLayer
## Free-form interrogation. POSTs {persona, messages} to the shared NPC brain and shows the
## in-character reply, SPOKEN aloud (TTS, per-NPC voice). Quick-reply chips guarantee it is
## playable without typing; the text field allows fully free-form questions. First successful
## exchange logs a testimony clue. Centered + width-capped to the viewport (portrait-safe).

signal closed

const ENDPOINT := "https://npc.myapping.com/chat"
const QUICK := ["Who took my daughter?", "Where did they go?", "What were they carrying?", "You're lying to me.", "Tell me, and I walk away."]

var _npc: Node
var _persona := ""
var _name := "Informant"
var _voice := "informant"
var _messages: Array = []
var _busy := false
var _got_reply := false

var _http: HTTPRequest
var _name_lbl: Label
var _transcript: VBoxContainer
var _scroll: ScrollContainer
var _input: LineEdit
var _send: Button
var _dots: Label
var _dot_timer: Timer
var _dot_n := 0
var _vb: VBoxContainer
var _chipflow: FlowContainer
var _content_w := 600.0

## Cap the panel to the live viewport so it never clips off a narrow portrait phone.
func _fit() -> void:
	_content_w = clampf(get_viewport().get_visible_rect().size.x - 28.0, 280.0, 600.0)
	if _vb != null:
		_vb.custom_minimum_size.x = _content_w
	if _scroll != null:
		_scroll.custom_minimum_size.x = _content_w
	if _chipflow != null:
		_chipflow.custom_minimum_size.x = _content_w
	if _transcript != null:
		for c in _transcript.get_children():
			if c.get_child_count() > 0 and c.get_child(0) is Label:
				(c.get_child(0) as Label).custom_minimum_size.x = _content_w - 40.0

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_http = HTTPRequest.new()
	_http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_http)
	_http.request_completed.connect(_on_response)
	_dot_timer = Timer.new()
	_dot_timer.wait_time = 0.4
	_dot_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_dot_timer.timeout.connect(_tick_dots)
	add_child(_dot_timer)
	_build()
	get_viewport().size_changed.connect(_fit)

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.1, 0.99)
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.5, 0.5, 0.65, 0.6)
	sb.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	_vb = vb
	vb.add_theme_constant_override("separation", 8)
	vb.custom_minimum_size = Vector2(600, 0)
	panel.add_child(vb)

	var head := HBoxContainer.new()
	vb.add_child(head)
	_name_lbl = Label.new()
	_name_lbl.add_theme_font_size_override("font_size", 22)
	_name_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_name_lbl)
	var close_btn := _chip("CLOSE", Color(0.4, 0.3, 0.3))
	close_btn.pressed.connect(close)
	head.add_child(close_btn)

	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(600, 300)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(_scroll)
	_transcript = VBoxContainer.new()
	_transcript.add_theme_constant_override("separation", 8)
	_transcript.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_transcript)

	_dots = Label.new()
	_dots.add_theme_font_size_override("font_size", 16)
	_dots.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	_dots.visible = false
	vb.add_child(_dots)

	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 6)
	var chipflow := FlowContainer.new()
	_chipflow = chipflow
	chipflow.custom_minimum_size = Vector2(600, 0)
	vb.add_child(chipflow)
	for q in QUICK:
		var c := _chip(q, Color(0.2, 0.4, 0.55))
		c.pressed.connect(_send_text.bind(q))
		chipflow.add_child(c)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vb.add_child(row)
	_input = LineEdit.new()
	_input.placeholder_text = "Ask anything..."
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.custom_minimum_size = Vector2(440, 44)
	_input.add_theme_font_size_override("font_size", 17)
	_input.virtual_keyboard_enabled = true
	_input.text_submitted.connect(_on_submit)
	row.add_child(_input)
	_send = _chip("ASK", Color(0.2, 0.55, 0.85))
	_send.custom_minimum_size = Vector2(90, 44)
	_send.pressed.connect(_on_send_pressed)
	row.add_child(_send)

func open(npc: Node) -> void:
	_npc = npc
	_persona = str(npc.call("persona")) if npc.has_method("persona") else ""
	_name = str(npc.get("display_name")) if npc.get("display_name") != null else "Informant"
	_voice = str(npc.call("voice_key")) if npc.has_method("voice_key") else "informant"
	_messages.clear()
	_got_reply = false
	for c in _transcript.get_children():
		c.queue_free()
	_set_name(_name)
	_fit()
	var hello := str(npc.call("opening_line")) if npc.has_method("opening_line") else "Etienne... you should not be here. What do you want?"
	_add_line(_name, hello, false)
	Voice.speak(hello, _voice)
	visible = true
	_input.text = ""
	_busy = false
	_update_busy()

func close() -> void:
	visible = false
	Voice.stop()
	if _npc != null and _npc.has_method("end_talk"):
		_npc.call("end_talk")
	closed.emit()

func _set_name(n: String) -> void:
	if _name_lbl != null:
		_name_lbl.text = n

func _on_submit(text: String) -> void:
	_send_text(text)

func _on_send_pressed() -> void:
	_send_text(_input.text)

func _send_text(text: String) -> void:
	var t := text.strip_edges()
	if t == "" or _busy:
		return
	_input.text = ""
	_add_line("You", t, true)
	_messages.append({"role": "user", "content": t})
	_trim()
	_busy = true
	_update_busy()
	_show_dots(true)
	var body := JSON.stringify({"persona": _persona, "messages": _messages})
	var err := _http.request(ENDPOINT, ["content-type: application/json"], HTTPClient.METHOD_POST, body)
	if err != OK:
		_fail()

func _on_response(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_show_dots(false)
	_busy = false
	_update_busy()
	if code != 200:
		_fail()
		return
	var txt := body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(txt)
	if not (parsed is Dictionary):
		_fail()
		return
	var d: Dictionary = parsed
	var reply := str(d.get("reply", "")).strip_edges()
	if reply == "":
		_fail()
		return
	_add_line(_name, reply, false)
	Voice.speak(reply, _voice)
	_messages.append({"role": "assistant", "content": reply})
	_trim()
	if not _got_reply:
		_got_reply = true
		if _npc != null and _npc.has_method("grant_clue"):
			_npc.call("grant_clue")

func _fail() -> void:
	_add_line(_name, "... (he looks away, lost in thought)", false)

func _add_line(who: String, text: String, mine: bool) -> void:
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.2, 0.3, 1) if mine else Color(0.18, 0.16, 0.12, 1)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(9)
	box.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = who + ": " + text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(_content_w - 40.0, 0)
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color(0.8, 0.92, 1.0) if mine else Color(1, 0.9, 0.7))
	box.add_child(l)
	_transcript.add_child(box)
	await get_tree().process_frame
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)

func _trim() -> void:
	while _messages.size() > 12:
		_messages.pop_front()

func _update_busy() -> void:
	_send.disabled = _busy
	_input.editable = not _busy
	_send.modulate = Color(0.5, 0.5, 0.5) if _busy else Color(1, 1, 1)

func _show_dots(on: bool) -> void:
	_dots.visible = on
	if on:
		_dot_n = 0
		_dots.text = "."
		_dot_timer.start()
	else:
		_dot_timer.stop()

func _tick_dots() -> void:
	_dot_n = (_dot_n + 1) % 3
	_dots.text = ".".repeat(_dot_n + 1)

func _chip(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 15)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color.r, color.g, color.b, 0.9)
	sb.set_corner_radius_all(9)
	sb.set_content_margin_all(8)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", sb)
	return b

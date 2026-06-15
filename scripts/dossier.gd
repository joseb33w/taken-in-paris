class_name Dossier
extends CanvasLayer
## The CASE DOSSIER: review collected evidence and physically LINK two clue cards into the
## deduction that opens the way forward. Works while the world is paused. Centered + width-
## capped to the live viewport so it never clips off a narrow portrait phone.

signal solved(level: int)
signal closed

var _level := 1
var _selected: Array = []
var _cards: Dictionary = {}   # id -> Button
var _panel: PanelContainer
var _list: VBoxContainer
var _scroll: ScrollContainer
var _status: Label
var _link_btn: Button
var _content_w := 560.0
var _solved_already := false

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()
	get_viewport().size_changed.connect(_fit)

## Cap the panel to the live viewport so it never clips off a narrow portrait phone.
func _fit() -> void:
	_content_w = clampf(get_viewport().get_visible_rect().size.x - 28.0, 280.0, 560.0)
	if _status != null:
		_status.custom_minimum_size.x = _content_w
	if _scroll != null:
		_scroll.custom_minimum_size.x = _content_w
	for cid in _cards:
		(_cards[cid] as Control).custom_minimum_size.x = _content_w - 12.0

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_panel = PanelContainer.new()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.12, 0.98)
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.5, 0.55, 0.7, 0.6)
	sb.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_panel.add_child(vb)

	var header := Label.new()
	header.text = "CASE DOSSIER"
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(header)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 15)
	_status.add_theme_color_override("font_color", Color(0.85, 0.9, 1))
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(560, 0)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_status)

	var scroll := ScrollContainer.new()
	_scroll = scroll
	scroll.custom_minimum_size = Vector2(560, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(footer)
	_link_btn = _btn("LINK CLUES", Color(0.2, 0.55, 0.85))
	_link_btn.pressed.connect(_on_link)
	footer.add_child(_link_btn)
	var close_btn := _btn("CLOSE", Color(0.35, 0.35, 0.4))
	close_btn.pressed.connect(close)
	footer.add_child(close_btn)

func open(level: int) -> void:
	_level = level
	_solved_already = Game.deduction_solved(level)
	_selected.clear()
	_fit()
	_rebuild()
	visible = true

func close() -> void:
	visible = false
	closed.emit()

func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	_cards.clear()
	var dd := Game.deduction_def(_level)
	if Game.evidence.is_empty():
		_status.text = "No evidence yet. Sneak past the guards and hold to collect the glowing clue nodes."
	elif _solved_already:
		_status.text = str(dd.get("title", "Case cracked.")) + "\n" + str(dd.get("text", "")) + "\nThe way forward is open."
	else:
		_status.text = "Select TWO clue cards that connect, then LINK CLUES to crack the case."
	for card in Game.evidence:
		if not (card is Dictionary):
			continue
		var c: Dictionary = card
		var id := str(c.get("id", ""))
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.toggle_mode = false
		b.custom_minimum_size = Vector2(_content_w, 0)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 15)
		b.text = "[" + str(c.get("kind", "")).to_upper() + "]  " + str(c.get("title", id)) + "\n" + str(c.get("text", ""))
		_style_card(b, false)
		b.pressed.connect(_on_card.bind(id))
		_list.add_child(b)
		_cards[id] = b
	_update_link_btn()

func _on_card(id: String) -> void:
	if _solved_already:
		return
	if _selected.has(id):
		_selected.erase(id)
	else:
		if _selected.size() >= 2:
			_selected.pop_front()
		_selected.append(id)
	for cid in _cards:
		_style_card(_cards[cid], _selected.has(cid))
	_update_link_btn()

func _update_link_btn() -> void:
	_link_btn.disabled = _solved_already or _selected.size() != 2
	_link_btn.modulate = Color(1, 1, 1) if not _link_btn.disabled else Color(0.5, 0.5, 0.5)

func _on_link() -> void:
	if _selected.size() != 2:
		return
	var ok := Game.try_link(_selected[0], _selected[1], _level)
	if ok:
		_solved_already = true
		var dd := Game.deduction_def(_level)
		_status.text = str(dd.get("title", "DEDUCTION!")) + "\n" + str(dd.get("text", ""))
		_update_link_btn()
		solved.emit(_level)
		create_timer_tween()
	else:
		_status.text = "Those two do not connect. Look again."
		var t := _status.create_tween()
		_status.modulate = Color(1, 0.4, 0.4)
		t.tween_property(_status, "modulate", Color(1, 1, 1), 0.6)

func create_timer_tween() -> void:
	var tm := get_tree().create_timer(1.6)
	tm.timeout.connect(func() -> void:
		if visible:
			close())

func _style_card(b: Button, sel: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.15, 0.2, 1) if not sel else Color(0.16, 0.28, 0.4, 1)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.4, 0.45, 0.55, 0.5) if not sel else Color(0.4, 0.85, 1.0, 1)
	sb.set_content_margin_all(10)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", sb)

func _btn(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(160, 46)
	b.add_theme_font_size_override("font_size", 18)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color.r, color.g, color.b, 0.9)
	sb.set_corner_radius_all(10)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", sb)
	return b

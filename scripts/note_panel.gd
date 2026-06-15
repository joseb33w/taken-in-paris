class_name NotePanel
extends CanvasLayer
## A small reading overlay for hidden notes / clue scraps. Pauses the world; Etienne reads
## the line aloud (TTS) the first time, and it persists to the dossier flags.

signal closed

var _title: Label
var _body: Label
var _note: Node

func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.93, 0.84, 0.99)
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.5, 0.42, 0.3, 0.9)
	sb.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.custom_minimum_size = Vector2(420, 0)
	panel.add_child(vb)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", Color(0.2, 0.12, 0.06))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)
	_body = Label.new()
	_body.add_theme_font_size_override("font_size", 17)
	_body.add_theme_color_override("font_color", Color(0.16, 0.12, 0.08))
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(420, 0)
	vb.add_child(_body)
	var close_btn := Button.new()
	close_btn.text = "POCKET IT"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.custom_minimum_size = Vector2(180, 44)
	close_btn.add_theme_font_size_override("font_size", 17)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.3, 0.24, 0.16, 1)
	bs.set_corner_radius_all(8)
	bs.set_content_margin_all(8)
	close_btn.add_theme_stylebox_override("normal", bs)
	close_btn.add_theme_stylebox_override("hover", bs)
	close_btn.add_theme_stylebox_override("pressed", bs)
	close_btn.add_theme_stylebox_override("focus", bs)
	close_btn.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82))
	close_btn.pressed.connect(close)
	var center := CenterContainer.new()
	center.add_child(close_btn)
	vb.add_child(center)

func open(note: Node) -> void:
	_note = note
	_title.text = str(note.get("title"))
	_body.text = str(note.get("body"))
	visible = true
	Audio.sfx("sfx_note")
	if note.has_method("mark_found") and not bool(note.get("found")):
		note.call("mark_found")
		Game.toast.emit("Lead noted: " + str(note.get("title")))
	Voice.speak(str(note.get("body")), "etienne")

func close() -> void:
	visible = false
	Voice.stop()
	closed.emit()

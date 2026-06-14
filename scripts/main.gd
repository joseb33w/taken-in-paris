extends Node3D
## Screen flow: tap-to-start -> auth (or resume) -> menu -> play levels -> endings, plus the
## leaderboard. Levels are instanced as children; meta UI lives on its own CanvasLayer.
## A #l1.. / #dev URL hash bypasses auth into gameplay for headless verification.

var ui: CanvasLayer
var root: Control
var current_level_node: LevelBase
var _busy := false

func _ready() -> void:
	var w := get_window()
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	ui = CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)
	_backdrop()

	await get_tree().process_frame
	var hash := _url_hash()
	if hash.begins_with("l") and hash.length() >= 2 and hash[1].is_valid_int():
		Game.play_as_guest()
		_start_level(clampi(int(hash[1]), 1, 5))
		return
	if hash == "dev":
		Game.play_as_guest()
		Game.furthest_level = 5
		_show_menu()
		return
	_show_tap_to_start()

func _url_hash() -> String:
	if not OS.has_feature("web"):
		return ""
	var raw: Variant = JavaScriptBridge.eval("(window.location.hash||'').replace('#','').toLowerCase()", true)
	return str(raw) if raw != null else ""

# ---------------------------------------------------------------- screens

func _clear_ui() -> void:
	for c in root.get_children():
		c.queue_free()

func _show_tap_to_start() -> void:
	_clear_ui()
	var panel := ColorRect.new()
	panel.color = Color(0.02, 0.03, 0.06, 1)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(box)
	box.add_child(_title("TAKEN IN PARIS", 44, Color(1, 0.84, 0.4)))
	box.add_child(_title("A stealth-thriller in five districts", 18, Color(0.85, 0.9, 1)))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	box.add_child(spacer)
	box.add_child(_title("Tap to begin", 22, Color(0.7, 0.9, 1)))
	panel.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventScreenTouch or e is InputEventMouseButton) and e.is_pressed():
			_after_tap())

func _after_tap() -> void:
	if _busy:
		return
	_busy = true
	_clear_ui()
	_loading("Connecting...")
	var resumed := await Game.try_resume()
	_busy = false
	if resumed.get("ok", false):
		_show_menu()
	else:
		_show_auth()

func _show_auth() -> void:
	_clear_ui()
	var card := _card()
	card.add_child(_title("OPERATIVE LOGIN", 30, Color(1, 0.85, 0.4)))
	card.add_child(_subtitle("Sign in to carry your progress across devices, or play as a guest."))
	var codename := _field("Codename (for the leaderboard)", false)
	var email := _field("Email", false)
	var password := _field("Password", true)
	card.add_child(codename)
	card.add_child(email)
	card.add_child(password)
	var status := _status_label()
	card.add_child(status)
	var signin := _menu_button("SIGN IN", Color(0.2, 0.55, 0.85))
	var signup := _menu_button("CREATE ACCOUNT", Color(0.25, 0.6, 0.45))
	var guest := _menu_button("PLAY AS GUEST (no cloud save)", Color(0.4, 0.4, 0.46))
	card.add_child(signin)
	card.add_child(signup)
	card.add_child(guest)
	signin.pressed.connect(func() -> void: await _do_auth(false, email.text, password.text, codename.text, status))
	signup.pressed.connect(func() -> void: await _do_auth(true, email.text, password.text, codename.text, status))
	guest.pressed.connect(func() -> void:
		Game.play_as_guest()
		_show_menu())

func _do_auth(create: bool, email: String, password: String, codename: String, status: Label) -> void:
	if _busy:
		return
	if email.strip_edges() == "" or password.strip_edges() == "":
		status.text = "Enter an email and password."
		return
	if create and codename.strip_edges() == "":
		status.text = "Choose a codename."
		return
	_busy = true
	status.text = "Connecting..."
	var r: Dictionary
	if create:
		r = await Game.sign_up(email.strip_edges(), password, codename.strip_edges())
	else:
		r = await Game.sign_in(email.strip_edges(), password)
	_busy = false
	if r.get("ok", false):
		_show_menu()
	else:
		var err := str(r.get("error", "unknown"))
		if err == "offline" or err == "bridge_unavailable" or err == "timeout":
			status.text = "Cannot reach the network here. You can still Play as Guest."
		else:
			status.text = "Login failed: " + err

func _show_menu() -> void:
	_clear_ui()
	var card := _card()
	card.add_child(_title("TAKEN IN PARIS", 36, Color(1, 0.84, 0.4)))
	var who := "Guest" if Game.guest else Game.codename
	card.add_child(_subtitle("Operative: " + who + "   |   Evidence: " + str(Game.evidence.size()) + "   |   Deductions: " + str(Game.clues_solved)))
	var cont := _menu_button("CONTINUE  (District " + str(Game.furthest_level) + ")", Color(0.2, 0.55, 0.85))
	cont.pressed.connect(func() -> void: _start_level(Game.furthest_level))
	card.add_child(cont)
	card.add_child(_subtitle("Select a district:"))
	var grid := GridContainer.new()
	grid.columns = 1
	grid.add_theme_constant_override("v_separation", 6)
	card.add_child(grid)
	for i in range(1, 6):
		var info: Dictionary = Game.LEVELS[i]
		var locked := i > Game.furthest_level
		var b := _menu_button(str(i) + ".  " + str(info["name"]) + ("   [LOCKED]" if locked else ""), Color(0.3, 0.35, 0.45) if locked else Color(0.28, 0.5, 0.42))
		b.disabled = locked
		var idx := i
		if not locked:
			b.pressed.connect(func() -> void: _start_level(idx))
		grid.add_child(b)
	var lb := _menu_button("LEADERBOARD", Color(0.45, 0.4, 0.6))
	lb.pressed.connect(func() -> void: await _show_leaderboard())
	card.add_child(lb)
	if not Game.guest:
		var so := _menu_button("SIGN OUT", Color(0.4, 0.34, 0.34))
		so.pressed.connect(func() -> void:
			await Game.sign_out()
			_show_auth())
		card.add_child(so)

func _show_leaderboard() -> void:
	_clear_ui()
	_loading("Loading fastest rescues...")
	var rows := await Game.leaderboard()
	_clear_ui()
	var card := _card()
	card.add_child(_title("FASTEST RESCUES", 30, Color(1, 0.85, 0.4)))
	if rows.is_empty():
		card.add_child(_subtitle("No times recorded yet. Be the first to bring Margaux home."))
	else:
		var rank := 1
		for row in rows:
			if not (row is Dictionary):
				continue
			var d: Dictionary = row
			var nm := str(d.get("codename", "Operative"))
			var ts := float(d.get("best_time_seconds", 0.0))
			var cl := int(d.get("clues_solved", 0))
			card.add_child(_subtitle("%d.  %s  -  %s   (%d clues)" % [rank, nm, Game.format_time(ts), cl]))
			rank += 1
	var back := _menu_button("BACK", Color(0.4, 0.4, 0.46))
	back.pressed.connect(_show_menu)
	card.add_child(back)

func _show_ending(result: Dictionary) -> void:
	_clear_ui()
	var card := _card()
	card.add_child(_title(str(result.get("title", "THE END")), 34, Color(1, 0.85, 0.4)))
	card.add_child(_subtitle(str(result.get("text", ""))))
	card.add_child(_subtitle("Rescue time: " + Game.format_time(Game.run_elapsed) + "   |   Clues solved: " + str(Game.clues_solved) + " / 4"))
	if Game.guest:
		card.add_child(_subtitle("(Guest run - sign in next time to save your time to the global leaderboard.)"))
	var lb := _menu_button("LEADERBOARD", Color(0.45, 0.4, 0.6))
	lb.pressed.connect(func() -> void: await _show_leaderboard())
	card.add_child(lb)
	var menu := _menu_button("MAIN MENU", Color(0.3, 0.5, 0.42))
	menu.pressed.connect(_show_menu)
	card.add_child(menu)

# ---------------------------------------------------------------- level lifecycle

func _start_level(n: int) -> void:
	_clear_ui()
	ui.visible = false
	if current_level_node != null and is_instance_valid(current_level_node):
		current_level_node.queue_free()
	if n == 1:
		Game.reset_run_timer()
	Game.current_level = n
	Game.timing_active = true
	var scr := load(str(Game.LEVELS[n]["script"]))
	var node: LevelBase = scr.new()
	node.main = self
	current_level_node = node
	add_child(node)

func on_level_cleared(n: int) -> void:
	if current_level_node != null and is_instance_valid(current_level_node):
		current_level_node.queue_free()
		current_level_node = null
	if n < 5:
		_start_level(n + 1)
	else:
		ui.visible = true
		_show_menu()

func on_finale(result: Dictionary) -> void:
	Game.timing_active = false
	if result.get("outcome", "") == "win":
		await Game.submit_score()
	if current_level_node != null and is_instance_valid(current_level_node):
		current_level_node.queue_free()
		current_level_node = null
	ui.visible = true
	_show_ending(result)

# ---------------------------------------------------------------- ui builders

func _backdrop() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.06, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(bg)
	ui.move_child(bg, 0)

func _card() -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.12, 0.96)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.5, 0.55, 0.7, 0.5)
	sb.set_content_margin_all(22)
	pc.add_theme_stylebox_override("panel", sb)
	center.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.custom_minimum_size = Vector2(380, 0)
	pc.add_child(vb)
	return vb

func _loading(text: String) -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	center.add_child(_title(text, 22, Color(0.8, 0.9, 1)))

func _title(text: String, fsize: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 5)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _subtitle(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.85, 0.9, 1))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(380, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _status_label() -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(1, 0.6, 0.5))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(380, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _field(placeholder: String, secret: bool) -> LineEdit:
	var le := LineEdit.new()
	le.placeholder_text = placeholder
	le.secret = secret
	le.custom_minimum_size = Vector2(380, 46)
	le.add_theme_font_size_override("font_size", 17)
	return le

func _menu_button(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(380, 50)
	b.add_theme_font_size_override("font_size", 18)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color.r, color.g, color.b, 0.92)
	sb.set_corner_radius_all(10)
	var sb2 := sb.duplicate() as StyleBoxFlat
	sb2.bg_color = Color(color.r, color.g, color.b, 1.0)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb2)
	b.add_theme_stylebox_override("pressed", sb2)
	b.add_theme_stylebox_override("focus", sb)
	b.add_theme_stylebox_override("disabled", sb)
	return b

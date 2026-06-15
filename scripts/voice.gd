extends Node
## Voiced dialogue (autoload "Voice"). Speaks NPC/story lines through the browser Web
## Speech engine (a French voice when the device has one) so you HEAR the characters, and
## shows a subtitle bar so the exchange reads even with audio off / no TTS voice installed.
## Per-character pitch + rate give the cast distinct voices. No audio assets, no API keys.

const PROFILES := {
	"etienne":       {"rate": 0.94, "pitch": 0.82, "lang": "fr-FR"},
	"margaux":       {"rate": 1.05, "pitch": 1.5,  "lang": "fr-FR"},
	"henchman":      {"rate": 0.9,  "pitch": 0.72, "lang": "fr-FR"},
	"waiter":        {"rate": 1.08, "pitch": 1.04, "lang": "fr-FR"},
	"musician":      {"rate": 0.97, "pitch": 0.95, "lang": "fr-FR"},
	"cop":           {"rate": 1.0,  "pitch": 0.9,  "lang": "fr-FR"},
	"flower_seller": {"rate": 0.95, "pitch": 1.28, "lang": "fr-FR"},
	"informant":     {"rate": 1.12, "pitch": 1.06, "lang": "fr-FR"},
	"kid":           {"rate": 1.1,  "pitch": 1.6,  "lang": "fr-FR"},
	"narrator":      {"rate": 0.96, "pitch": 1.0,  "lang": "fr-FR"},
}

var _layer: CanvasLayer
var _bar: PanelContainer
var _label: RichTextLabel
var _hide_tween: Tween
var _last_bark_ms := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 40
	add_child(_layer)
	_bar = PanelContainer.new()
	_bar.process_mode = Node.PROCESS_MODE_ALWAYS
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.03, 0.05, 0.82)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.6, 0.65, 0.8, 0.4)
	_bar.add_theme_stylebox_override("panel", sb)
	_layer.add_child(_bar)
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.custom_minimum_size = Vector2(560, 0)
	_label.add_theme_font_size_override("normal_font_size", 18)
	_bar.add_child(_label)
	_bar.visible = false
	get_viewport().size_changed.connect(_relayout)
	_relayout()

func _relayout() -> void:
	if _bar == null:
		return
	var s := get_viewport().get_visible_rect().size
	var w := minf(620.0, s.x - 40.0)
	_label.custom_minimum_size = Vector2(w - 24.0, 0)
	_bar.size = Vector2(w, _bar.size.y)
	_bar.position = Vector2((s.x - w) * 0.5, s.y * 0.78)

# ---------------------------------------------------------------- TTS

func speak(text: String, profile_key := "narrator") -> void:
	if not OS.has_feature("web"):
		return
	var t := text.strip_edges()
	if t == "":
		return
	var p: Dictionary = PROFILES.get(profile_key, PROFILES["narrator"])
	var js := "window.gogiSpeak && window.gogiSpeak(%s, %s)" % [JSON.stringify(t), JSON.stringify(JSON.stringify(p))]
	JavaScriptBridge.eval(js, true)

func stop() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.gogiStopSpeak && window.gogiStopSpeak()", true)

## Speak AND show a subtitle. Use for story beats / overheard lines / ambient barks.
func say(text: String, profile_key := "narrator", speaker := "") -> void:
	speak(text, profile_key)
	subtitle(text, speaker)

func subtitle(text: String, speaker := "", hold := 0.0) -> void:
	if _bar == null:
		return
	var name_col := "#ffd766"
	var line := ""
	if speaker != "":
		line = "[color=%s][b]%s[/b][/color]  " % [name_col, speaker]
	_label.text = line + "[color=#eef2ff]" + text + "[/color]"
	_bar.visible = true
	_bar.modulate.a = 1.0
	await get_tree().process_frame
	_relayout()
	var dur := hold if hold > 0.0 else clampf(1.6 + float(text.length()) * 0.045, 2.0, 7.0)
	if _hide_tween != null and _hide_tween.is_valid():
		_hide_tween.kill()
	_hide_tween = _bar.create_tween()
	_hide_tween.tween_interval(dur)
	_hide_tween.tween_property(_bar, "modulate:a", 0.0, 0.5)
	_hide_tween.tween_callback(func() -> void: _bar.visible = false)

## Throttled ambient bark (NPC mutters something as you pass) — speak + subtitle, but no
## more than one every ~3.5s so a crowd never talks over itself.
func bark(text: String, profile_key: String, speaker := "") -> bool:
	var now := Time.get_ticks_msec()
	if now - _last_bark_ms < 3500:
		return false
	_last_bark_ms = now
	say(text, profile_key, speaker)
	return true

func clear() -> void:
	stop()
	if _bar != null:
		_bar.visible = false

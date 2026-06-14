extends Node
## Low-level bridge to web/bridge.js (Supabase via supabase-js). Async request/poll
## pattern: bridge.js kicks off the promise, stashes the JSON result under an id, and
## we poll it each frame. On non-web (editor/headless) every call resolves offline so
## the game still runs and is verifiable without a reachable backend.

const TIMEOUT_MS := 14000

func is_web() -> bool:
	return OS.has_feature("web")

## Returns {"ok": bool, "data": Variant} or {"ok": false, "error": String}.
func request(method: String, args: Dictionary = {}) -> Dictionary:
	if not is_web():
		return {"ok": false, "error": "offline"}
	var argstr := JSON.stringify(args)
	var js := "window.gogiCall(%s, %s)" % [JSON.stringify(method), JSON.stringify(argstr)]
	var idv: Variant = JavaScriptBridge.eval(js, true)
	if idv == null:
		return {"ok": false, "error": "bridge_unavailable"}
	var id := int(idv)
	if id <= 0:
		return {"ok": false, "error": "bridge_unavailable"}
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < TIMEOUT_MS:
		await get_tree().process_frame
		var pollv: Variant = JavaScriptBridge.eval("window.gogiPoll(%d)" % id, true)
		var raw := ""
		if pollv != null:
			raw = str(pollv)
		if raw != "":
			var parsed: Variant = JSON.parse_string(raw)
			if parsed is Dictionary:
				return parsed
			return {"ok": false, "error": "bad_response"}
	return {"ok": false, "error": "timeout"}

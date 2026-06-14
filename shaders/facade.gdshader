shader_type spatial;
// Procedural lit Haussmann facade: a window grid in world space (consistent size on any
// box dimension), warm-lit cells chosen by a per-building seed, dark shopfront band at the
// bottom. One draw call per building, reads as a real Parisian building at night.
render_mode cull_back;
uniform vec3 wall : source_color = vec3(0.80, 0.76, 0.68);
uniform vec3 win_lit : source_color = vec3(1.0, 0.84, 0.5);
uniform vec3 win_dark : source_color = vec3(0.05, 0.07, 0.12);
uniform vec3 base_band : source_color = vec3(0.20, 0.19, 0.2);
uniform float seed = 1.0;
uniform float lit_ratio = 0.45;
uniform float floor_h = 1.7;
uniform float bay_w = 1.8;

varying vec3 wpos;
varying vec3 wn;

float hash(vec2 p) { return fract(sin(dot(p, vec2(41.31, 289.17)) + seed) * 43758.5453); }

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float horiz = (abs(wn.z) > abs(wn.x)) ? wpos.x : wpos.z;
	float vfac = 1.0 - clamp(abs(wn.y) * 4.0, 0.0, 1.0);
	float above_base = step(2.0, wpos.y);
	vec2 cellf = vec2(horiz / bay_w, (wpos.y - 2.0) / floor_h);
	vec2 cell = floor(cellf);
	vec2 f = fract(cellf);
	float inwin = step(0.2, f.x) * step(f.x, 0.8) * step(0.22, f.y) * step(f.y, 0.82);
	float lit = step(1.0 - lit_ratio, hash(cell));
	vec3 wincol = mix(win_dark, win_lit, lit);
	vec3 col = wall;
	col = mix(col, base_band, (1.0 - above_base) * vfac);
	col = mix(col, wincol, inwin * vfac * above_base);
	ALBEDO = col;
	ROUGHNESS = 0.85;
	EMISSION = win_lit * inwin * vfac * lit * above_base * 1.4;
}

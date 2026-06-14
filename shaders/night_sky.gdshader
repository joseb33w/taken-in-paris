shader_type sky;
// Procedural Paris night: deep gradient + warm horizon light-pollution glow + a faint
// star field. A ShaderMaterial sky (not a bare ProceduralSkyMaterial gradient).
uniform vec3 zenith : source_color = vec3(0.015, 0.025, 0.06);
uniform vec3 horizon : source_color = vec3(0.10, 0.09, 0.15);
uniform vec3 glow : source_color = vec3(0.55, 0.32, 0.16);
uniform float star_amount = 0.4;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = clamp(d.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 col = mix(horizon, zenith, pow(h, 0.55));
	float band = smoothstep(0.45, 0.0, abs(d.y));
	col += glow * band * 0.6;
	if (d.y > 0.04) {
		vec2 uv = vec2(atan(d.x, d.z), asin(clamp(d.y, -1.0, 1.0)));
		vec2 g = floor(uv * 70.0);
		float s = hash(g);
		float tw = 0.5 + 0.5 * sin(TIME * 1.5 + s * 40.0);
		float star = step(0.991, s) * tw * star_amount;
		col += vec3(star * 0.9, star * 0.95, star) * smoothstep(0.04, 0.3, d.y);
	}
	COLOR = col;
}

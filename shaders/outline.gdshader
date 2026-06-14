shader_type spatial;
render_mode unshaded, cull_front;
uniform float outline = 0.02;
uniform vec4 col : source_color = vec4(0.0, 0.0, 0.0, 1.0);
void vertex() { VERTEX += NORMAL * outline; }
void fragment() { ALBEDO = col.rgb; }

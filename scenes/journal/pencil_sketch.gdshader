shader_type canvas_item;
// Turns whatever is drawn underneath (the enlarged postcard) into a pencil sketch on
// paper: edges from the brightness, plus diagonal hatching in the dark parts.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec4 paper : source_color = vec4(0.965, 0.925, 0.84, 1.0);
uniform vec4 pencil : source_color = vec4(0.32, 0.29, 0.26, 1.0);
uniform float edge_strength = 5.0;
uniform float hatch_spacing = 7.0;

float lum(vec2 uv) {
	return dot(texture(screen_tex, uv).rgb, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * 1.5;
	vec2 uv = SCREEN_UV;
	float tl = lum(uv + vec2(-px.x, -px.y));
	float t = lum(uv + vec2(0.0, -px.y));
	float tr = lum(uv + vec2(px.x, -px.y));
	float l = lum(uv + vec2(-px.x, 0.0));
	float r = lum(uv + vec2(px.x, 0.0));
	float bl = lum(uv + vec2(-px.x, px.y));
	float b = lum(uv + vec2(0.0, px.y));
	float br = lum(uv + vec2(px.x, px.y));
	float gx = (tr + 2.0 * r + br) - (tl + 2.0 * l + bl);
	float gy = (bl + 2.0 * b + br) - (tl + 2.0 * t + tr);
	// Ignore the faintest differences (soft gradients, compression noise): only real lines.
	float edge = smoothstep(0.06, 0.22, length(vec2(gx, gy)) * edge_strength * 0.2);
	float shade = 1.0 - lum(uv);
	float line1 = step(0.55, fract((FRAGCOORD.x + FRAGCOORD.y) / hatch_spacing));
	float line2 = step(0.55, fract((FRAGCOORD.x - FRAGCOORD.y) / hatch_spacing));
	float hatch = line1 * smoothstep(0.35, 0.7, shade) * 0.45 + line2 * smoothstep(0.6, 0.9, shade) * 0.4;
	float ink = clamp(max(edge, hatch), 0.0, 1.0);
	COLOR = vec4(mix(paper.rgb, pencil.rgb, ink), 1.0);
}

shader_type canvas_item;
// Stream water: a gently moving surface, light-to-deep colour with depth and drifting
// glints. Works in local pixels of the Polygon2D it's on (surface_y/depth match the
// SteppingStones numbers), so it costs nothing on the CPU.

uniform vec4 shallow : source_color = vec4(0.47, 0.75, 0.82, 0.72);
uniform vec4 deep : source_color = vec4(0.13, 0.33, 0.47, 0.93);
uniform vec4 shine : source_color = vec4(0.88, 0.97, 1.0, 1.0);
uniform float surface_y = 16.0;
uniform float depth = 58.0;
// How fast the glints drift along the stream (px per second).
uniform float flow = 26.0;

varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	float wave = sin(local.x * 0.055 + TIME * 2.0) * 1.1 + sin(local.x * 0.13 - TIME * 1.4) * 0.5;
	float top = surface_y + wave;
	float below = local.y - top;
	if (below < -1.0) {
		discard;
	}
	float t = clamp(below / max(depth - surface_y, 1.0), 0.0, 1.0);
	vec4 c = mix(shallow, deep, smoothstep(0.0, 1.0, t));
	// Bright rim along the surface, with a one-pixel soft edge above it instead of a hard cut.
	float rim = 1.0 - smoothstep(0.0, 2.6, below);
	c.rgb = mix(c.rgb, shine.rgb, rim * 0.85);
	c.a = mix(c.a, 0.95, rim) * clamp(below + 1.0, 0.0, 1.0);
	// Short drifting glints, strongest near the surface.
	float x = local.x - TIME * flow;
	float band = sin(x * 0.085 + sin(local.y * 0.4 + TIME * 0.6) * 1.6) * sin(local.y * 0.55 - TIME * 0.9);
	float glint = smoothstep(0.9, 1.0, band) * (1.0 - t * 0.8);
	c.rgb = mix(c.rgb, shine.rgb, glint * 0.55);
	COLOR = c;
}

shader_type canvas_item;
// Gentle sway for plants and trees, plus a lean in wind gusts and (for grass and
// reeds) a bend away from the hiker brushing past. Each vertex carries its sway
// weight in UV.y (0 at the root, 1 at the tip) and a phase in UV.x, so one draw
// call can hold a whole meadow or forest.

global uniform float wind_strength;
global uniform vec2 hiker_pos;

uniform float sway_px = 1.6;
uniform float gust_px = 7.0;
uniform float brush_px = 0.0;
uniform float brush_radius = 34.0;

void vertex() {
	float w = UV.y;
	if (w > 0.0) {
		vec2 world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
		float phase = UV.x + world.x * 0.013;
		float sway = sin(TIME * 1.6 + phase) * sway_px + sin(TIME * 2.7 + phase * 1.7) * sway_px * 0.4;
		// Wind pushes back down the trail (towards -x).
		float gust = -wind_strength * gust_px;
		float dx = world.x - hiker_pos.x;
		float near = clamp(1.0 - abs(dx) / brush_radius, 0.0, 1.0) * step(abs(world.y - hiker_pos.y), 60.0);
		float brush = sign(dx) * near * brush_px;
		VERTEX.x += (sway + gust + brush) * w * w;
	}
}

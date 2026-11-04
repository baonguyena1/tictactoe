shader_type canvas_item;

// 0 = Circle Sweep for O, 1 = Two-Stroke Cross for X
uniform int mark_type : hint_range(0, 1) = 0;
// Drawing progress from 0.0 (empty) to 1.0 (fully drawn)
uniform float progress : hint_range(0.0, 1.0) = 1.0;
// Edge feathering for a natural brush-stroke feel
uniform float feather : hint_range(0.01, 0.15) = 0.04;
// Color tint applied to the hand-drawn mark
uniform vec4 mark_color : source_color = vec4(0.18, 0.15, 0.13, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float stroke_alpha = 0.0;

	if (mark_type == 0) {
		// O Mark: Circular sweep starting from 12 o'clock, proceeding clockwise
		vec2 dir = UV - vec2(0.5);
		float angle = atan(dir.x, -dir.y);
		if (angle < 0.0) {
			angle += 2.0 * PI;
		}
		float norm_angle = angle / (2.0 * PI);
		stroke_alpha = smoothstep(norm_angle - feather, norm_angle, progress);
	} else {
		// X Mark: Two diagonal strokes in sequence
		// Distance to diagonal 1 (\): abs(UV.x - UV.y)
		// Distance to diagonal 2 (/): abs(1.0 - UV.x - UV.y)
		float d1 = abs(UV.x - UV.y);
		float d2 = abs(1.0 - UV.x - UV.y);

		if (d1 <= d2) {
			// First stroke (\) drawn from top-left to bottom-right during progress 0.0 -> 0.5
			float t1 = (UV.x + UV.y) * 0.5;
			float p1 = clamp(progress * 2.0, 0.0, 1.0);
			stroke_alpha = smoothstep(t1 - feather, t1, p1);
		} else {
			// Second stroke (/) drawn from top-right to bottom-left during progress 0.5 -> 1.0
			float t2 = ((1.0 - UV.x) + UV.y) * 0.5;
			float p2 = clamp((progress - 0.5) * 2.0, 0.0, 1.0);
			stroke_alpha = smoothstep(t2 - feather, t2, p2);
		}
	}

	COLOR = vec4(mark_color.rgb, tex.a * mark_color.a * stroke_alpha);
}

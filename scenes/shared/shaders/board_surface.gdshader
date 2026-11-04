shader_type canvas_item;

// 0 = Chalkboard (Dark slate + chalk dust smudges)
// 1 = Vintage Paper (Warm yellowed paper + creases + stains)
uniform int skin_mode : hint_range(0, 1) = 0;
uniform vec2 aspect = vec2(0.5625, 1.0);

// Chalkboard palette
uniform vec4 chalk_bg_center : source_color = vec4(0.18, 0.21, 0.20, 1.0);
uniform vec4 chalk_bg_edge   : source_color = vec4(0.08, 0.10, 0.09, 1.0);

// Vintage paper palette
uniform vec4 paper_light : source_color = vec4(0.95, 0.89, 0.69, 1.0);
uniform vec4 paper_dark  : source_color = vec4(0.79, 0.66, 0.43, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int k = 0; k < 5; k++) {
		v += a * noise(p);
		p = rot * p * 2.04;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * aspect;
	float dist_center = distance(UV, vec2(0.5, 0.46));

	if (skin_mode == 0) {
		// CHALKBOARD SLATE
		float slate_grain = noise(uv * 280.0) * 0.035;
		float wipe_smudge = fbm(uv * vec2(2.4, 4.2) + vec2(1.7, 3.1));
		float scratch = pow(1.0 - abs(noise(uv * vec2(120.0, 6.0)) * 2.0 - 1.0), 18.0) * 0.04;

		vec3 base = mix(chalk_bg_center.rgb, chalk_bg_edge.rgb, smoothstep(0.05, 0.78, dist_center));
		base += vec3(wipe_smudge * 0.085); // Eraser chalk cloudiness
		base += vec3(slate_grain + scratch);
		COLOR = vec4(base, 1.0);
	} else {
		// VINTAGE CRUMPLED PAPER
		float stains = fbm(uv * 3.2);
		float crease = pow(1.0 - abs(fbm(uv * 5.5 + 7.0) * 2.0 - 1.0), 9.0);
		float fiber = noise(uv * 360.0) * 0.045;

		vec3 col = mix(paper_dark.rgb, paper_light.rgb, smoothstep(0.22, 0.78, mix(0.58, stains, 0.65)));
		col += crease * 0.09;
		col -= fiber;
		col *= 1.0 - smoothstep(0.32, 0.86, dist_center) * 0.48;
		COLOR = vec4(col, 1.0);
	}
}

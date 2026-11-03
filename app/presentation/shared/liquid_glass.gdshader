shader_type canvas_item;
render_mode blend_mix;

// Liquid Glass Shader for iOS 26+ and modern translucent frosted glass UI.
// Simulates real-time refraction, chromatic aberration, backdrop blur, and specular rim sheen.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.4;
uniform float refraction_strength : hint_range(0.0, 0.05) = 0.012;
uniform float chromatic_aberration : hint_range(0.0, 0.02) = 0.006;
uniform vec4 glass_tint : source_color = vec4(0.05, 0.09, 0.07, 0.65);
uniform float rim_power : hint_range(1.0, 10.0) = 3.2;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 0.35);

void fragment() {
	vec2 uv = UV;
	vec2 center = vec2(0.5);
	vec2 from_center = uv - center;
	float dist = length(from_center);

	// Curved glass lens displacement
	vec2 normal_offset = normalize(from_center + vec2(0.0001)) * pow(dist * 2.0, 2.0) * refraction_strength;
	vec2 screen_uv = SCREEN_UV + normal_offset;

	// Chromatic aberration samples
	vec4 red_sample = textureLod(screen_texture, screen_uv + vec2(chromatic_aberration, 0.0), blur_amount);
	vec4 green_sample = textureLod(screen_texture, screen_uv, blur_amount);
	vec4 blue_sample = textureLod(screen_texture, screen_uv - vec2(chromatic_aberration, 0.0), blur_amount);

	vec3 blurred_scene = vec3(red_sample.r, green_sample.g, blue_sample.b);

	// Specular rim reflection (Fresnel effect along glass bevel)
	float rim = pow(dist * 1.8, rim_power);
	rim = clamp(rim, 0.0, 1.0);

	// Composite glass tint + blurred refraction + specular rim
	vec3 final_color = mix(blurred_scene, glass_tint.rgb, glass_tint.a);
	final_color = mix(final_color, rim_color.rgb, rim * rim_color.a);

	COLOR = vec4(final_color, 1.0);
}

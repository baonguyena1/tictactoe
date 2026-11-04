shader_type canvas_item;
render_mode blend_mix;

// Liquid Glass Frosted Blur Shader
// Compatible with all Godot 4 renderers (gl_compatibility, mobile, forward_plus).
// Uses multi-tap Poisson/Gaussian sampling on screen_texture for rich frosted blur.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float blur_amount : hint_range(0.0, 10.0) = 4.5;
uniform float refraction_strength : hint_range(0.0, 0.05) = 0.012;
uniform float chromatic_aberration : hint_range(0.0, 0.02) = 0.005;
uniform vec4 glass_tint : source_color = vec4(0.02, 0.05, 0.03, 0.82);
uniform float rim_power : hint_range(1.0, 10.0) = 3.5;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 0.30);

void fragment() {
	vec2 uv = UV;
	vec2 center = vec2(0.5);
	vec2 from_center = uv - center;
	float dist = length(from_center);

	// Curved glass displacement
	vec2 normal_offset = normalize(from_center + vec2(0.0001)) * pow(dist * 2.0, 2.0) * refraction_strength;
	vec2 screen_uv = SCREEN_UV + normal_offset;

	// Multi-tap blur kernel using SCREEN_PIXEL_SIZE
	vec2 p = SCREEN_PIXEL_SIZE * blur_amount * 2.2;

	// 13-tap circular sampling for lush frosted glass blur
	vec4 blur_acc = texture(screen_texture, screen_uv) * 0.16;
	blur_acc += texture(screen_texture, screen_uv + vec2(-p.x, -p.y)) * 0.09;
	blur_acc += texture(screen_texture, screen_uv + vec2(0.0, -p.y * 1.2)) * 0.11;
	blur_acc += texture(screen_texture, screen_uv + vec2(p.x, -p.y)) * 0.09;
	blur_acc += texture(screen_texture, screen_uv + vec2(-p.x * 1.2, 0.0)) * 0.11;
	blur_acc += texture(screen_texture, screen_uv + vec2(p.x * 1.2, 0.0)) * 0.11;
	blur_acc += texture(screen_texture, screen_uv + vec2(-p.x, p.y)) * 0.09;
	blur_acc += texture(screen_texture, screen_uv + vec2(0.0, p.y * 1.2)) * 0.11;
	blur_acc += texture(screen_texture, screen_uv + vec2(p.x, p.y)) * 0.09;

	// Wide outer samples for soft haze
	vec2 p_wide = p * 2.2;
	vec4 wide_acc = texture(screen_texture, screen_uv + vec2(-p_wide.x, 0.0));
	wide_acc += texture(screen_texture, screen_uv + vec2(p_wide.x, 0.0));
	wide_acc += texture(screen_texture, screen_uv + vec2(0.0, -p_wide.y));
	wide_acc += texture(screen_texture, screen_uv + vec2(0.0, p_wide.y));
	vec3 blurred_scene = mix(blur_acc.rgb, wide_acc.rgb * 0.25, 0.35);

	// Add subtle chromatic fringe
	float r_fringe = texture(screen_texture, screen_uv + vec2(chromatic_aberration, 0.0)).r;
	float b_fringe = texture(screen_texture, screen_uv - vec2(chromatic_aberration, 0.0)).b;
	blurred_scene.r = mix(blurred_scene.r, r_fringe, 0.25);
	blurred_scene.b = mix(blurred_scene.b, b_fringe, 0.25);

	// Specular rim reflection along border
	float rim = pow(dist * 1.6, rim_power);
	rim = clamp(rim, 0.0, 1.0);

	// Composite frosted scene with dark chalkboard glass tint
	vec3 final_color = mix(blurred_scene, glass_tint.rgb, glass_tint.a);
	final_color = mix(final_color, rim_color.rgb, rim * rim_color.a);

	COLOR = vec4(final_color, 1.0);
}

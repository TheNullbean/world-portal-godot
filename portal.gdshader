shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

// The picture taken by the portal's hidden camera.
uniform sampler2D view : source_color, filter_linear;

void fragment() {
	// SCREEN_UV: read the picture at the same spot this pixel has on your screen.
	ALBEDO = texture(view, SCREEN_UV).rgb;
}

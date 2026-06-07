shader_type canvas_item;
// Basic luminance mask shader.
// Licensed under CC0 from Null Builds
// See https://godotshaders.com/shader/luminance-mask-transition/

/**
 * The cutoff point to apply the mask based on its sampled luminance. Sweep this
 * value to transition.
 * 
 * If the mask_texture uses pure black, a cutoff of slightly less than zero is
 * required to fully ignore it.
 */
uniform float luminance_cutoff: hint_range(0.0, 1.0) = 0.0;

/**
 * Inverts the behavior of luminance_cutoff.
 */
uniform bool invert = false;

/**
 * A greyscale texture defining the mask. Transitions will ocurr from light to
 * dark or dark to light depending on invert and luminance_cutoff.
 */
uniform sampler2D mask_texture: hint_default_white;

/**
 * The texture to display over masked areas. Try a solid color like black or a
 * loading image.
 */
uniform sampler2D display_texture: hint_default_black;

void fragment() {
	// Get the mask pixel color
	vec4 mask_color = texture(mask_texture, UV);
	
	// Convert the color to luminance (only matters if the mask is in color)
	// See https://en.wikipedia.org/wiki/Relative_luminance
	float luminance = dot(mask_color.rgb, vec3(0.2126, 0.7152, 0.0722));
	
	// Compare the sampled luminance to the cutoff
	bool masked = luminance > luminance_cutoff;
	if (invert) {
		masked = !masked;
	}
	
	if (masked) {
		// Mask the area with the display texture
		COLOR = texture(display_texture, UV);
	} else {
		// Show whatever is behind for unmasked areas
		COLOR = vec4(vec3(1.0), 0.0);
	}
}

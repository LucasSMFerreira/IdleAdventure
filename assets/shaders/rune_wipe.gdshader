shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 wipe_color : source_color = vec4(0.08, 0.04, 0.03, 1.0);

void fragment() {
	float rune_edge = sin(UV.y * 70.0 + UV.x * 18.0) * 0.025;
	float mask = smoothstep(progress - 0.08, progress + 0.02, UV.x + rune_edge);
	COLOR = vec4(wipe_color.rgb, wipe_color.a * (1.0 - mask));
}

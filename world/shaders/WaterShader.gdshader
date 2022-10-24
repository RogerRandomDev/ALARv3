shader_type canvas_item;

void fragment() {
	vec2 floatyBy=vec2(sin(TIME),cos(TIME))*SCREEN_PIXEL_SIZE*4.;
	vec4 tex=texture(TEXTURE,UV);
	COLOR.rgb=mix(
		tex.rgb,
		texture(SCREEN_TEXTURE,SCREEN_UV+floatyBy).rgb,
		0.5
	);
	
	COLOR.a=tex.a;
}


shader_type canvas_item;

void fragment() {
	float closest=64.;
	vec2 uv = UV;
	uv.x=floor(uv.x*128.)/128.;
	uv.y=floor(uv.y*128.)/128.;
	for(float x=-4.;x<4.;x++){for(float y=-4.;y<4.;y++){
		float col=texture(TEXTURE,uv+(vec2(x,y)*TEXTURE_PIXEL_SIZE)).a;
		if(col>0.0){
			closest=min(closest,(pow(x,2.)+pow(y,2.))/col);
		}
	}}
	COLOR.a=closest/32. -0.03125;
}
shader_type canvas_item;

void fragment() {
	float closest=72.;
	vec2 uv = UV/TEXTURE_PIXEL_SIZE;
	for(float x=-6.;x<6.;x++){for(float y=-6.;y<6.;y++){
		if(x*x+y*y >36.){continue;}
		float col=texture(TEXTURE,(uv+vec2(x,y))*TEXTURE_PIXEL_SIZE).a;
		
		closest=min(closest,float(x==0.&&y==0.&&col<0.5)*72.+(x*x+y*y)/max(float(col>0.5),0.001));
	}}
	
	COLOR.a=sqrt(closest/2.)/5.-0.2;
	
}
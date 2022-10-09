extends Node
func _ready():
	Input.add_joy_mapping("030000006f0e0000a40200000f010000,Microsoft Xbox One S pad - Wired,a:b0,b:b1,back:b6,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,leftshoulder:b4,leftstick:b9,lefttrigger:a2,leftx:a0,lefty:a1,rightshoulder:b5,rightstick:b10 ,righttrigger:a5,rightx:a3,righty:a4,start:b7,x:b2,y:b3,platform:Linux",true)
var directMouse=false
func _input(_event):
	
	var moveMouse=Vector2(
		Input.get_joy_axis(0,JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0,JOY_AXIS_RIGHT_Y))
	if !directMouse:
		#if move mouse is too small, it moves by the movement stick instead
		if moveMouse.length_squared()<0.5:
			
			get_viewport().warp_mouse(get_viewport().get_visible_rect().size/2+Vector2(
		Input.get_joy_axis(0,JOY_AXIS_LEFT_X),
		Input.get_joy_axis(0,JOY_AXIS_LEFT_Y))*256)
		else:
			get_viewport().warp_mouse(get_viewport().get_visible_rect().size/2+moveMouse*256)
		
	else:
		if moveMouse.length_squared()>0.5:
			get_viewport().warp_mouse(get_viewport().get_mouse_position()+moveMouse*4)
	#swaps mouse mode between global and direct, I.E. the stick moves, or the stick translates
	if Input.is_action_just_pressed("joyRDown"):directMouse=!directMouse

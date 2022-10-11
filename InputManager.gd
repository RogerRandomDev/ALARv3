extends Node

var useController=false
func _ready():
	if !useController:return
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	Input.add_joy_mapping("030000006f0e0000a40200000f010000,Microsoft Xbox One S pad - Wired,a:b0,b:b1,back:b6,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,leftshoulder:b4,leftstick:b9,lefttrigger:a2,leftx:a0,lefty:a1,rightshoulder:b5,rightstick:b10 ,righttrigger:a5,rightx:a3,righty:a4,start:b7,x:b2,y:b3,platform:Linux",true)
var directMouse=false
var just_warped=false
func _input(_event):
	if !useController:return
	if just_warped&&_event is InputEventMouseMotion:
		just_warped=false;return
	if _event is InputEventMouseMotion:
		get_viewport().warp_mouse(_event.position-_event.relative)
		just_warped=true
func _process(_delta):
	if !useController:return
	#swaps mouse mode between global and direct, I.E. the stick moves, or the stick translates
	if Input.is_action_just_pressed("joyRDown"):
		warpTo=get_viewport().get_mouse_position()
		directMouse=!directMouse
	moveMouseTo(_delta)
var warpTo=Vector2.ZERO
#updates mouse position using joystick
func moveMouseTo(delta):
	var moveMouse=Vector2(
		Input.get_joy_axis(0,JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0,JOY_AXIS_RIGHT_Y))
	if !directMouse:
		#if move mouse is too small, it moves by the movement stick instead
		if !(abs(moveMouse.x)<0.075&&abs(moveMouse.y)<0.075):
			just_warped=true
			
			get_viewport().warp_mouse(get_viewport().get_visible_rect().size/2+moveMouse*256)
		
	else:
			just_warped=true
			warpTo+=moveMouse*Vector2(
				int(abs(moveMouse.x)>0.125),
				int(abs(moveMouse.y)>0.125)
			)*delta*480
			get_viewport().warp_mouse(warpTo)


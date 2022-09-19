extends CanvasLayer


@onready var FPS=$VBoxContainer/FPS
@onready var MEM=$VBoxContainer/MEMORY
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	FPS.text="Frames Per Second: %s"%str(Engine.get_frames_per_second())
	MEM.text="Memory: %s/%s"%[str(OS.get_static_memory_usage()),str(OS.get_static_memory_peak_usage())]

var already=false
func _input(_event):
	if Input.is_key_pressed(KEY_F3):
		if already:return
		already=true
		self.visible=!self.visible
	else:
		already=false

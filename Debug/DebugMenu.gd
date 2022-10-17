extends CanvasLayer
##
#debug info
#Shows debugger info used for optimization and misc
#left in so player can check as well
##
@onready var FPS=$VBoxContainer/FPS
@onready var MEM=$VBoxContainer/MEMORY
@onready var BIM=$VBoxContainer/BIOME
@onready var CHU=$VBoxContainer/CHUNKPOS

func _process(_delta):
	if world.player==null:return
	FPS.text="Frames Per Second: %s"%str(Engine.get_frames_per_second())
	MEM.text="Memory: %s/%s"%[String.humanize_size(OS.get_static_memory_usage()),String.humanize_size(OS.get_static_memory_peak_usage())]
	BIM.text="Biome: %s"%world.chunkFiller.getBiomeCell(int(world.player.global_position.x/8)).biomeName
	var chunk=world.mapGen.globalToCell(world.player.global_position)
	CHU.text="Chunk: %s\nCell: %s"%[str(chunk[1]),str(chunk[0])]

var already=false
func _input(_event):
	if Input.is_key_pressed(KEY_F3):
		if already:return
		already=true
		self.visible=!self.visible
	else:
		already=false

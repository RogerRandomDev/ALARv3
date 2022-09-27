extends Sprite2D

var time=Timer.new()
func _ready():
	add_child(time)
	time.wait_time=0.125
	time.one_shot=true
	time.connect("timeout",hideBlast)
	time.start()
	$GpuParticles2d.emitting=true
func _process(delta):
	scale+=(scale*1.05)*delta
func hideBlast():
	time.disconnect("timeout",hideBlast)
	time.connect("timeout",freeSelf)
	time.wait_time=0.5
	time.start()
	self_modulate=Color(0,0,0,0)

func freeSelf():
	time.disconnect("timeout",freeSelf)
	queue_free()

extends itemDrop2D
class_name itemBomb2D

var explosionRadius:int=8
var body:=RigidBody2D.new()
var time=Timer.new()
func _ready():
	randomize()
	texture=load("res://entities/Explosives/Dynamite.png")
	var shape=CollisionShape2D.new()
	shape.shape=CircleShape2D.new()
	shape.shape.radius=4
	body.collision_layer=0
	body.can_sleep=false
	body.add_child(shape)
	
	body.angular_velocity=randi_range(-PI,PI)
	body.continuous_cd=true
	world.reparent(self,body)
	body.global_position=global_position
	position=Vector2.ZERO
	pickable=false
	
	add_child(time)
	time.one_shot=true
	time.wait_time=0.5
	time.start()
	time.connect("timeout",finishExplode)

#finishes the explosion once the timer is done
func finishExplode():
	time.disconnect("timeout",finishExplode)
	world.miscFunctions.explode(global_position,explosionRadius)
	quantityLabel.queue_free()
	body.queue_free()
	
	
	
func _physics_process(_delta):return

func prepFree():
	get_parent().queue_free()

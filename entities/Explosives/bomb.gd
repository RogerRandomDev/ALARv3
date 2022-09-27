extends itemDrop2D
class_name itemBomb2D

var explosionRadius:int=6
var body:=RigidBody2D.new()
var time=Timer.new()
var bombType="Bomb"
const physics=preload("res://entities/Explosives/BombPhysics.tres")
func _ready():
	randomize()
	texture=load("res://tools/%s.png"%bombType)
	var shape=CollisionShape2D.new()
	shape.shape=CircleShape2D.new()
	shape.shape.radius=3
	body.collision_layer=0
	body.collision_mask=2
	body.can_sleep=false
	body.add_child(shape)
	body.physics_material_override=physics
	body.angular_velocity=randi_range(-PI*3,PI*3)
	body.linear_velocity.y=min(body.linear_velocity.y,128)
	body.continuous_cd=true
	world.reparent(self,body)
	body.global_position=global_position
	position=Vector2.ZERO
	pickable=false
	body.gravity_scale=0.75
	add_child(time)
	time.one_shot=true
	time.wait_time=1
	time.start()
	time.connect("timeout",finishExplode)

#finishes the explosion once the timer is done
func finishExplode():
	time.disconnect("timeout",finishExplode)
	world.miscFunctions.explode(global_position,explosionRadius)
	
	quantityLabel.queue_free()
	body.queue_free()
	
	
	
func _physics_process(_delta):
	var variable=world.renderDistance
	var mult=world.chunkSize*world.tileSize
	body.freeze=(body.position.x>(world.mapGen.centerChunk.x+variable+1)*mult||
	body.position.x<(world.mapGen.centerChunk.x-variable)*mult||
	body.position.y>(world.mapGen.centerChunk.y+variable+1)*mult||
	body.position.y<(world.mapGen.centerChunk.y-variable)*mult)

func prepFree():
	get_parent().queue_free()

extends itemDrop2D
class_name itemBomb2D

var explosionRadius:int=6
var body:=RigidBody2D.new()
var time=Timer.new()
var bombType="Bomb"
var type=0
var num=0
const physics=preload("res://entities/Explosives/BombPhysics.tres")
var throwDir=Vector2.ZERO
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
	body.angular_velocity=randf_range(-PI*3,PI*3)
	body.linear_velocity.y=min(body.linear_velocity.y,128)
	body.continuous_cd=RigidBody2D.CCD_MODE_CAST_RAY
	body.contact_monitor=true
	body.max_contacts_reported=1
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
	
	type=id+1
	#updates throw direction
	throwDir=body.linear_velocity.normalized()

#finishes the explosion once the timer is done
func finishExplode():
	time.disconnect("timeout",finishExplode)
	match type:
		0:
			defaultExplosion()
		1:
			depthCharge()
		2:
			clusterBomb()
	quantityLabel.queue_free()
	body.queue_free()
#the default explosion method
func defaultExplosion():
	var rad=abs(explosionRadius)
	if explosionRadius>0:world.miscFunctions.call_deferred('explode',global_position,explosionRadius)
	else:world.miscFunctions.triggerExplosionFx(global_position,rad)
	knockbackPlayer()
#depthcharge goes horizontally only in a straight line
func depthCharge():
	if (type==1&&body.get_contact_count()):throwDir=lastVelocity.normalized()
	var removeTiles=[]
	var lineNormal=throwDir
	var dir=Vector2i(-explosionRadius*int(throwDir.x<0),-explosionRadius*int(throwDir.y<0))
	var angle=Vector2.ZERO.angle_to_point(lineNormal)
	var cPos=Vector2(0,0)
	
	lineNormal=Vector2(1,0).rotated(angle).normalized()
	var addDir=Vector2(0,1).rotated(angle)
	var lay1=ceil(abs(addDir))*sign(addDir)
	var lay0=floor(abs(addDir))*sign(addDir)
	lineNormal=lineNormal.normalized()
	
	for x in explosionRadius*2:
		cPos=floor(lineNormal*x)
		
		#appends cells to remove
		removeTiles.append_array([
			Vector2i(cPos),
			Vector2i(cPos+lay1/2),
			Vector2i(cPos-lay1/2),
			Vector2i(cPos+lay1),
			Vector2i(cPos-lay1)
			])
		if int(cPos.length())%3==0:
			world.miscFunctions.triggerExplosionFx(global_position+cPos*world.tileSize,3)
	world.miscFunctions.call_deferred('explode',global_position,explosionRadius,removeTiles,false)
	knockbackPlayer(Vector2(1,0),0.25)

#clusterbomb launches normal bombs in the area around it
func clusterBomb():
	pass



#player knockback force
func knockbackPlayer(dirMult=Vector2.ONE,rangeMult:=1.0):
	var rad=abs(explosionRadius)*rangeMult
	var knockBack=world.player.global_position-global_position
	if knockBack.length_squared()<(rad*world.tileSize)**2:
		var dir=(1-max(knockBack.length()/(rad*world.tileSize),0.25))*knockBack.normalized()
		world.player.velocity+=dir*rad*world.explosionForce*dirMult


var lastVelocity=Vector2.ZERO
func _physics_process(_delta):
	var variable=world.renderDistance
	var mult=world.chunkSize*world.tileSize
	body.freeze=(
		(type==1&&body.get_contact_count())||
		body.position.x>(world.mapGen.centerChunk.x+variable+1)*mult||
		body.position.x<(world.mapGen.centerChunk.x-variable)*mult||
		body.position.y>(world.mapGen.centerChunk.y+variable+1)*mult||
		body.position.y<(world.mapGen.centerChunk.y-variable)*mult
	)
	#stores last velocity to be used by anything needing what it was before sticking
	if !body.freeze:lastVelocity=body.linear_velocity
func prepFree():
	get_parent().queue_free()


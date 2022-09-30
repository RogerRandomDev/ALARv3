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
var sticky=false
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
	sticky=float(type)/3 >= 1
func _init():pass
#finishes the explosion once the timer is done
func finishExplode():
	time.disconnect("timeout",finishExplode)
	match type%3:
		0:
			defaultExplosion()
		1:
			stripCharge()
		2:
			clusterBomb()
	quantityLabel.queue_free()
	body.queue_free()
#the default explosion method
func defaultExplosion():
	var rad=abs(explosionRadius)
	if explosionRadius>0:GameTick.storeAction(self,world.miscFunctions.explode,[global_position,explosionRadius])
	else:world.miscFunctions.triggerExplosionFx(global_position,rad)
	knockbackPlayer()
	
#Stripcharge goes only in a straight line, based on where you threw it,
#or how it was moving when it landed
func stripCharge():
	if (sticky&&body.get_contact_count()):throwDir=lastVelocity.normalized()
	var removeTiles=[]
	var lineNormal=throwDir
	var _dir=Vector2i(-explosionRadius*int(throwDir.x<0),-explosionRadius*int(throwDir.y<0))
	var angle=Vector2.ZERO.angle_to_point(lineNormal)
	var cPos=Vector2(0,0)
	
	lineNormal=Vector2(1,0).rotated(angle).normalized()
	var addDir=Vector2(0,1).rotated(angle)
	var lay1=ceil(abs(addDir))*sign(addDir)
	var _lay0=floor(abs(addDir))*sign(addDir)
	lineNormal=lineNormal.normalized()
	#changes explosion range to be the desired value
	var explosionMult=3/explosionRadius
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
		#only triggers explosion every explosion radius
		#makes a long line of explosions for you
		#it looks nice
		if int(cPos.length())%3==0:
			world.miscFunctions.triggerExplosionFx(global_position+cPos*world.tileSize,3)
			knockbackPlayer(Vector2(1,0),explosionMult,cPos*world.tileSize)
	GameTick.storeAction(self,world.miscFunctions.explode,[global_position,explosionRadius,removeTiles,false])
	

#clusterbomb launches normal bombs in the area around it
#the bomb-bomb
func clusterBomb():
	var launchNum=explosionRadius
	for bomb in launchNum:
		
		var angle=Vector2(sin(PI*2*float(bomb)/float(launchNum)),cos(PI*2*float(bomb)/float(launchNum)))*512
		GameTick.storeAction(self,world.miscFunctions.fireBomb,[global_position,global_position+angle,6])
		



#player knockback force
func knockbackPlayer(dirMult=Vector2.ONE,rangeMult:=1.0,_offset:Vector2=Vector2.ZERO):
	var rad=abs(explosionRadius)*rangeMult
	var knockBack=world.player.global_position-global_position-_offset
	if knockBack.length_squared()<(rad*world.tileSize)**2:
		var dir=(1-max(knockBack.length()/(rad*world.tileSize),0.25))*knockBack.normalized()
		world.player.velocity+=dir*rad*world.explosionForce*dirMult


var lastVelocity=Vector2.ZERO
func _physics_process(_delta):
	var variable=world.renderDistance
	var mult=world.chunkSize*world.tileSize
	body.freeze=(
		(sticky&&body.get_contact_count())||
		body.position.x>(world.mapGen.centerChunk.x+variable+1)*mult||
		body.position.x<(world.mapGen.centerChunk.x-variable)*mult||
		body.position.y>(world.mapGen.centerChunk.y+variable+1)*mult||
		body.position.y<(world.mapGen.centerChunk.y-variable)*mult
	)
	#stores last velocity to be used by anything needing what it was before sticking
	if !body.freeze:lastVelocity=body.linear_velocity
func prepFree():
	get_parent().queue_free()


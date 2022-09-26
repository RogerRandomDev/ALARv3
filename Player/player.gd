extends CharacterBody2D


const SPEED = 128.0
const JUMP_VELOCITY = -256.0
@export var canMove=true
@onready var waterCollision=$waterCheck
# Get the gravity from the project settings to be synced with RigidBody nodes.

func _ready():
	canMove=true
	world.player=self



var inWater
func _physics_process(delta):
	if !canMove:return
	inWater=waterCollision.get_overlapping_bodies().size()>0
	if not is_on_floor():
		velocity.y += world.defaultGravity.y * delta
	else:velocity.y=min(velocity.y,0)
	# Handle Jump.
	if Input.is_action_just_pressed("u") and is_on_floor()&&$Icon.frame<5:
		velocity.y = JUMP_VELOCITY;return
	if Input.is_action_pressed("u") and inWater:
		velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("l", "r")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	#dampens motion when in water
	if(inWater):
		var resist=Vector2(sqrt(velocity.x**2 * 0.5)*sign(velocity.x),sqrt(velocity.y**2 * 0.01)*sign(velocity.y))
		velocity-=resist
	if velocity.x!=0:$Icon.flip_h=velocity.x<0
	move_and_slide()
	var myChunk=world.mapGen.globalToChunk(global_position)
	world.mapGen.moveCurrentChunk(myChunk)

func _input(event):
	if Input.is_action_pressed("m1")||Input.is_action_pressed("m2"):
		var mPos=get_global_mouse_position()
		var c=world.mapGen.globalToCell(mPos)
		var chunk=c[1]
		var cell=c[0]
		cell.x=cell.x%16;cell.y=cell.y%16;
		cell.x+=int(cell.x<0)*16;cell.y+=int(cell.y<0)*16
		world.call_deferred('changeCell',chunk,cell,int(Input.is_action_pressed("m2"))*2-1)
		#drops a bomb where the mouse is
		#currently very large explosion radius
		world.miscFunctions.fireBomb(global_position,mPos,8)


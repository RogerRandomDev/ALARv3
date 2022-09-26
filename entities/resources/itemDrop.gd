extends Sprite2D
class_name itemDrop2D
@export var itemName:String="ERROR_NAME"
@export var quantity:int=1
@export var itemWeight:int=1
var ray=PhysicsRayQueryParameters2D.new()
var pickable=true
var velocity=Vector2.ZERO
var nearChecks=0
var quantityLabel=Label.new()
func _ready():
	world.itemList.append(self)
	if !pickable:return
	add_child(quantityLabel)
	checkSameNearBy()
#handles freeing itself
func prepFree():
	world.itemList.erase(self)
	queue_free()


func _physics_process(delta):
	var variable=world.renderDistance
	var mult=world.chunkSize*world.tileSize
	if(position.x>(world.mapGen.centerChunk.x+variable+1)*mult||
	position.x<(world.mapGen.centerChunk.x-variable)*mult||
	position.y>(world.mapGen.centerChunk.y+variable+1)*mult||
	position.y<(world.mapGen.centerChunk.y-variable)*mult||
	!pickable):return
	rayCheck(delta)
	if(nearChecks>8):
		nearChecks=0
		checkSameNearBy()
	else:nearChecks+=1
	quantityLabel.text=str(quantity)
#handles the falling and moving up of items to stay on the floor
func rayCheck(delta):
	ray.from=global_position-Vector2(0,8.1)
	ray.to=global_position+Vector2(0,3)
	var hit:=get_world_2d().direct_space_state.intersect_ray(ray)
	velocity=clamp(velocity+world.defaultGravity*delta,-world.defaultGravity,world.defaultGravity)
	if hit:
		velocity=Vector2.ZERO
		global_position = hit.position
	position+=velocity*delta
	

func buildItem(itemData):
	scale*=0.5
	texture=itemData.texture
	quantity=itemData.quantity
	itemWeight=itemData.weight
	itemName=itemData.name

#gets the chunk the item is in
func getChunk():
	var pos=global_position
	var c=world.mapGen.globalToCell(pos)[1]
	
	return c

#checks if inside the given chunk
func inChunk(chunk):
	return getChunk()==chunk

#stacks same items together to their stack limit
func checkSameNearBy():
	if quantity>=99:return
	for item in world.itemList:
		if item==self||item.itemName!=itemName||(item.global_position-global_position).length_squared()>256||item.quantity>=99:continue
		var itemQuantity=item.quantity+quantity
		if itemQuantity>99:
			item.quantity=itemQuantity-99
			quantity=99
			return
			
		quantity+=item.quantity
		item.prepFree()
	

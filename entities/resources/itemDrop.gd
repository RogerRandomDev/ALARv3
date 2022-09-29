extends Sprite2D
class_name itemDrop2D
@export var itemName:String="ERROR_NAME"
@export var quantity:int=1
@export var itemWeight:int=1
@export var actionRadius:int=8
@export var actionType:String="mine"
@export var id:int=-1

var ray=PhysicsRayQueryParameters2D.new()
var pickable=true
var velocity=Vector2.ZERO
var nearChecks=0
var lifeTime:float=0.0



var quantityLabel=Label.new()

var toFree=false
func _ready():
	z_index=100
	if !world.itemList.has(self):world.itemList.append(self)
	if !pickable:return
	add_child(quantityLabel)
	quantityLabel.theme=world.itemTheme
#handles freeing itself
func prepFree():
	if world.itemList.has(self):
		world.itemList.erase(self)
	toFree=true
	queue_free()


func _physics_process(delta):
	lifeTime+=delta
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
	ray.from=position-Vector2(0,8.1)
	ray.to=position+Vector2(0,3)
	var hit:=get_world_2d().direct_space_state.intersect_ray(ray)
	velocity=clamp(velocity+world.defaultGravity*delta,-world.defaultGravity,world.defaultGravity)
	if hit:
		
		if hit.collider.name=="Player":
			if !lifeTime>world.itemPickupBuffer:return
			var newStack=world.inventory.storeItem(
				{"quantity":quantity,
				"name":itemName,
				"id":id,
				"actionType":actionType,
				"actionRadius":actionRadius})
			if newStack>0:
				quantity=newStack
				quantityLabel.text=str(newStack)
			else:prepFree()
		else:
			velocity=Vector2.ZERO
			global_position += (hit.position-position)*delta*15
	position+=velocity*delta
	

func buildItem(itemData):
	scale*=0.5
	texture=itemData.texture
	quantity=itemData.quantity
	itemWeight=itemData.weight
	itemName=itemData.name
	id=itemData.id
	actionType=itemData.actionType
	actionRadius=itemData.actionRadius

#gets the chunk the item is in
func getChunk():
	var pos=position
	var c=world.mapGen.globalToCell(pos)[1]
	
	return c

#checks if inside the given chunk
func inChunk(chunk):
	return getChunk()==chunk

#stacks same items together to their stack limit
func checkSameNearBy():
	if quantity>=world.maxItemStack||toFree:return
	for item in world.itemList:
		if toFree:break
		if(
			item==null||item.toFree||item==self||
			item.itemName!=itemName||
			(item.position-position).length_squared()>80||
			item.quantity>=world.maxItemStack):continue
		
		var itemQuantity=item.quantity+quantity
		if itemQuantity>world.maxItemStack:
			item.quantity=itemQuantity-world.maxItemStack
			quantity=world.maxItemStack
			return
			
		quantity+=item.quantity
		item.prepFree()


#formats the item to data to get stored
func storageFormat():
	
	return [
		quantity,
		actionRadius,
		itemName,
		actionType,
		id
	]
#rebuilds from storage format
func fromStorageFormat(data):
	var texPath = ("res://tools/%s.png" if data[3]!="place" else "res://world/Tiles/%s.png")
	buildItem({
		"quantity":data[0],
		"actionRadius":data[1],
		"name":data[2],
		"weight":1,
		"actionType":data[3],
		"texture":load(texPath%data[2]),
		"id":data[4]
	})
	
	

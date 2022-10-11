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
#prevent it from being orphaned and taking up memory as a leak
func _init():
	
	
	z_index=100
	if !pickable:return
	add_child.call_deferred(quantityLabel)
	quantityLabel.theme=world.itemTheme
	
	
#handles freeing itself
func prepFree():
	
	if is_queued_for_deletion()||toFree||free:return
	if world.itemList.has(self):
		world.itemList.erase(self)
	if world.itemDropStore.has(self):
		world.itemDropStore.erase(self)
	if world.itemDropStore.size()<2499:
		world.itemDropStore.push_back(self)
	else:
		if !is_queued_for_deletion()&&!free&&!toFree:queue_free()
	toFree=true
	
	toggleActive(false)
#toggle item activity
func toggleActive(isActive):
	lifeTime=0.0
	set_physics_process_internal(isActive)
	set_physics_process(isActive)
	visible=isActive

func _physics_process(delta):
	if !visible:return
	lifeTime+=delta
	if(position.x>GameTick.rrX||
	position.x<GameTick.rlX||
	position.y>GameTick.rbY||
	position.y<GameTick.rtY||
	!pickable):return
	rayCheck(delta)
	if(nearChecks>8):
		
		nearChecks=0
		checkSameNearBy()
	else:nearChecks+=1
	
#handles the falling and moving up of items to stay on the floor
func rayCheck(delta):
	if get_parent()==null||free||toFree:return
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
				"actionRange":actionRadius})
			if newStack>0:
				quantity=newStack
				quantityLabel.text=str(newStack)
			else:prepFree.call_deferred()
		else:
			velocity=Vector2.ZERO
			position += (hit.position-position)*delta*15
	position+=velocity*delta
	

func buildItem(itemData):
	
	toggleActive(true)
	toFree=false
	free=false
	if !world.itemList.has(self):world.itemList.append(self)
	if !itemData.has("texture"):
		var texPath = ("res://tools/%s.png" if itemData.actionType!="place" else "res://world/Tiles/%s.png")
		itemData.texture=load(texPath%itemData.name)
	scale=Vector2(0.5,0.5)
	texture=itemData.texture
	quantity=itemData.quantity
	itemName=itemData.name
	id=itemData.id
	actionType=itemData.actionType
	if itemData.actionRange!=null:actionRadius=itemData.actionRange
	quantityLabel.text=str(quantity)
	toggleActive(true)
#gets the chunk the item is in
func getChunk():
	var pos=position
	var ce=world.mapGen.globalToCell(pos)
	return ce[1]
#checks if in render distance, if not it stores in the chunk it is in
func checkInRenderDistance():
	if !visible||!pickable||toFree:return
	var ce=world.mapGen.globalToCell(position-Vector2(0,7))
	if !(position.x>GameTick.rrX||
	position.x<GameTick.rlX||
	position.y>GameTick.rbY||
	position.y<GameTick.rtY):return
	var dat=storageFormat()
	dat.append(ce[0])
	world.storeEntityToChunk(ce[1],dat)
	prepFree.call_deferred()
		
#checks if inside the given chunk
func inChunk(chunk):
	return getChunk()==chunk

#stacks same items together to their stack limit
func checkSameNearBy():
	if quantity>=world.maxItemStack||toFree:return
	for item in world.itemList:
		if toFree||free:break
		if(
			item.itemName!=itemName||item==null||
			item.toFree||item==self||item.free||
			#increases the radius them ore items there are
			#does this to reduce lag from large item counts
			(item.position-position).length_squared()>(65)||
			item.quantity>=world.maxItemStack):continue
		
		var itemQuantity=item.quantity+quantity
		if itemQuantity>world.maxItemStack:
			item.quantity=itemQuantity-world.maxItemStack
			quantity=world.maxItemStack
			return
		quantity+=item.quantity
		item.prepFree()
		item.free=true
	quantityLabel.text=str(quantity)
var free=false

#formats the item to data to get stored
func storageFormat():
	
	return world.itemManager.compressToStorage({
		"quantity":quantity,
		"actionRange":actionRadius,
		"name":itemName,
		"actionType":actionType,
		"id":id
	})
#rebuilds from storage format
func fromStorageFormat(data):
	var texPath = ("res://tools/%s.png" if data[3]!="place" else "res://world/Tiles/%s.png")
	buildItem({
		"quantity":data[0],
		"actionRange":data[1],
		"name":data[2],
		"weight":1,
		"actionType":data[3],
		"texture":load(texPath%data[2]),
		"id":data[4]
	})
	
	

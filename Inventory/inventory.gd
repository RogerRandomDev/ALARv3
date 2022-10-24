extends Node

var inventoryData=[]
var inventorySize:int=32
var holdingSlot=0
var toggled=false
signal updateSlot(slot,data)
var emptySlotb={
			"name":null,
			"quantity":0,
			"id":-1,
			"actionType":"empty",
			"actionRange":1,
			"location":-1,
			"slotNum":0,
			"gameID":-1}

func _ready():
	inventoryData.resize(inventorySize)
	for slot in inventorySize:
		inventoryData[slot]=emptySlotb.duplicate()
		inventoryData[slot].slotNum=slot
	call_deferred('storeItem',{
			"name":"Drill",
			"quantity":1,
			"id":-1,
			"actionType":"mine",
			"location":1,
			"actionRange":0})
	call_deferred('storeItem',{
			"name":"Dynamite",
			"quantity":400,
			"id":-1,
			"actionType":"throw",
			"location":1,
			"actionRange":12})
#builds using just an id and quantity of each item
func buildFromStorage(inputData):
	for slot in len(inputData):
		if inputData[slot][0]==-1:
			inventoryData[slot]=emptySlotb.duplicate()
			inventoryData[slot].slotNum=slot
			continue
		var data=world.itemManager.getItemData(
			world.itemManager.getItemName(inputData[slot][0])
		)
		inventoryData[slot]={
			"name":data.name,
			"quantity":inputData[slot][1],
			"id":data.id,
			"actionType":data.actionType,
			"location":data.location,
			"actionRange":data.actionRange,
			"slotNum":slot,
			"gameID":data.gameID
			}
		emit_signal("updateSlot",slot)
#converts data to storage format
func convertToStorage():
	var output=inventoryData.map(func(e):
		return [world.itemManager.itemData.keys().find(e.name),e.quantity])
	return output

func storeItem(item):
	if !item.has("gameID"):item.gameID=world.itemManager.itemData.keys().find(item.name)
	var count = item.quantity
	var slots=inventoryData.filter(
		func(slot):return (slot.name==item.name)&&slot.quantity<world.maxItemStack
		);slots.append_array(
			inventoryData.filter(func(slot):return slot.name==null)
		)
	for slot in slots:
		
		var combined=count+slot.quantity
		if(slot.name)==null:
			inventoryData[slot.slotNum]=item
			inventoryData[slot.slotNum].slotNum=slot.slotNum
			
			emit_signal("updateSlot",slot.slotNum)
			return 0
		elif(combined>world.maxItemStack):
			count=combined-world.maxItemStack
			inventoryData[slot.slotNum].quantity=world.maxItemStack
			emit_signal("updateSlot",slot.slotNum)
		else:
			inventoryData[slot.slotNum].quantity+=count
			emit_signal("updateSlot",slot.slotNum)
			return 0
	
	return count
#removes given number from the slot
func reduceSlotBy(slot,count):
	
	inventoryData[slot].quantity-=count
	if inventoryData[slot].quantity<=0:
		emptySlot(slot)
	else:emit_signal("updateSlot",slot)
#removes given number from any slot with the item
#until it meets the amount
func removeItemBy(itemName,count):
	var slotSearch=inventoryData.filter(func(e):return e.name==itemName)
	var remaining=count
	for slot in slotSearch:
		
		#empties if it still has more left
		if remaining>=inventoryData[slot.slotNum].quantity:
			remaining-=inventoryData[slot.slotNum].quantity
			emptySlot(slot.slotNum)
		#otherwise, leave the remaining and exit loop
		else:
			inventoryData[slot.slotNum].quantity-=remaining
			emit_signal("updateSlot",slot.slotNum)
			break
		
#sets slot to default empty value
func emptySlot(slot):
	inventoryData[slot]=emptySlotb.duplicate()
	inventoryData[slot].slotNum=slot
	emit_signal("updateSlot",slot)
#checks if you have a minimum of the given quantity of the given item
func haveEnough(itemName,itemQuantity):
	#filters to only the wanted items,
	#then reduces while adding the quantities
	#and returns if the output is greater than itemQuantity
	var out=inventoryData.filter(
		func(i):return i.name==itemName).map(
			func(e):return e.quantity).reduce(
			func(a,b):return a+b)
	return (out!=null&&out>=itemQuantity-1)

#gets the active slot data
func get_active():
	return inventoryData[holdingSlot]
#swaps two slots with one another
func swapSlots(slotA,slotB,_replaceA:bool=true):
	if slotA==slotB:return
	var slotAData=inventoryData[slotA]
	var slotBData=inventoryData[slotB]
	
	if slotAData.name==slotBData.name:
		var combined=slotAData.quantity+slotBData.quantity
		if combined>world.maxItemStack:
			slotBData.quantity=world.maxItemStack
			slotAData.quantity=combined-world.maxItemStack
		else:
			slotBData.quantity+=slotAData.quantity
			slotAData=emptySlotb.duplicate()
	else:
		slotAData=slotBData
		slotBData=inventoryData[slotA]
	slotAData.slotNum=slotA
	slotBData.slotNum=slotB
	
	inventoryData[slotB]=slotBData
	inventoryData[slotA]=slotAData
	emit_signal("updateSlot",slotA)
	emit_signal("updateSlot",slotB)
	return slotAData


#drops items into world
func dropItem(slotID):
	var dropData=inventoryData[slotID]
	if dropData.name==null:return
	dropData.texture=world.playerInventory.get_node("heldItem").texture
	dropData.weight=1
	world.dropItem(world.player.global_position/world.tileSize-Vector2(0.5,0.5),dropData)
	inventoryData[slotID]=emptySlotb.duplicate()
	inventoryData[slotID].slotNum=slotID
	emit_signal("updateSlot",slotID)

#checks if there is enough space in the inventory for the given items
func hasRoomFor(itemName,quantityOf):
	if inventoryData.filter(func(e):return e.name==null):return true
	var slotCheck=inventoryData.filter(func(e):return e.name==itemName&&e.quantity<world.maxItemStack)
	var curQuantity=quantityOf
	for slot in slotCheck:
		curQuantity-=world.maxItemStack-inventoryData[slot].quantity
	return curQuantity<=0

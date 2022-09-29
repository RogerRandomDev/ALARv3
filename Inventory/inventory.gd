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
			"actionType":"mine",
			"actionRadius":1,
			"slotNum":0}

func _ready():
	inventoryData.resize(inventorySize)
	for slot in inventorySize:
		inventoryData[slot]=emptySlotb.duplicate()
		inventoryData[slot].slotNum=slot
	call_deferred('storeItem',{
			"name":"Dynamite",
			"quantity":1,
			"id":-1,
			"actionType":"throw",
			"actionRadius":12})
	call_deferred('storeItem',{
			"name":"Bomb",
			"quantity":1,
			"id":0,
			"actionType":"throw",
			"actionRadius":12})
func storeItem(item):
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

#sets slot to default empty value
func emptySlot(slot):
	inventoryData[slot]=emptySlotb.duplicate()
	inventoryData[slot].slotNum=slot
	emit_signal("updateSlot",slot)

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
	world.dropItem(world.player.global_position/world.tileSize,dropData)
	inventoryData[slotID]=emptySlotb.duplicate()
	inventoryData[slotID].slotNum=slotID
	emit_signal("updateSlot",slotID)

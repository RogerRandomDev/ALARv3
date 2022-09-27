extends Node

var inventoryData=[]
var inventorySize:int=32
var holdingSlot=0
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
			"name":"Bomb",
			"quantity":1,
			"id":-1,
			"actionType":"throw",
			"actionRadius":5})

func storeItem(item):
	var count = item.quantity
	var slots=inventoryData.filter(
		func(slot):return (slot.name==item.name||slot.name==null)&&slot.quantity<world.maxItemStack
		)
	
	for slot in slots:
		var combined=count+slot.quantity
		if(slot.name)==null:
			inventoryData[slot.slotNum]=item
			inventoryData[slot.slotNum].slotNum=slot.slotNum
			emit_signal("updateSlot",slot.slotNum)
			return true
		elif(combined>world.maxItemStack):
			count=combined-world.maxItemStack
			inventoryData[slot.slotNum].quantity=world.maxItemStack
			emit_signal("updateSlot",slot.slotNum)
		else:
			inventoryData[slot.slotNum].quantity+=count
			emit_signal("updateSlot",slot.slotNum)
			return true
	return false
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

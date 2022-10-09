extends CanvasLayer

signal toggleVisible(count)
signal toggleActive(slotNum)
const basicTextures={
	"EMPTYSLOT":preload("res://Inventory/inventorySlot.png")
}
var chosenItem=Sprite2D.new()
func _ready():
	buildMenu()
	add_child(chosenItem)
	world.inventory.connect("updateSlot",updateSlot)

var curHeld=-1
@onready var heldItem=$heldItem
#builds basic setup for inventory
func buildMenu():
	var holder=$ItemList
	for item in world.inventory.inventorySize:
		var slot=TextureRect.new()
		slot.self_modulate=Color(0.75,0.75,0.75,1.0)
		#slot update actions
		connect("toggleVisible",func(c):slot.visible=c>item)
		connect("toggleActive",func(c):
			slot.scale=Vector2(float(c==item)*0.5+1.0,float(c==item)*0.5+1.0)
			slot.pivot_offset=Vector2(int(c==item)*6,int(c==item)*6)
			)
		
		slot.texture=basicTextures.EMPTYSLOT
		slot.ignore_texture_size=true
		slot.custom_minimum_size=Vector2(12,12)
		var count=Label.new()
		count.mouse_filter=Control.MOUSE_FILTER_PASS
		count.name="itemCount"
		count.position=Vector2(0,6)
		count.size=Vector2(8,12)
		count.text_direction=Control.TEXT_DIRECTION_RTL
		
		var itemTex=TextureRect.new()
		itemTex.mouse_filter=Control.MOUSE_FILTER_PASS
		count.theme=world.itemTheme
		itemTex.ignore_texture_size=true
		itemTex.set_size(Vector2(8,8))
		itemTex.position=Vector2(2,2)
		slot.add_child(itemTex)
		itemTex.name="itemTex"
		holder.add_child(slot)
		slot.add_child(count)
		#lets you select the slot with your mouse
		
	
	emit_signal("toggleVisible",8)
#updates singular slot data
func updateSlot(slot):
	var slotItem=$ItemList.get_child(slot)
	var slotData=world.inventory.inventoryData[slot]
	if slotData.name==null:
		slotItem.get_node("itemTex").visible=false
	else:
		slotItem.get_node("itemTex").texture=world.findItemTexture(slotData)
		slotItem.get_node("itemTex").visible=true
	if slotData.quantity>1:
		slotItem.get_node("itemCount").text=str(slotData.quantity)
	else:
		slotItem.get_node("itemCount").text=""
var releasedChange=true
#changes which slot is held
func _input(_event):
	justHeld=false
	checkInv(_event)
	heldItem.global_position=heldItem.get_global_mouse_position()
	var held=world.inventory.holdingSlot
	if _event is InputEventKey:
		
		match _event.keycode:
			49:world.inventory.holdingSlot=0
			50:world.inventory.holdingSlot=1
			51:world.inventory.holdingSlot=2
			52:world.inventory.holdingSlot=3
			53:world.inventory.holdingSlot=4
			54:world.inventory.holdingSlot=5
			55:world.inventory.holdingSlot=6
			56:world.inventory.holdingSlot=7
	else:
		if releasedChange:
			#handles scroll wheel and controller switching
			world.inventory.holdingSlot=(held+(
				int(Input.is_action_just_pressed("nextHotBar"))-
				int(Input.is_action_just_pressed("prevHotBar"))
				))%8
			if world.inventory.holdingSlot!=held:releasedChange=false
	if world.inventory.holdingSlot<0:world.inventory.holdingSlot=7
	#resets mine progress if changing held item
	if held!=world.inventory.holdingSlot:
		if(world.inventory.get_active().actionType!="mine"):
			world.itemActions.mineTex.visible=false
		world.mineTimer.stop()
	
	if Input.is_key_pressed(KEY_E):
		world.inventory.toggled=!world.inventory.toggled
		emit_signal("toggleVisible",int(world.inventory.toggled)*(world.inventory.inventorySize-8)+8)
	emit_signal("toggleActive",world.inventory.holdingSlot)
	releasedChange=releasedChange||(Input.is_action_just_released("nextHotBar")||
	Input.is_action_just_released("prevHotBar")
	)

var justHeld=false
#hold given item
func hold(item):
	if item==-1:
		justHeld=true
		heldItem.visible=false
	var data=world.inventory.inventoryData[item]
	if data.name==null:return
	heldItem.visible=true
	heldItem.texture=world.findItemTexture(data)
	heldItem.get_node("Label").text=str(
				world.inventory.inventoryData[item].quantity
			)
	

#slot inputs
func slotInput(item):
	if(curHeld==-1):
		if world.inventory.inventoryData[item].name==null:return
		curHeld=item
		hold(curHeld)
	else:
		world.inventory.swapSlots(curHeld,item)
		hold(curHeld)
		heldItem.visible=false
		justHeld=true
		curHeld=-1


#lets you choose slots in your inventory
func checkInv(e):
	if not e is InputEventMouseButton or not e.pressed:return
	var pos=$ItemList.get_local_mouse_position()
	var itemPos=Vector2i(pos/14)
	if (
		itemPos.y>0&&!world.inventory.toggled||
		itemPos.x>7||
		itemPos.x<0||
		itemPos.y*8+itemPos.x>world.inventory.inventorySize-1):
			#drops held item if holding one
			if curHeld!=-1:
				world.inventory.dropItem(curHeld)
				curHeld=-1;hold(curHeld)
				
			
			return
	slotInput(itemPos.x+itemPos.y*8)

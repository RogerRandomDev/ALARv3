extends CanvasLayer


const basicTextures={
	"EMPTYSLOT":preload("res://world/Tiles/WaterTiles/WaterSource.png")
}
var chosenItem=Sprite2D.new()
func _ready():
	buildMenu()
	add_child(chosenItem)
	world.inventory.connect("updateSlot",updateSlot)


#builds basic setup for inventory
func buildMenu():
	var holder=$ItemList
	for item in world.inventory.inventorySize:
		var slot=TextureRect.new()
		slot.texture=basicTextures.EMPTYSLOT
		slot.ignore_texture_size=true
		slot.custom_minimum_size=Vector2(12,12)
		var count=Label.new()
		count.name="itemCount"
		count.position=Vector2(0,6)
		count.size=Vector2(8,12)
		count.text_direction=Control.TEXT_DIRECTION_RTL
		
		var itemTex=TextureRect.new()
		count.theme=world.itemTheme
		itemTex.ignore_texture_size=true
		itemTex.set_size(Vector2(8,8))
		itemTex.position=Vector2(2,2)
		slot.add_child(itemTex)
		itemTex.name="itemTex"
		holder.add_child(slot)
		slot.add_child(count)


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
#changes which slot is held
func _input(_event):
	if not _event is InputEventKey:return
	match _event.keycode:
		49:world.inventory.holdingSlot=0
		50:world.inventory.holdingSlot=1
		51:world.inventory.holdingSlot=2
		52:world.inventory.holdingSlot=3
		53:world.inventory.holdingSlot=4
		54:world.inventory.holdingSlot=5
		55:world.inventory.holdingSlot=6
		56:world.inventory.holdingSlot=7
	

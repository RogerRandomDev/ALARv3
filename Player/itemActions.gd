extends Node

var root=null
var mineTex=null

func place(id):
	var mPos=root.get_global_mouse_position()
	var c=getChunkAndCell(mPos)
	if world.changeCell(c[0],c[1],id.id):
		world.inventory.reduceSlotBy(id.slotNum,1)
func mine(_id):
	var mPos=root.get_global_mouse_position()
	
	var c=getChunkAndCell(mPos)
	mineTex.global_position=(c[0]*world.chunkSize+c[1])*world.tileSize
	
	if world.mineCell(c):mineTex.visible=true
	else:mineTex.visible=false

func throw(id):
	if !Input.is_action_just_pressed("m1"):return
	var mPos=root.get_global_mouse_position()
	var bomb=world.miscFunctions.fireBomb(
		root.global_position,mPos,id.actionRange)
	bomb.bombType=id.name
	bomb.id=id.id
	world.inventory.reduceSlotBy(id.slotNum,1)
#null action
func empty(_id):return


func getChunkAndCell(mPos):
	var c=world.mapGen.globalToCell(mPos)
	var chunk=c[1]
	var cell=c[0]
	cell.x=cell.x%16;cell.y=cell.y%16;
	cell.x+=int(cell.x<0)*16;cell.y+=int(cell.y<0)*16
	return [chunk,cell]

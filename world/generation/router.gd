extends Node

const mapTiles=preload("res://world/resources/mapTiles.tres")
const font=preload("res://themes/Retro Gaming.ttf")
const itemTheme=preload("res://themes/itemTheme.tres")

var mapGen=load("res://world/generation/mapGeneration.gd").new()
var chunkFiller=load("res://world/generation/chunkFiller.gd").new()
var worldShadows=load("res://world/generation/worldShadows.gd").new()
var dataStore=load("res://world/generation/rawChunkData.gd").new()
var shaderComp=load("res://world/generation/runShader.gd").new()
var fileManager=load("res://world/generation/fileManager.gd").new()

var miscFunctions=load("res://entities/resources/miscActions.gd").new()
var itemActions=load("res://Player/itemActions.gd").new()


var inventory=load("res://Inventory/inventory.gd").new()
var playerInventory=load("res://Inventory/inventoryMenu.tscn").instantiate()
var itemManager=load("res://world/generation/itemManager.gd").new()

var saveName="testing"

var root=null
var chunkHolder=null
var player=null
var biomeList=[]
var renderDistance=3
var chunkSize=16
var tileSize=8
var groundLevel=32
var height = 1024
var exitGame=false
var itemPickupBuffer=0.75;
var explosionForce:int=200

var itemList=[]
#stores item objects to reduce lag to a certain extent
var itemDropStore=[]



const oneUp=Vector2i(0,1)

#block id to what the plant is made of
const plantsByFloor={
	0:[5,6],
	3:[5,5]
}

#the default world gravity
var defaultGravity=Vector2(0,980)

var maxItemStack:int=99
#default number of item objects to preload
var defaultItemStoreCount:int=2500
func _ready():

	itemManager._ready()
	fillBiomeList()
	fileManager._ready()
	mapGen.call_deferred('_ready')
#	worldShadows.call_deferred('_ready')
	shaderComp._ready()
	inventory._ready()
	add_child(mineTimer)
	mineTimer.wait_time=1
	mineTimer.connect("timeout",progressMine)
	add_child(playerInventory)
	var timer=Timer.new()
	add_child(timer)
	timer.start()
	timer.connect("timeout",checkThreads)
func loadItems(toNode):
	for item in defaultItemStoreCount:
		var drop=itemDrop2D.new()
		#why does this crash me
		GameTick.connect("updateItems",drop.checkInRenderDistance)
		itemDropStore.append(drop)
		await get_tree().process_frame
		toNode.add_child(drop)


#loads all the biomes into an array
func fillBiomeList():
	var dir=Directory.new()
	dir.open("res://world/Biomes")
	for biome in dir.get_files():biomeList.append(load("res://world/Biomes/%s"%biome))


#converts cell position to the chunk position
func cellToChunk(cellPos):
	return Vector2i(cellPos/16.)
#removes items from scene that are in the array
func removeItems(items):
	for item in items:
		item.prepFree.call_deferred()


func _notification(what):
	if what==NOTIFICATION_EXIT_TREE:
		exitGame=true
		GameTick.thread.wait_to_finish()
		GameTick.sem.post()
		mapGen.generationThread.wait_to_finish()
		GameTick.genSema.post(1)


#changes cell in given chunk
func changeCell(chunk,cell,id):
	if !mapGen.loadedChunks.has(chunk):return false
	return mapGen.loadedChunks[chunk].changeCell(cell,id)

#handles spawning in the item drop when you break something
func dropItem(globalCell,itemData,place=true,dropping=true):
	if itemData.name=="ERROR_NAME"||itemData.name=="NONE":return
	var item=getItem()
	if dropping:
		var drop=world.itemManager.getDrop(itemData.name)
		var quant=itemData.quantity
		itemData=world.itemManager.getItemData(drop)
		itemData.quantity=quant
	item.buildItem(itemData)
	
	if place:
		item.position=(Vector2(globalCell)+Vector2(0.5,0.5))*tileSize+Vector2(0,6)
	return item

#reparents node to new one
func reparent(node,newParent):
	var originalParent=node.get_parent()
	originalParent.remove_child(node)
	originalParent.add_child(newParent)
	newParent.add_child(node)

var curMining=[]
var mineTimer=Timer.new()
#handles mining for you
func mineCell(c):
	
	if curMining!=c:
		mineTimer.stop()
		itemActions.mineTex.frame=0
		curMining=c
	if mineTimer.is_stopped():
		itemActions.mineTex.frame=0
		mineTimer.start()
	return mapGen.loadedChunks[c[0]].getCellData(c[1]).name!="ERROR"
	
#increase the mine progress
func progressMine():
	itemActions.mineTex.visible=false
	mineTimer.stop()
	var minedItem=mapGen.loadedChunks[curMining[0]].changeCell(curMining[1],-1,false)
	minedItem=itemManager.getDrop(minedItem.name)
	#if the used tool smelts, then it will auto-smelt the drop
	
	if (
		inventory.get_active().id==1&&
		itemManager.canSmelt(minedItem)
		):
			minedItem=itemManager.getItemData(
			itemManager.getItemData(minedItem).SmeltTo)
	
	else:minedItem=itemManager.getItemData(minedItem)
	minedItem.quantity=1
	if minedItem.name=="NONE":return
	dropItem(curMining[1]+curMining[0]*world.chunkSize,minedItem,true,false)

#finds texture for given item
func findItemTexture(itemData):
	if itemData.actionType=="place":return load("res://world/Tiles/%s.png"%itemData.name)
	else:
		return load("res://tools/%s.png"%itemData.name)

#restarts threads if they are found to have crashed
func checkThreads():
	if !mapGen.generationThread.is_alive():
		mapGen.breakNow=true
		mapGen.genSema.post()
		mapGen.generationThread.wait_to_finish()
		mapGen.breakNow=false
		mapGen._prepThreads()
var toStoreChunkEnt={}


func storeEntityToChunk(c,entData):
	if !toStoreChunkEnt.has(c):toStoreChunkEnt[c]=[]
	toStoreChunkEnt[c].append(entData)


#gets item from item store
func getItem():
	var item=itemDropStore.pop_back()
	if item==null:
		var out=itemDrop2D.new();
		GameTick.connect("updateItems",out.checkInRenderDistance)
		root.add_child(out)
		return out
	return item
	

extends Node

const mapTiles=preload("res://world/resources/mapTiles.tres")
const font=preload("res://themes/Retro Gaming.ttf")
const itemTheme=preload("res://themes/itemTheme.tres")

var mapGen=load("res://world/generation/mapGeneration.gd").new()
var chunkFiller=load("res://world/generation/chunkFiller.gd").new()
var oreFiller=load("res://world/generation/oreFill.gd").new()

var worldShadows=load("res://world/generation/worldShadows.gd").new()
var dataStore=load("res://world/generation/rawChunkData.gd").new()
var shaderComp=load("res://world/generation/runShader.gd").new()
var fileManager=load("res://managers/fileManager.gd").new()

var miscFunctions=load("res://entities/resources/miscActions.gd").new()
var itemActions=load("res://Player/itemActions.gd").new()


var inventory=load("res://Inventory/inventory.gd").new()
var playerInventory=load("res://Inventory/inventoryMenu.tscn").instantiate()
var itemManager=load("res://managers/itemManager.gd").new()
var craftingManager=load("res://managers/recipeManager.gd").new()
var saveName="testing"

var root=null
var chunkHolder=null
var entityHolder
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
#stores length of each item when stored in chunkdata
var itemStoreLength=5
#is only true in the game world
var inGame=false


const oneUp=Vector2i(0,1)

var gameVersion=""
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
	process_mode=Node.PROCESS_MODE_ALWAYS
	gameVersion=ProjectSettings.get_setting("global/version")
	itemManager._ready()
	oreFiller._ready()
	craftingManager._ready()
	fillBiomeList()
	fileManager._ready()
	mapGen.call_deferred('_ready')
	worldShadows.call_deferred('_ready')
	shaderComp.call_deferred('_ready')
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
	GameTick.pause=true
	for item in defaultItemStoreCount:
		var drop=itemDrop2D.new()
		#why does this crash me
		GameTick.connect("updateItems",drop.checkInRenderDistance)
		#fixed it by stopping game ticks until loaded
		#i question threading sometimes,
		#and this is the best way to word why
		itemDropStore.append(drop)
		
		if drop.get_parent()==null:toNode.add_child(drop)
	GameTick.pause=false

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

#closes threads to end game
func _notification(what):
	if what==NOTIFICATION_EXIT_TREE:
		fileManager.compilePlayerSave()
		
		exitGame=true
		GameTick.sem.post()
		GameTick.thread.wait_to_finish()
		mapGen.genSema.post()
		mapGen.generationThread.wait_to_finish()
		await mapGen.saveLoadedChunks()
		


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
	if itemData.name=="NONE":
		itemDropStore.push_back(item)
		return
	item.buildItem(itemData)
	if item.get_parent()==null:root.add_child(item)
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
	if typeof(minedItem)!=TYPE_DICTIONARY||minedItem.name=="ERROR":return
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

const typeToPath=[
	"world/Tiles/%s.png",
	"items/tools/%s.png",
	"items/resources/%s.png"
]
#finds texture for given item
func findItemTexture(itemData):
	return itemManager.getItemTexture(itemData)
#loads texture
func loadItemTexture(itemData):
	return load(typeToPath[itemData.location]%itemData.name.replace(" ",""))
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
	

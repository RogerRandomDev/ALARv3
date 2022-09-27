extends Node

const mapTiles=preload("res://world/resources/mapTiles.tres")

var mapGen=load("res://world/generation/mapGeneration.gd").new()
var chunkFiller=load("res://world/generation/chunkFiller.gd").new()
var worldShadows=load("res://world/generation/worldShadows.gd").new()
var dataStore=load("res://world/generation/rawChunkData.gd").new()
var shaderComp=load("res://world/generation/runShader.gd").new()
var fileManager=load("res://world/generation/fileManager.gd").new()

var miscFunctions=load("res://entities/resources/miscActions.gd").new()
var itemActions=load("res://Player/itemActions.gd").new()


var inventory=load("res://Inventory/inventory.gd").new()



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

var itemList=[]

const oneUp=Vector2i(0,1)

#block id to what the plant is made of
const plantsByFloor={
	0:[5,6],
	3:[5,5]
}

#the default world gravity
var defaultGravity=Vector2(0,980)

var maxItemStack:int=99

func _ready():
	fillBiomeList()
	fileManager._ready()
	mapGen._ready()
	worldShadows.call_deferred('_ready')
	shaderComp._ready()
	inventory._ready()
	add_child(mineTimer)
	mineTimer.wait_time=1
	mineTimer.connect("timeout",progressMine)
	


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
		item.prepFree()


func _notification(what):
	if what==NOTIFICATION_EXIT_TREE:
		exitGame=true
		GameTick.thread.wait_to_finish()
		mapGen.generationThread.wait_to_finish()


#changes cell in given chunk
func changeCell(chunk,cell,id):
	if !mapGen.loadedChunks.has(chunk):return false
	return mapGen.loadedChunks[chunk].changeCell(cell,id)

#handles spawning in the item drop when you break something
func dropItem(globalCell,itemData,place=true):
	if itemData.name=="ERROR":return
	var item=itemDrop2D.new()
	item.buildItem(itemData)
	if place:
		item.global_position=(Vector2(globalCell)+Vector2(0.5,0.5))*tileSize+Vector2(0,6)
		root.add_child(item)
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
	if mineTimer.is_stopped():mineTimer.start()
	return mapGen.loadedChunks[c[0]].getCellData(c[1]).name!="ERROR"
	
#increase the mine progress
func progressMine():
	itemActions.mineTex.visible=false
	mineTimer.stop()
	mapGen.loadedChunks[curMining[0]].changeCell(curMining[1],-1)


#finds texture for given item
func findItemTexture(itemData):
	if itemData.actionType=="place":return load("res://world/Tiles/%s.png"%itemData.name)
	else:
		return load("res://tools/%s.png"%itemData.name)

extends Node


var thread=Thread.new()
var sem=Semaphore.new()
var tickCount:int=0
func _ready():
	thread.start(tickThread)
signal updateItems()
var rlX=0
var rrX=0
var rtY=0
var rbY=0
func tickThread():
	while true:
		if world.exitGame:break
		sem.wait()
		if world.exitGame:break
		compute()
		miscActions()
		updateItemSignal()
var computing=false
func compute():
		
		var storeChunks=world.mapGen.loadedChunks.duplicate()
		var storeCenter=world.mapGen.centerChunk
		world.shaderComp.input_data=world.dataStore.compileChunks()
		world.shaderComp.input_data.append(tickCount)
		var output=world.shaderComp.runCompute()
		computing=true
		var modBy=storeCenter-Vector2i(world.renderDistance,world.renderDistance)
		for cX in 49:
			var newChunk=[]
			var c=(Vector2i(int(cX/7),cX%7)+modBy)
			var temp=cX%7*1792+int(cX/7)*16
			for y in 16:newChunk.append_array(output.slice(y*112+temp,y*112+16+temp))
			if(world.mapGen.loadedChunks[c]==storeChunks[c]):
				storeChunks[c].fill([newChunk,[]],true)
		computing=false
		
		tickCount+=1
		if tickCount>128397:tickCount=0;

var miscStored=[]
#stored action for miscAction
func storeAction(requester,action,data):
	miscStored.append([requester,action,data])



#miscactions handles things such as explosions for me
#very nice and convenient to do here, since it won't collide
#and it does it at a consistent pace
func miscActions():
	computing=true
	for action in len(miscStored):
		var act=miscStored[action]
		doCallBack(act[1],act[2])
		miscStored.remove_at(action)
	computing=false
	#handles the storing entities outside the chunk
#	for chunk in world.toStoreChunkEnt:
#		world.fileManager.openChunkFile(chunk)
#		var fullData=world.fileManager.getFullChunk(chunk)
#		if fullData==null:fullData=[world.chunkFiller.buildChunkData(chunk,false),[]]
#		fullData[1].append_array(world.toStoreChunkEnt[chunk])
#		world.fileManager.storeFullChunk(chunk,fullData)
#		world.fileManager.closeChunkFile(chunk)
#		world.toStoreChunkEnt.erase(chunk)

func doCallBack(callBack,data):
	match len(data):
		0:return callBack.call()
		1:return callBack.call(data[0])
		2:return callBack.call(data[0],data[1])
		3:return callBack.call(data[0],data[1],data[2])
		4:return callBack.call(data[0],data[1],data[2],data[3])
		5:return callBack.call(data[0],data[1],data[2],data[3],data[4])
	


func nextTick():
	sem.post()
	

func loadTicks():
	$TickTimer.start()

#prevents orphaned item nodes
func updateItemSignal():
	rlX=(world.mapGen.centerChunk.x-world.renderDistance)*world.chunkSize*world.tileSize
	rrX=(world.mapGen.centerChunk.x+world.renderDistance)*world.chunkSize*world.tileSize
	rtY=(world.mapGen.centerChunk.y-world.renderDistance)*world.chunkSize*world.tileSize
	rbY=(world.mapGen.centerChunk.y+world.renderDistance)*world.chunkSize*world.tileSize
	emit_signal.call_deferred("updateItems")

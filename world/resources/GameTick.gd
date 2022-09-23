extends Node


var thread=Thread.new()
var sem=Semaphore.new()
var tickCount:int=0
func _ready():
	thread.start(tickThread)


func tickThread():
	while true:
		if world.exitGame:break
		sem.wait()
		if world.exitGame:break
		compute()
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
				storeChunks[c].fill([newChunk,[]])
				world.dataStore.chunkData[c]=[newChunk,[]]
		computing=false
		tickCount+=1
		if tickCount>128397:tickCount=0;
func nextTick():
	sem.post()
	

func loadTicks():
	$TickTimer.start()

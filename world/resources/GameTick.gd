extends Node


var thread=Thread.new()
var sem=Semaphore.new()
var tickCount:int=0
func _ready():
	thread.start(tickThread)


func tickThread():
	while true:
		sem.wait()
		compute()
var computing=false
func compute():
		
		var storeChunks=world.mapGen.loadedChunks.duplicate()
		var storeCenter=world.mapGen.centerChunk
		world.shaderComp.input_data=world.dataStore.compileChunks()
		world.shaderComp.input_data.append(tickCount)
		var output=world.shaderComp.runCompute()
		computing=true
		for cX in 7:for cY in 7:
			var modBy=storeCenter-Vector2i(world.renderDistance,world.renderDistance)
			var newChunk=[]
			var c=(Vector2i(cX,cY)+modBy)
			var temp=cY*1792+cX*16
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

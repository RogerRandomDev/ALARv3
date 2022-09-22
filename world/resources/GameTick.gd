extends Node


var thread=Thread.new()
var sem=Semaphore.new()
func _ready():
	thread.start(tickThread)


func tickThread():
	while true:
		sem.wait()
		compute()
var computing=false
func compute():
		computing=true
		world.shaderComp.input_data=world.dataStore.compileChunks()
		
		var output=world.shaderComp.runCompute("updateWater")
		
		
		for cX in 7:for cY in 7:
			var modBy=world.mapGen.centerChunk-Vector2i(world.renderDistance,world.renderDistance)
			var newChunk=[]
			var c=(Vector2i(cX,cY)+modBy)
			
			for y in 16:
				newChunk.append_array(
					output.slice(
						y*112+cY*1792+cX*16,y*112+16+cY*1792+cX*16
					))
			
			world.mapGen.loadedChunks[c].fill([newChunk,[]])
			world.dataStore.chunkData[c]=[newChunk,[]]
		computing=false
func nextTick():
	sem.post()


func loadTicks():
	$TickTimer.start()

extends Node

var generationThread:=Thread.new()
var genSema=Semaphore.new()

var loadedChunks={}

var centerChunk=Vector2i(100000,1000000)
var threadedCenter=Vector2i.ZERO

var globalChunkData={}





#builds current chunks to read
func getChunksToRead():
	var validSpots=[]
	var i=0;
	validSpots.resize((world.renderDistance*2+1)*(world.renderDistance*2+1))
	for x in range(threadedCenter.x-world.renderDistance,threadedCenter.x+world.renderDistance+1):
		for y in range(threadedCenter.y-world.renderDistance,threadedCenter.y+world.renderDistance+1):
			validSpots[i]=Vector2i(x,y)
			i+=1
	return validSpots

#builds single chunk
func generateChunk(chunkPos,removedChunks=[]):
	var chunk
	#calls if you need to build a new chunk
	if removedChunks.size()==0:
		chunk=chunk2D.new()
		chunk.set_deferred('tile_set',world.mapTiles)
		world.chunkHolder.call_deferred('add_child',chunk)
		
	#otherwise just uses an already made chunk and sets new data in it
	else:
		chunk=loadedChunks[removedChunks[removedChunks.size()-1]]
		loadedChunks.erase(chunk._pos)
	loadedChunks[chunkPos]=chunk
	chunk._pos=chunkPos
	chunk.position=chunkPos*world.tileSize*world.chunkSize
	
	#uses already made data if it is there
	#otherwise it creates the new chunk
	var chunkData=world.dataStore.getChunk(chunkPos)
	if chunkData==null:chunkData=world.chunkFiller.buildChunkData(chunkPos)
#	chunk.fill(chunkData)
	removedChunks.pop_back()
	return [removedChunks,chunkData]


#builds the chunks for the map
func buildChunks():
	while true:
		
		genSema.wait()
		threadedCenter=centerChunk
		var validSpots=getChunksToRead()
		var lKeys=loadedChunks.keys()
		var needChunks=validSpots.filter(func(cPos):return !lKeys.has(cPos))
		var removeChunks=loadedChunks.keys().filter(func(cPos):return !validSpots.has(cPos))
		#removes chunks outside of range
		for chunk in removeChunks:
			loadedChunks[chunk].call_deferred('prepForRemoval')
			world.dataStore.removeChunk(chunk)
		#builds new needed chunks
		for chunk in needChunks:
			var dat=generateChunk(chunk,removeChunks)
			removeChunks=dat[0]
			world.dataStore.addChunk(chunk,dat[1])
		#loads the shadows
#		world.worldShadows.call_deferred("loadShadows",loadedChunks.duplicate(),centerChunk)
		world.shaderComp.input_data=world.dataStore.compileChunks()
		compute()
func compute():
		
		
		var output=world.shaderComp.runCompute("updateWater")
		var sorted=loadedChunks.keys()
		sorted.sort_custom(func(a,b):return a.x<b.x||a.y<b.y)
		for chunk in len(sorted):
			var modifiedChunkData=[]
			
			for y in 16:
				modifiedChunkData.append_array(output.slice(chunk*16,chunk*16 + 16))
			loadedChunks[sorted[chunk]].fill([modifiedChunkData,[]])


#does basic thread prep for use
func _prepThreads():
	generationThread.start(buildChunks)

#prepares basic needs for map generation
func _ready():
	_prepThreads()


func moveCurrentChunk(newCurChunk):
	if centerChunk==newCurChunk:return
	centerChunk=newCurChunk
	
	genSema.post()




#converts global position to chunk position
func globalToChunk(globalPos):
	globalPos=Vector2i(globalPos/world.tileSize)
	globalPos-=Vector2i(int(globalPos.x<0),int(globalPos.y<0))*world.chunkSize
	globalPos.x-=globalPos.x%world.chunkSize;globalPos.y-=globalPos.y%world.chunkSize
	return globalPos/world.chunkSize







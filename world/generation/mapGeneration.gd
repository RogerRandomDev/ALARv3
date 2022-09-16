extends Node

var generationThread:=Thread.new()
var genSema=Semaphore.new()

var loadedChunks={}

var centerChunk=Vector2i(100000,1000000)




#builds current chunks to read
func getChunksToRead():
	var validSpots=[]
	var i=0;
	validSpots.resize((world.renderDistance*2+1)*(world.renderDistance*2+1))
	for x in range(centerChunk.x-world.renderDistance,centerChunk.x+world.renderDistance+1):
		for y in range(centerChunk.y-world.renderDistance,centerChunk.y+world.renderDistance+1):
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
	
	chunk.set_deferred('position',chunkPos*world.tileSize*world.chunkSize)
	
	
	var chunkData=world.chunkFiller.buildChunkData(chunkPos)
	chunk.fill(chunkData)
	removedChunks.pop_back()
	return [removedChunks,0]
	
#builds the chunks for the map
func buildChunks():
	while true:
		
		genSema.wait()
		var validSpots=getChunksToRead()
		var lKeys=loadedChunks.keys()
		var needChunks=validSpots.filter(func(cPos):return !lKeys.has(cPos))
		var removeChunks=loadedChunks.keys().filter(func(cPos):return !validSpots.has(cPos))
		var chunkData=[]
		#removes chunks outside of range
		for chunk in removeChunks:
			loadedChunks[chunk].call_deferred('prepForRemoval')
		#builds new needed chunks
		for chunk in needChunks:
			var dat=generateChunk(chunk,removeChunks)
			removeChunks=dat[0]
			chunkData.push_back(dat[1])
	
		#loads the shadows
		
		world.worldShadows.loadShadows(loadedChunks.duplicate(),centerChunk)
		


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






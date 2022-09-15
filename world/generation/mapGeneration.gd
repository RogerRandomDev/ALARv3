extends Node

var generationThread:=Thread.new()
var genSema=Semaphore.new()

var loadedChunks={}

var centerChunk=Vector2i(100000,1000000)




#builds current chunks to read
func getChunksToRead():
	var validSpots=[]
	for x in range(centerChunk.x-world.renderDistance,centerChunk.x+world.renderDistance+1):
		for y in range(centerChunk.y-world.renderDistance,centerChunk.y+world.renderDistance+1):
			validSpots.append(Vector2i(x,y))
	return validSpots

#builds single chunk
func generateChunk(chunkPos,removedChunks=[]):
	var chunk
	#calls if you need to build a new chunk
	if removedChunks.size()==0:
		chunk=chunk2D.new()
		chunk.tile_set=world.mapTiles
		world.chunkHolder.call_deferred('add_child',chunk)
		
	#otherwise just uses an already made chunk and sets new data in it
	else:
		chunk=loadedChunks[removedChunks[removedChunks.size()-1]]
		loadedChunks.erase(chunk._pos)
	loadedChunks[chunkPos]=chunk
	chunk._pos=chunkPos
	
	chunk.position=chunkPos*world.tileSize*world.chunkSize
	
	
	var chunkData=world.chunkFiller.buildChunkData(chunkPos)
	chunk.fill(chunkData)
	removedChunks.pop_back()
	return removedChunks
	
#builds the chunks for the map
func buildChunks():
	while true:
		
		genSema.wait()
		var validSpots=getChunksToRead()
		var needChunks=validSpots.filter(func(cPos):return !loadedChunks.keys().has(cPos))
		var removeChunks=loadedChunks.keys().filter(func(cPos):return !validSpots.has(cPos))
		#removes chunks outside of range
		for chunk in removeChunks:
			loadedChunks[chunk].call_deferred('prepForRemoval')
		#builds new needed chunks
		for chunk in needChunks:removeChunks=generateChunk(chunk,removeChunks)



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






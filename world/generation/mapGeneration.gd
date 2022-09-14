extends Node

var generationThread:=Thread.new()
var genSema=Semaphore.new()

var loadedChunks={}

var centerChunk=Vector2i.ZERO




#builds current chunks to read
func getChunksToRead():
	var validSpots=[]
	for x in range(centerChunk.x-world.renderDistance,centerChunk.x+world.renderDistance+1):
		for y in range(centerChunk.y-world.renderDistance,centerChunk.y+world.renderDistance+1):
			validSpots.append(Vector2i(x,y))
	return validSpots

#builds single chunk
func generateChunk(chunkPos):
	var chunk=chunk2D.new()
	loadedChunks[chunkPos]=chunk
	chunk._pos=chunkPos
	chunk.tile_set=world.mapTiles
	chunk.position=chunkPos*world.tileSize*world.chunkSize
	world.chunkHolder.call_deferred('add_child',chunk)
	
	var chunkData=world.chunkFiller.buildChunkData(chunkPos)
	chunk.fill(chunkData)

#builds the chunks for the map
func buildChunks():
	while true:
		
		genSema.wait()
		var validSpots=getChunksToRead()
		var needChunks=validSpots.filter(func(cPos):return !loadedChunks.keys().has(cPos))
		var removeChunks=loadedChunks.keys().filter(func(cPos):return !validSpots.has(cPos))
		#removes chunks outside of range
		for chunk in removeChunks:
			loadedChunks[chunk].prepForRemoval()
			loadedChunks.erase(chunk)
		#builds new needed chunks
		for chunk in needChunks:generateChunk(chunk)



#does basic thread prep for use
func _prepThreads():
	generationThread.start(buildChunks)

#prepares basic needs for map generation
func _ready():
	_prepThreads()


func moveCurrentChunk(newCurChunk):
	centerChunk=newCurChunk
	genSema.post()









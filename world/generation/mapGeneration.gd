extends Node

var generationThread:=Thread.new()
var genSema=Semaphore.new()

var loadedChunks={}

var centerChunk=Vector2i(100000,1000000)
var threadedCenter=Vector2i.ZERO

var globalChunkData={}
signal chunksLoaded




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

var unusedChunks=[]
#builds single chunk
func generateChunk(chunkPos):
	var chunk=unusedChunks.pop_back()
	if chunk==null:
		chunk=chunk2D.new()
		chunk.tile_set=world.mapTiles
		world.chunkHolder.call_deferred('add_child',chunk)
	else:chunk.clear()
	loadedChunks[chunkPos]=chunk
	chunk._pos=chunkPos
	chunk.position=chunkPos*world.tileSize*world.chunkSize
	
	#uses already made data if it is there
	#otherwise it creates the new chunk
	var fileData=world.fileManager.getFullChunk(chunkPos)
	
	if fileData==null:fileData=[null,[]]
	var chunkData=fileData[0]
	
	if chunkData==null:chunkData=world.chunkFiller.buildChunkData(chunkPos,false)
	chunk.originalData=chunkData
	world.dataStore.chunkData[chunk]=chunkData
	
	if !GameTick.computing:
		chunk.fill(chunkData)
	chunk.fillEntities.call_deferred(fileData[1])
	return chunkData

var computing=false
var breakNow=false
#builds the chunks for the map
func buildChunks():
	while true:
		
		if world.exitGame||breakNow:break
		genSema.wait()
		if world.exitGame||breakNow:break
		computing=true
		threadedCenter=centerChunk
		var validSpots=getChunksToRead()
		var lKeys=loadedChunks.keys()
		var needChunks=validSpots.filter(func(cPos):return !lKeys.has(cPos))
		var removeChunks=loadedChunks.keys().filter(func(cPos):return !validSpots.has(cPos))
		#gets items by chunk
		var itemsByChunk={}
		for c in loadedChunks.keys():itemsByChunk[c]=[[],[]]
		for item in world.itemList:
			var c=item.getChunk()
			if !itemsByChunk.has(c):continue
			var data=item.storageFormat()
			var pos=globalToCell(item.position)[0]
			data.append(pos.x);data.append(pos.y)
			itemsByChunk[c][0].append_array(data)
			itemsByChunk[c][1].append(item)
		#removes chunks outside of range
		for chunk in removeChunks:
			
			loadedChunks[chunk].prepForRemoval()
			unusedChunks.push_back(loadedChunks[chunk])
			#handles items first
			if itemsByChunk.has(chunk):
				world.dataStore.entityData[chunk]=itemsByChunk[chunk][0]
				
				world.removeItems(itemsByChunk[chunk][1])
			#removes chunk from local, and checks if you have modified it at all
			#so it only saves modified chunks
			world.dataStore.removeChunk(chunk,
			(loadedChunks[chunk].originalData!=world.dataStore.chunkData[chunk]||
			itemsByChunk.has(chunk))
			)
			loadedChunks.erase(chunk)
			
			await world.fileManager.closeChunkFile(chunk)
		#builds new needed chunks
		for chunk in needChunks:
			world.fileManager.openChunkFile(chunk)
			world.dataStore.addChunk(chunk,generateChunk(chunk))
		
		#loads the shadows
#		world.worldShadows.call_deferred("loadShadows",loadedChunks.duplicate(),centerChunk)
		computing=false
		emit_signal.call_deferred("chunksLoaded")

#saves chunks even if they aren't being removed
func saveLoadedChunks():
	var removeChunks=loadedChunks.keys()
	#gets items by chunk
	var itemsByChunk={}
	for c in loadedChunks.keys():itemsByChunk[c]=[[],[]]
	for item in world.itemList:
		var c=item.getChunk()
		if !itemsByChunk.has(c):continue
		var data=item.storageFormat()
		var pos=globalToCell(item.position)[0]
		data.append(pos.x+pos.y*16)
		itemsByChunk[c][0].append_array(data)
		itemsByChunk[c][1].append(item)
	#removes chunks outside of range
	for chunk in removeChunks:
		#handles items first
		if itemsByChunk.has(chunk):
			world.dataStore.entityData[chunk]=itemsByChunk[chunk][0]
			
			world.removeItems(itemsByChunk[chunk][1])
		#removes chunk from local, and checks if you have modified it at all
		#so it only saves modified chunks
		await world.dataStore.removeChunk(chunk,true)
		
		world.fileManager.closeChunkFile(chunk)
		
	return true

#does basic thread prep for use
func _prepThreads():
	generationThread.start(buildChunks)

#prepares basic needs for map generation
func _ready():
	_prepThreads()

#updates the world gen origin chunk
func moveCurrentChunk(newCurChunk):
	if GameTick.computing:return
	if centerChunk==newCurChunk:return
	centerChunk=newCurChunk
	
	genSema.post()




#converts global position to chunk position
func globalToChunk(globalPos):
	globalPos=Vector2i(globalPos/world.tileSize)
	globalPos-=Vector2i(int(globalPos.x<0),int(globalPos.y<0))*world.chunkSize
	globalPos.x-=globalPos.x%world.chunkSize;globalPos.y-=globalPos.y%world.chunkSize
	return globalPos/world.chunkSize

#converts global to cell pos
func globalToCell(globalPos):
	var cell=Vector2i(globalPos/8.)
	var chunk=Vector2i(globalPos/8./16.)
	cell-=Vector2i(int(globalPos.x<0),int(globalPos.y<0))
	chunk-=Vector2i(int(globalPos.x<0),int(globalPos.y<0))
	cell=cell-chunk*16
	return [cell,chunk]


#lets you modify an unloaded chunk
func modifyUnloaded(chunkPos,data):
	world.fileManager.openChunkFile(chunkPos)
	var fullData=world.fileManager.getFullChunk(chunkPos)
	var chunkData
	var entData=[]
	if fullData==null:fullData=[world.chunkFiller.buildChunkData(chunkPos,false),[]]
	chunkData=fullData[0]
	entData=fullData[1]
	
	for c in float(len(data))/2:
		
		var cell=data[c*2]
		var id=chunkData[cell.x+cell.y*16]
		if chunkData[cell.x+cell.y*16]<0:continue
		var source=world.mapTiles.get_source(id)
		var cellData=source.get_tile_data(Vector2i.ZERO,0)
		if(cellData.get_custom_data("unmineable")||
		cellData.get_custom_data("ExplosionProof")||
		source.get("name")==null):continue
		#full item building
		#it's many layers but is very good at it's job
		var dropItem=world.itemManager.compressToStorage(
			world.itemManager.getItemData(
			world.itemManager.getDrop(source.get("name"))
			))
		if dropItem!="NONE":
			dropItem.append(cell.x+cell.y*16)
			entData.append_array(dropItem)
		
		chunkData[cell.x+cell.y*16]=-1
	
	
#	world.fileManager.storeFullChunk(chunkPos,[chunkData,fullData[1]])
	world.fileManager.storeFullChunk(chunkPos,[chunkData.duplicate(),entData])
	await world.fileManager.closeChunkFile(chunkPos)



func getCellData(id):
	var raw=world.mapTiles.get_source(id)
	var cellData={
		"texture":raw.get("texture"),
		"name":raw.get("resource_name"),
		"id":id,
		"actionType":"place",
		"actionRadius":0
	}
	cellData.weight=1
	cellData.quantity=1
	return world.dropItem(Vector2(0,0),cellData,false).storageFormat()


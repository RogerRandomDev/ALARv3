extends Node

var chunkFiles={}
var activeChunks=[]
var clusterBuffers={}

var unusedChunkFiles=[]
var dir=Directory.new()
var allSaves=[]

func _ready():
	allSaves=getSaveList()
#gets the chunk cluster vector
func getChunkCluster(chunk):
	var c=chunk
	c.x-=int(chunk.x<0)*5;c.y-=int(chunk.y<0)*5
	return Vector2i(c/6)

#returns list of saves for you
func getSaveList():
	var out=[]
	dir.open("user://Saves")
	
	var dirs=dir.get_directories()
	var file=File.new()
	for dirN in dirs:
		file.open("user://Saves/%s/Misc/menuData.dat"%dirN,File.READ)
		out.append(str_to_var(file.get_as_text()))
		file.close()
	return out


#creates new save file for you
func createNewSave(saveName,_seed):
	if !dir.dir_exists("user://Saves/%s/chunks"%saveName):
		dir.make_dir_recursive("user://Saves/%s/chunks"%saveName)
		dir.make_dir_recursive("user://Saves/%s/Player"%saveName)
		dir.make_dir_recursive("user://Saves/%s/Misc"%saveName)
		var file=File.new()
		file.open("user://Saves/%s/Misc/menuData.dat"%saveName,File.WRITE)
		var out=[]
#		OS.execute('date',PackedStringArray(["+%d-%m-%y"]),out,true)
		out=["1-1-1"]
		file.seek(0)
		file.store_line(var_to_str(
			[saveName,
			_seed,
			out[0].replace("-","/").replace("\n","")
			]
		))
		file.close()
	else:return false
	return true
#removes recursively the given directory
func remove_recursive(path):
	var directory = Directory.new()
	
	# Open directory
	var error = directory.open(path)
	if error == OK:
		# List directory content
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while file_name != "":
			if directory.current_is_dir():
				remove_recursive(path + "/" + file_name)
			else:
				directory.remove(file_name)
			file_name = directory.get_next()
		
		# Remove current path
		directory.remove(path)
	else:
		print("Error removing " + path)
#gets menu data for the chosen world save
func getWorldData(worldName):
	var file=File.new()
	file.open("user://Saves/%s/Misc/menuData.dat"%worldName,File.READ)
	var out=str_to_var(file.get_as_text())
	file.close()
	return out
func loadWorld(worldName):
	var file=File.new()
	var path="user://Saves/%s/"%worldName
	if !file.file_exists("%sPlayer/PlayerData.dat"%path):
		file.open("%sPlayer/PlayerData.dat"%path,File.WRITE)
		file.close()
	else:
		file.open("%sPlayer/PlayerData.dat"%path,File.READ_WRITE)
		var data=str_to_var(file.get_as_text())
		if data==null:return
		world.player.canMove=false
		world.player.global_position=data.cellPos*8-Vector2i(0,32)
		world.inventory.buildFromStorage(data.inventory)
		var myChunk=world.mapGen.globalToChunk(world.player.global_position)
		world.mapGen.moveCurrentChunk(myChunk)
		await world.mapGen.chunksLoaded
		world.player.canMove=true
#compiles save data for the player
func compilePlayerSave():
	var data={
		"cellPos":Vector2i(world.player.global_position/8.),
		"inventory":world.inventory.convertToStorage()
	}
	var file=File.new()
	var path="user://Saves/%s/"%world.saveName
	file.open("%sPlayer/PlayerData.dat"%path,File.READ_WRITE)
	file.seek(0)
	file.store_line(var_to_str(data))
	file.close()



#main game from here
func openChunkFile(chunk):
	
	var n=getChunkCluster(chunk)
	if (chunk.y>40||chunk.y<-10)||chunkFiles.has(n):return
	activeChunks.append(chunk)
	
	var path="user://Saves/%s/chunks/%s.nfts"%[world.saveName,str(n)]
	var file=File.new()
	var bufferData=null
	if !dir.file_exists(path):
		file.open(path,File.WRITE_READ)
		bufferData=PackedByteArray()
		bufferData.resize(72)
	else:
		file.open(path,File.READ_WRITE)
		bufferData=file.get_buffer(
			file.get_length()
		)
	if !clusterBuffers.has(n):clusterBuffers[n]=bufferData
	chunkFiles[n]=file
	

#cuts chunk out of cluster buffer
#and then returns it and the two split parts without it
func cutChunkFromBuffer(chunk):
	
	var n=getChunkCluster(chunk)
	if !clusterBuffers.has(n):return
	var bufferSlot=getSpotInBuffer(chunk)
	var myBuffer=clusterBuffers[n]
	var mySize=(
		myBuffer[bufferSlot*2]+
		myBuffer[bufferSlot*2+1]*256
	)
	var distanceToMine=0
	var secondByte=true
	Array(
		myBuffer.slice(0,bufferSlot*2)
		).map(func(e):
			secondByte=!secondByte
			distanceToMine+=e*((255*int(secondByte))+1)
			)
	distanceToMine=int(distanceToMine)
	return [
		myBuffer.slice(
			distanceToMine+72,
			distanceToMine+72+mySize
		),
		[
			myBuffer.slice(0,distanceToMine+72),
			myBuffer.slice(distanceToMine+72+mySize)
		],
	]



func closeChunkFile(chunk):
	if !activeChunks.has(chunk):return
	activeChunks.erase(chunk)
	var myCluster=getChunkCluster(chunk)
	if (
		activeChunks.any(
			func(pos):getChunkCluster(pos)-myCluster==Vector2i.ZERO
		)||
		!chunkFiles.has(myCluster)
	):return
	#await makes sure this is completed before it continues with the rest
	chunkFiles[myCluster].seek(0)
	chunkFiles[myCluster].store_buffer(clusterBuffers[myCluster])
	chunkFiles[myCluster].close()
	clusterBuffers.erase(myCluster)
	chunkFiles.erase(myCluster)
	




#stores entire chunk worth of data
func storeFullChunk(chunk,data):
	var newData=compressChunkData(data)
	var bufferData=cutChunkFromBuffer(chunk)
	
	if bufferData==null:return
	
	var bufferSlot=getSpotInBuffer(chunk)
	bufferData[1][0][bufferSlot*2]=len(newData)%256
	bufferData[1][0][bufferSlot*2+1]=int(len(newData)/256)
	var newDataOut=bufferData[1][0]
	newDataOut.append_array(newData)
	newDataOut.append_array(bufferData[1][1])
	clusterBuffers[getChunkCluster(chunk)]=(
		newDataOut
	)
	
	
	
	
	

#inserts data into chunk cluster
func insertChunkToFile(chunk,data):
	pass
#pulls chunk data from the chunk cluster file
func getChunkFromFile(chunk):
	pass

#gets the entire chunk's data
func getFullChunk(chunk):
	var rawInput=cutChunkFromBuffer(chunk)
	if rawInput==null:return
	var out=decompressChunkData(rawInput[0])
	return out
#loads the chunk data only if it is available
func loadFullChunk(chunk):
	var out=getFullChunk(chunk)
	if out==null:return
	world.dataStore.chunkData[chunk]=out[0]
#	world.dataStore.entityData[chunk]=out[1]
	
#opens chunk temporarily




#compression of a chunk for storing

#gets what spot in the storage buffer this chunk is
func getSpotInBuffer(chunk):
	var n=getChunkCluster(chunk)*6
	
	return chunk.x-n.x+(chunk.y-n.y)*6

#if you have problems with blocks and items being wrong later
#its the (e-256)/256 part
#change it to 255 on one or both and it should be fixed
func compressChunkData(chunkData):
	#handles cell tiles first, 512 bytes of them
	var out=PackedByteArray(
		chunkData[0].map(func(e):e%256
		))
	out.append_array(
			chunkData[0].map(func(e):int((e-255)/256))
		#now it goes through entities
		)
	out.append_array(
			chunkData[1]
		#stores entity data length for decompression reasons
		)
	out.append_array(
			[
				len(chunkData[1])%256,
				int((len(chunkData[1])-255)/256)
			]
		)
	return out.compress(2)


#decompression of a chunk for use
func decompressChunkData(chunkData):
	var length=len(chunkData)-1
	if length<1:return
	var decompSize=chunkData[length-1]+chunkData[length]*256
	chunkData.resize(len(chunkData)-2)
	
	var newChunkData=chunkData.decompress(decompSize,2)
	var blockData=[]
	var i=0;
	while i<256:
		blockData.append(
			(newChunkData[i]+newChunkData[i+256]*256)*
			int(newChunkData[i+256]<253)
			
		)
		i+=1
	return [
		blockData,
		[]
		]



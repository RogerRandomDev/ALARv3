extends Node

#var chunkFiles={}
var activeChunks={}
var clusterBuffers={}
var clusterFiles={}
var clusterStore={}
var unusedChunkFiles=[]
var dir=Directory.new()
var allSaves=[]
var emptyBuffer=PackedByteArray()

func _ready():
	emptyBuffer.resize(72)
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
#returns the file object for the given chunk
func getChunkFile(chunk):
	var path="user://Saves/%s/chunks/%s.nfts"%[world.saveName,str(getChunkCluster(chunk))]
	var file=File.new();file.open(path,File.READ_WRITE)
	return file

#main game from here
func openChunkFile(chunk):
	
	var n=getChunkCluster(chunk)
	activeChunks[chunk]=n
	if (chunk.y>40||chunk.y<-10)||clusterBuffers.has(n):return
	var path="user://Saves/%s/chunks/%s.nfts"%[world.saveName,str(n)]
	var file=File.new()
	if !dir.file_exists(path):
		file.open(path,File.WRITE_READ)
		file.store_buffer(emptyBuffer)
		clusterBuffers[n]=PackedByteArray()
		clusterBuffers[n].resize(72)
	else:
		file.open(path,File.READ_WRITE)
		clusterBuffers[n]=file.get_buffer(
			file.get_length()
		)
	clusterFiles[n]=file
	

#cuts chunk out of cluster buffer
#and then returns it and the two split parts without it
func cutChunkFromBuffer(chunk):
	pass


func closeChunkFile(chunk):
	var n=activeChunks[chunk]
	if activeChunks.has(chunk):activeChunks.erase(chunk)
	if activeChunks.values().has(n):return
	saveClusterBuffer(n)
#saves a cluster buffer to file
func saveClusterBuffer(cluster):
	clusterFiles[cluster].store_buffer(clusterBuffers[cluster])
	clusterFiles[cluster].close()
	clusterFiles.erase(cluster)
	clusterBuffers.erase(cluster)

func getClusterPosition(chunk):
	var n=getChunkCluster(chunk)
	var clusterPos=getSpotInBuffer(chunk)
	var outPos=0;var i=0;
	while i<clusterPos:
		outPos+=clusterBuffers[n][i*2]+clusterBuffers[n][i*2+1]*256
		i+=1
	return [
		outPos+72,
		clusterBuffers[n][clusterPos*2]+clusterBuffers[n][clusterPos*2+1]*256
	]


#stores entire chunk worth of data
func storeFullChunk(chunk,data):
	var n=getChunkCluster(chunk)
	if !clusterBuffers.has(n):return
	var startingCluster=clusterBuffers[n]
	var cutAt=getClusterPosition(chunk)
	

func getFromCluster(chunk):
	return []
	
#gets the entire chunk's data
func getFullChunk(chunk):
	if !activeChunks.has(chunk):return
	var curAt=getClusterPosition(chunk)
	if curAt[1]==0:return
	#doesn't return the actual chunk data yet
	#need to do that still
	#add 72 to the numbers to account for the front byte buffer
	var out=[]
	out=null
	return out

#loads the chunk data only if it is available
func loadFullChunk(chunk):
	var out=getFullChunk(chunk)
	if out==null:return
	world.dataStore.chunkData[chunk]=out[0]
	world.dataStore.entityData[chunk]=[]
	
#opens chunk temporarily




#gets what spot in the storage buffer this chunk is
func getSpotInBuffer(chunk):
	var n=getChunkCluster(chunk)*6
	
	return chunk.x-n.x+(chunk.y-n.y)*6

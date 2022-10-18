extends Node

var chunkFiles={}
var unusedChunkFiles=[]
var dir=Directory.new()
var allSaves=[]

func _ready():
	allSaves=getSaveList()
#gets the chunk cluster vector
func getChunkCluster(chunk):
	var c=chunk
	c.x-=int(chunk.x<0)*7;c.y-=int(chunk.y<0)*7
	return Vector2i(c/8)

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
		OS.execute('date',PackedStringArray(["+%d-%m-%y"]),out,true)
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
	if(chunkFiles.has(chunk))||chunk.y>40||chunk.y<-10:return
	var path="user://Saves/%s/chunks/%s.nfts"%[world.saveName,str(n)]
	var file=File.new()
	if !dir.file_exists(path):
		file.open(path,File.WRITE_READ)
	else:
		file.open(path,File.READ_WRITE)
	chunkFiles[chunk]=file
	


func closeChunkFile(chunk):
	if !chunkFiles.has(chunk):return
	chunkFiles[chunk].close()
	chunkFiles.erase(chunk)




#stores entire chunk worth of data
func storeFullChunk(chunk,data):
	if !chunkFiles.has(chunk)||chunk.y>40||chunk.y<-10:return
	chunkFiles[chunk].seek(0)
#	chunkFiles[chunk].store_pascal_string(compressChunkData(data))
	var compressed=compressChunkData(data,chunk)
	insertChunkToFile(chunk,compressed)
	

#inserts data into chunk cluster
func insertChunkToFile(chunk,data):
	var start=str_to_var(chunkFiles[chunk].get_buffer(
		chunkFiles[chunk].get_length()
	).get_string_from_ascii())
	if start==null:start={}
	start[chunk]=data.hex_encode()
	chunkFiles[chunk].seek(0)
	var buff=var_to_str(start).to_ascii_buffer()
	var out=buff.compress(2)
	
	out.append_array([len(buff)%256,int(len(buff)/256)])
	chunkFiles[chunk].store_buffer(out)
#pulls chunk data from the chunk cluster file
func getChunkFromFile(chunk):
	var start=chunkFiles[chunk].get_buffer(
			chunkFiles[chunk].get_length()
		)
	
	var leng=((start[len(start)-2])+(start[len(start)-1])*256)
	start.resize(len(start)-2)
	start=str_to_var(start.decompress(leng,2).get_string_from_ascii())
	if !start.has(chunk):return null
	var out=start[chunk];var finOut=PackedByteArray()
	var i=0;var arrLen=len(out)/2
	while i<arrLen:
		finOut.append(out.substr(i*2,2).hex_to_int())
		i+=1
	return finOut

#gets the entire chunk's data
func getFullChunk(chunk):
	if !chunkFiles.has(chunk):return null
	var chunkData=getChunkFromFile(chunk)
	if chunkData==null:return null
	var base=decompressChunkData(chunkData,chunk)
	
	return base

#loads the chunk data only if it is available
func loadFullChunk(chunk):
	var out=getFullChunk(chunk)
	if out==null:return
	world.nftsaStore.chunkData[chunk]=out[0]
	world.nftsaStore.entityData[chunk]=out[1]
	
#opens chunk temporarily



const numCompression={
}


#compression of a chunk for storing

#gets what spot in the storage buffer this chunk is
func getSpotInBuffer(chunk):
	var n=getChunkCluster(chunk)*4
	
	return chunk.x-n.x+(chunk.y-n.y)*4

#if you have problems with blocks and items being wrong later
#its the (e-256)/256 part
#change it to 255 on one or both and it should be fixed
func compressChunkData(chunkData,chunk):
	
	var dat=chunkData[0].map(func(e):return e%256)
	dat.append_array(
			chunkData[0].map(func(e):return int((e-255)/256)))
	#stores size of chunk entity list
	var leng=len(chunkData[1])
	dat.append_array([leng%256,int((leng-255)/256.)])
	#stores the list itself now
	dat.append_array(chunkData[1])
	var compressed=PackedByteArray(dat).compress(2)
	compressed.append_array([
		len(dat)%256,int(len(dat)/256)
	])
	
	return compressed
		


#decompression of a chunk for use
func decompressChunkData(chunkData,chunk,giveFull=false):
	var bufferSpot=getSpotInBuffer(chunk)
	var length=chunkData[len(chunkData)-2]+chunkData[len(chunkData)-1]*256
	chunkData.resize(len(chunkData)-2)
	#decompresses chunk data
	var steps=Array(chunkData.decompress(
			length,2
		))
	var ents=[]
	#cuts into only the entity buffer
	if(length>514):ents=steps.slice(514,len(steps))
	var decompressed=[
		steps.slice(0,512),
		ents,
		steps[len(steps)-1]
	]
	var i=0
	while i<256:
		decompressed[0][i]+=decompressed[0][i+256]*256+1
		decompressed[0][i]=decompressed[0][i]*int(
			decompressed[0][i+256]<253
		)-1
		i+=1
	decompressed[0].resize(256)
	return decompressed



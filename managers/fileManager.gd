extends Node

var chunkFiles={}
var unusedChunkFiles=[]
var dir=Directory.new()
var allSaves=[]

func _ready():
	allSaves=getSaveList()
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



#main game from here
func openChunkFile(chunk):
	if(chunkFiles.has(chunk))||chunk.y>40:return
	var path="user://Saves/%s/chunks/%s.dat"%[world.saveName,str(chunk)]
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
	if !chunkFiles.has(chunk)||chunk.y>40:return
	chunkFiles[chunk].seek(0)
#	chunkFiles[chunk].store_pascal_string(compressChunkData(data))
	chunkFiles[chunk].store_line(compressChunkData(data))
	



#gets the entire chunk's data
func getFullChunk(chunk):
	if !chunkFiles.has(chunk):return null
	
	var base=decompressChunkData(chunkFiles[chunk].get_as_text())
	return base

#loads the chunk data only if it is available
func loadFullChunk(chunk):
	var out=getFullChunk(chunk)
	if out==null:return
	world.dataStore.chunkData[chunk]=out[0]
	world.dataStore.entityData[chunk]=out[1]
	
#opens chunk temporarily



const numCompression={
}


#compression of a chunk for storing

#if you have problems with blocks and items being wrong later
#its the (e-256)/256 part
#change it to 255 on one or both and it should be fixed
func compressChunkData(chunkData):
	var compressed=[]
	compressed.append([
		PackedByteArray(chunkData[0][0].map(func(e):return e%256)).compress(2),
		PackedByteArray(chunkData[0][0].map(func(e):return int((e-256)/256))).compress(2)
		]
		)
	compressed.append(chunkData[1])
	#stores the decompression lengths
	compressed.append(len(chunkData[1]))
	return compressed


#decompression of a chunk for use
func decompressChunkData(chunkData):
	
	var decompressed=str_to_var(chunkData)
	if decompressed[0][0]!=[]:
		decompressed[0][0]=Array(PackedByteArray(decompressed[0][0]).decompress(
			256,2
		))
		decompressed[0][1]=Array(PackedByteArray(decompressed[0][1]).decompress(256,2))
		
		for i in 256:
			decompressed[0][0][i]+=decompressed[0][1][i]*256+1
			decompressed[0][0][i]=decompressed[0][0][i]*int(decompressed[0][1][i]<254)-1
	return decompressed



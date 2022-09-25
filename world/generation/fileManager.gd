extends Node

var chunkFiles={}
var unusedChunkFiles=[]
var dir=Directory.new()
func _ready():
	for chunk in (world.renderDistance*2+1) **2:
		unusedChunkFiles.append(File.new())
	if !dir.dir_exists("user://Saves/%s/chunks"%world.saveName):
		dir.make_dir_recursive("user://Saves/%s/chunks"%world.saveName)
		
	


func openChunkFile(chunk):
	if(chunkFiles.has(chunk))||chunk.y>40:return
	var path="user://Saves/%s/chunks/%s.dat"%[world.saveName,str(chunk)]
	var file=unusedChunkFiles.pop_back()
	
	if !dir.file_exists(path):
		file.open(path,File.WRITE_READ)
	else:
		file.open(path,File.READ_WRITE)
	chunkFiles[chunk]=file
	
	


func closeChunkFile(chunk):
	if !chunkFiles.has(chunk):return
	chunkFiles[chunk].close()
	unusedChunkFiles.append(chunkFiles[chunk])
	chunkFiles.erase(chunk)




#stores entire chunk worth of data
func storeFullChunk(chunk,data):
	if !chunkFiles.has(chunk)||chunk.y>40:return
#	chunkFiles[chunk].seek(0);
	chunkFiles[chunk].store_line(compressChunkData(data))



#gets the entire chunk's data
func getFullChunk(chunk):
	if !chunkFiles.has(chunk):return null
	return str_to_var(decompressChunkData(chunkFiles[chunk].get_as_text()))

#loads the chunk data only if it is available
func loadFullChunk(chunk):
	var out=getFullChunk(chunk)
	if out==null:return
	world.dataStore.chunkData[chunk]=out

const numCompression={
}


#compression of a chunk for storing
func compressChunkData(chunkData):
	var compressed=str(chunkData).replace(
		" ","").replace(
		"-2,","~").replace(
		"-1","|")
	return compressed


#decompression of a chunk for use
func decompressChunkData(chunkData):
	var decompressed=chunkData.replace(
		"~","-2,").replace(
		"|","-1"
		)
	return decompressed

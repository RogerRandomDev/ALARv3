extends Node

var chunkFiles={}
var unusedChunkFiles=[]
var dir=Directory.new()
func _ready():
	#one extra for a margin chunk
	#used when temporary loading outside chunks
	#to modify mainly, I.E. explosions at the edge of the chunk
#	for chunk in (world.renderDistance*2+1) **2 +5:
#		unusedChunkFiles.append(File.new())
	if !dir.dir_exists("user://Saves/%s/chunks"%world.saveName):
		dir.make_dir_recursive("user://Saves/%s/chunks"%world.saveName)
		
	


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
	chunkFiles[chunk].store_line(compressChunkData(data))



#gets the entire chunk's data
func getFullChunk(chunk):
	
	if !chunkFiles.has(chunk):return null
	var base=decompressChunkData(chunkFiles[chunk].get_as_text())
	var out=str_to_var(base)
	return out

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
func compressChunkData(chunkData):
	var compressed=var_to_str(chunkData)
#	.replace(
#		" ","").replace(
#		"-2,","~").replace(
#		"-1,","|")
	return compressed


#decompression of a chunk for use
func decompressChunkData(chunkData):
	var decompressed=chunkData
#	.replace(
#		"~","-2,").replace(
#		"|","-1,"
#		)
	return decompressed

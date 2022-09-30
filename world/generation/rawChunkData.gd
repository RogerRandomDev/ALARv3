extends Node

var chunkData={}
var entityData={}
var playerData={}


#empty chunk data
const emptyChunk=[
	-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,
	-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,
	-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,
	-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,
	-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,
	-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,
	-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,
	-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2
]
var dir=Directory.new()

func _ready():
	pass
##
#CHUNK DATA
##
func addChunk(chunk,chunkDataIn=[]):
	
	chunkData[chunk]=chunkDataIn.duplicate(true)
	entityData[chunk]=[]
	if chunkDataIn==[]:chunkDataIn=[emptyChunk.duplicate(true),emptyChunk.duplicate(true)]
	

#this prevents storing in the ram itself
#if you want to load chunks after this, you need to store
#as a file and then get this fill from getChunk
func removeChunk(chunk,doSave):
	if doSave:
		world.fileManager.storeFullChunk(chunk,[
			chunkData[chunk].duplicate(),
			entityData[chunk]])
	entityData.erase(chunk)
	chunkData.erase(chunk)
func getChunk(chunk):
	return chunkData[chunk]
#compiles chunk data into one giant array
#mainly used for formatting for the compute shaders
func compileChunks():
	var data=[]
	var modBy=world.mapGen.centerChunk-Vector2i(world.renderDistance,world.renderDistance)
	for cY in world.renderDistance*2+1:
		for y in 16:
			var temp=y*16
			for cX in world.renderDistance*2+1:
				var arr=chunkData[Vector2i(cX,cY)+modBy][0]
				data.append_array(arr.slice(temp,temp+16))
	
	return data


##
#ENTITY DATA
##


##
#PLAYER DATA
##

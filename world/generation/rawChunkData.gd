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
	addChunk(Vector2i(0,0))
	addChunk(Vector2i(1,0))
	chunkData[Vector2i(0,0)][0][0]=1
	chunkData[Vector2i(1,0)][0][0]=1
	compileChunks()
##
#CHUNK DATA
##
func addChunk(chunk,chunkDataIn=[]):
	if chunkData.has(chunk):return
	if chunkDataIn==[]:chunkDataIn=[emptyChunk.duplicate(true),emptyChunk.duplicate(true)]
	chunkData[chunk]=chunkDataIn

#this prevents storing in the ram itself
#if you want to load chunks after this, you need to store
#as a file and then get this fill from getChunk
func removeChunk(chunk):
	chunkData.erase(chunk)
func getChunk(chunk):
	return chunkData[chunk]
#compiles chunk data into one giant array
#mainly used for formatting for the compute shaders
func compileChunks():
	var raw=[]
	var data=[]
	var sorted=chunkData.keys()
	#sorts into top-left to bottom-right order
	sorted.sort_custom(func(a,b):return a.x<b.x||a.y<b.y)
	for y in 16:for chunk in sorted:
		data.append_array(chunkData[chunk][0].slice(y*16,y*16+16))
	return data


##
#ENTITY DATA
##


##
#PLAYER DATA
##

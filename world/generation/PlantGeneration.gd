extends Node

const plantNoise0=preload("res://world/noise/plantNoise0.tres")
const plantNoise1=preload("res://world/noise/plantNoise1.tres")
var chunkList=[]
func genPlants(newChunks):
	var plantAt=[]
	chunkList=newChunks
	#compiles where it can plant in each chunk
	for chunk in newChunks:
		var addPos=newChunks[chunk]._pos*16
		var a = newChunks[chunk].get_used_cells(0).filter(func(x):
			return (newChunks[chunk].get_cell_source_id(0,x,false)==0&&
			plantNoise0.get_noise_1d(x.x+addPos.x)>0.75
			))
		plantAt.append_array(a.map(func(x):return x+addPos))
	#places plants at open positions
	for plant in plantAt:
		growPlant(plant)


const plantCells=[3,4]
func growPlant(globalPlantCell):
	for y in range(1,6):
		var chunk=world.cellToChunk(globalPlantCell-Vector2i(0,y))
		var cell=Vector3i(globalPlantCell.x-chunk.x*16,globalPlantCell.y-chunk.y*16-y,int(y<4)*(plantCells[0]-plantCells[1])+plantCells[1])
		
		var succeeded=placeBlock(chunk,cell)
		if !succeeded:break


func placeBlock(chunk,cell):
	if !chunkList.has(chunk):return false
	else:
		return chunkList[chunk].attemptFillCell(cell)

@tool
extends Resource
class_name biomeResource
@export var biomeName:String="Default"

@export var baseTiles:PackedInt32Array


@export var Temperature:float=0.5
@export var Humidity:float=0.5
@export var Depth:float=0.5

@export var groundOffset:int=0
@export var groundVariance:float=0.

@export var growPlants:bool=true
@export var plantCull:float=0.75
@export var plantSizeMin:int=4
@export var plantSizeMax:int=8
@export var plantTiles:PackedInt32Array=PackedInt32Array([0,0])
@export var oreCutoff:float=0.5
@export var fluidType:int=7


func addFluidOffset(fromID):
	if len(plantTiles):
		if plantTiles[0]>fromID:plantTiles[0]+=4
		if plantTiles[1]>fromID:plantTiles[1]+=4
	if baseTiles[0]>fromID:baseTiles[0]+=4
	if baseTiles[1]>fromID:baseTiles[1]+=4
	if baseTiles[2]>fromID:baseTiles[2]+=4
	if baseTiles[3]>fromID:baseTiles[3]+=4
	if fluidType>fromID:fluidType+=4

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

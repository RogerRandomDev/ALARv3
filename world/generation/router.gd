extends Node

const mapTiles=preload("res://world/resources/mapTiles.tres")

var mapGen=load("res://world/generation/mapGeneration.gd").new()
var chunkFiller=load("res://world/generation/chunkFiller.gd").new()
var worldShadows=load("res://world/generation/worldShadows.gd").new()
var dataStore=load("res://world/generation/rawChunkData.gd").new()
var shaderComp=load("res://world/generation/runShader.gd").new()

var root=null
var chunkHolder=null
var player=null
var biomeList=[]
var renderDistance=3
var chunkSize=16
var tileSize=8
var groundLevel=32
var height = 1024
const oneUp=Vector2i(0,1)

#block id to what the plant is made of
const plantsByFloor={
	0:[5,6],
	3:[5,5]
}



func _ready():
	fillBiomeList()
	mapGen._ready()
	worldShadows.call_deferred('_ready')
	shaderComp._ready()
	


#loads all the biomes into an array
func fillBiomeList():
	var dir=Directory.new()
	dir.open("res://world/Biomes")
	for biome in dir.get_files():biomeList.append(load("res://world/Biomes/%s"%biome))


#converts cell position to the chunk position
func cellToChunk(cellPos):
	return Vector2i(cellPos/16.)

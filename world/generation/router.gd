extends Node

const mapTiles=preload("res://world/resources/mapTiles.tres")

var mapGen=load("res://world/generation/mapGeneration.gd").new()
var chunkFiller=load("res://world/generation/chunkFiller.gd").new()
var root=null
var chunkHolder=null

var renderDistance=2
var chunkSize=16
var tileSize=8
var groundLevel=32

func _ready():
	mapGen._ready()
	mapGen.moveCurrentChunk(Vector2i(0,0))

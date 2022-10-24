extends Node


var modLoader=load("res://managers/modMiddleWare/modLoader.gd").new()
var tileSetBuilder=load("res://managers/modMiddleWare/tileSetBuilder.gd").new()





func loadMods():
	modLoader.loadMods()
	buildTiles()
	world.craftingManager.buildCSV()


func buildTiles():
	tileSetBuilder.buildTileSet(world.itemManager.itemData.values().filter(
		func(item):
			return item.name!="NONE"&&item.actionType=="place"
			))

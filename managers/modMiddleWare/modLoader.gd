extends Node



const modItems=preload("res://managers/modMiddleWare/modItems.gd")

func loadMods():
	var modList=getMods()
	for mod in modList:modItems.loadModItems(mod)



func getMods():
	var dir=Directory.new()
	dir.open("user://Mods")
	var file=File.new()
	return dir.get_directories()
